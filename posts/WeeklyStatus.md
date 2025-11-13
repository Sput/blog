+++
title = 'From Weekly Updates to Instant Insight: A RAG-Powered Status App'
date = 2025-11-10T07:07:07+01:00
draft = false
+++


*For all code discussed here, visit the Github repository*
https://github.com/Sput/weekly_status_RAG

  

Weekly updates are the heartbeat of most engineering teams—but too often, they’re trapped in scattered documents, chat threads, or inboxes. Context disappears, insights lag, and managers spend hours piecing together what actually happened across the organization.

  

This app solves that by turning weekly updates into a **retrieval-augmented knowledge surface**.

It combines a simple posting UI with an AI-powered chat that can answer questions like _“What did the mobile team ship last week?”_—grounded directly in the latest updates from your team.

  

The result: a **lightweight, explainable status hub** that transforms free-form updates into actionable, traceable insight.

---



## **Under the Hood: RAG & Embeddings**

### What is RAG?

**Retrieval-Augmented Generation (RAG)** is an AI based technology that combines information retrieval with language generation to produce grounded, trustworthy answers. Instead of relying solely on data that has been learned by a language model, RAG first searches a structured knowledge source (in this case a repository of your team's weekly status updates which have been converted into a vector database—for the most relevant context to a query. Those retrieved snippets are then passed into the model’s prompt, ensuring that its response is based on real, recent data. This approach improves accuracy, transparency, and adaptability: users can see exactly which sources were used, developers can update or re-rank context without retraining the model, and organizations can keep responses aligned with their latest information.

### **Embeddings 101**

Embeddings are numerical vectors representing the **semantic meaning** of text.

Two similar sentences will have vectors that point in roughly the same direction in high-dimensional space.

### **Vector Creation**

- Use the **same embedding model** for all text types (question, teammate status update).
    
- Clean input lightly — normalize whitespace, but no need to strip punctuation.
    
- For long text, split into chunks and average their vectors.
    
- Store vectors persistently so they can be reused efficiently.
    

### **Cosine Similarity**

  

The similarity score comes from the **angle** between vectors:

![Cosine Similarity](/images/Screenshot%202025-11-12%20at%2012.02.40%20PM.png)
  

If both vectors are normalized (which they should be in this case, since we used the same embedding algorithm for each), the dot product directly equals the cosine similarity.


## **What the App Does**

At a glance, the app is part **status feed**, part **AI query engine**, built for clarity and speed.

**You can:**

- **Post updates** - Write your weekly status in a single field; it’s fast and frictionless.
    
- **Browse the feed** - See everyone’s updates in a clean, searchable timeline.
    
- **Ask questions** - Query the team’s progress through a chat UI powered by Retrieval-Augmented Generation (RAG).
    
- **See the sources** - Every AI answer includes the snippets it used—timestamps, similarity scores, and all so you can trust what you see.
    

**Why it matters:**

- Eliminates the “status chase”-no more digging through Slack or Notion.
    
- Turns updates into structured, queryable data.
    
- Provides leadership with high-signal, verifiable summaries.
    
- Keeps teammates aligned asynchronously without meetings.
    

---

## **How RAG Works in this application**

  

The system uses **RAG (Retrieval Augmented Generation)** to connect questions with the most relevant, recent updates. 

### 1. Core Functionality
1. Turn a user's status update into a vector. This will allow the cosine similarity calculation (coming next) to determine how similar the user's status is to the teammate's question.
![Status Update Vectorization](/images/Screenshot%202025-11-13%20at%207.06.31%20AM%201.png)
2. Calculate similarity between a user's status update and a teammate's question. We do this in Supabase using a pgvector built-in function for computing similarity: <=>.
![Similarity Calculation](/images/Screenshot%202025-11-13%20at%207.10.16%20AM.png)
3. **Augment** LLM query with the user status updates we **retrieved** which are most **similar** to the question asked by a teammate.
![RAG Augmentation](/images/Screenshot%202025-11-13%20at%207.13.55%20AM.png)
---


### **2. Data Flow Overview**

1. A team member posts their weekly update via the web UI.
    
2. The text is stored in Supabase and embedded into a 1,536-dimension vector (using OpenAI’s text-embedding-3-small).
    
3. When someone asks a question in chat, FastAPI:
    
    - Creates a query embedding.
        
    - Uses **pgvector similarity search** to find the most semantically relevant “latest-per-user” updates.
        
    - Returns both the context snippets and an LLM-generated summary (via GPT-4o-mini).
        
    
4. The frontend displays both the **answer** and the **exact sources** used.
    

  

This gives the team confidence that every summary is backed by real, recent work—**not hallucinations.**


## **Architecture Overview**

  

### **Frontend (Next.js 15 + React 19)**

  

The frontend provides a clean, minimal interface built with **shadcn/ui** components.

- **Updates Page** - src/app/updates/page.tsx
    
    - Post updates with one click.
        
    - View a live feed with filters by user or date.
        
    - Supabase triggers can auto-generate embeddings upon submission.
        
    
- **Chat Page** - src/app/chat/page.tsx
    
    - Ask questions like “What did the infra team do this week?”
        
    - Displays retrieved snippets (“Context”) before showing the model’s answer.
        
    - Transparency by design: you see where every claim came from.
        
    
- **API Proxy** - src/app/api/chat/route.ts
    
    - Proxies chat requests to the FastAPI backend (NEXT_PUBLIC_BACKEND_URL) for same-origin simplicity.
        
    

  

### **Backend (FastAPI Service)**

  

The Python backend owns the AI orchestration logic and retrieval pipeline.

  

**api/main.py handles:**

1. Embedding creation via OpenAI.
    
2. Querying Supabase RPC match_latest_updates for semantically similar updates.
    
3. Fallbacks to recency if embeddings aren’t available.
    
4. Prompting GPT-4o-mini with those snippets for concise, grounded answers.
    
5. Returning both **context** and **debug info** (mode, source, reason).
    

  

This clear separation of concerns lets the React frontend focus on UX while the Python layer handles LLM orchestration and secret management.

---

## **Supabase Data Layer**

- **Tables**
    
    - users: app users with roles and metadata.
        
    - updates: text field, embedding (vector), created_at timestamp.
        
    - roles: defines manager/member view roles.
        
    
- **Views & Functions**
    
    - latest_updates_per_user: returns each user’s most recent update.
        
    - match_latest_updates(query_embedding, match_count): finds semantically closest updates using cosine similarity.
        
    - Optional trigger create_embedding: can call OpenAI directly from Postgres to compute embeddings on insert.
        
    

  

**Index:** ivfflat over embeddings with cosine distance for efficient approximate nearest-neighbor search.

---

## **Why FastAPI Instead of Just Next.js or Supabase**

  

**1. Separation of Concerns**

  

Next.js handles the UI.

FastAPI handles LLM calls, retrieval, and orchestration.

This avoids mixing secret-heavy code (OpenAI keys, Supabase service roles) into the browser or JavaScript runtime.

  

**2. Secret Isolation**

  

Sensitive keys never touch the frontend—FastAPI alone uses:

- OPENAI_API_KEY
    
- SUPABASE_SERVICE_ROLE_KEY
    

  

**3. Operational Flexibility**

  

LLM workloads can be scaled, rate-limited, or monitored independently of web traffic. FastAPI is ideal for Python’s async, vector, and analytics ecosystem.

  

**4. Clear API Contract**

  

A single endpoint:

```
POST /chat { query, top_k } → { context[], answer, debug }
```

Pydantic models ensure type safety between services.

---

## **Retrieval and Generation Cycle**

1. **Embed Query:**
    
    The user’s question is embedded using text-embedding-3-small.
    
2. **Retrieve Context:**
    
    Supabase RPC returns the top_k most similar _latest-per-user_ updates.
    
3. **Construct Prompt:**
    
    - Context formatted as:
        
    

```
(2025-01-07) sim=0.83: “Shipped new onboarding flow…”
(2025-01-06) sim=0.79: “Deployed API monitoring for billing…”
```

3. -   
        
    - System message instructs GPT-4o-mini to ground its response in these snippets.
        
    
4. **Generate Answer:**
    
    GPT-4o-mini produces a concise, source-linked summary.
    
5. **Return to UI:**
    
    The chat page displays both **context** and **answer**, plus debug metadata (similarity mode, fallback reason, and context count).
    

---

## **Local Development**

  

**Frontend:**

```
pnpm install && pnpm run dev
```

- .env.local → configure NEXT_PUBLIC_SUPABASE_URL, NEXT_PUBLIC_SUPABASE_ANON_KEY, and NEXT_PUBLIC_BACKEND_URL.
    

  

**Backend:**

```
uvicorn main:app --reload --port 8787
```

- .env → include SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, and OPENAI_API_KEY.
    

  

**Supabase:**

- Apply SQL schema (supabase/sql/*.sql) and enable pgvector.
    
- Optional: enable create_embedding() trigger for automatic embeddings.
    

  

The frontend proxies /api/chat to FastAPI, so the browser never deals with cross-origin calls or exposed secrets.

---

## **Observability & Trust**

  

Transparency is a major advantage of RAG. Much of what happens in LLMs is opaque to human users, but with RAG human's can see exactly what data is being used to deliver their answer, making referencing and verification easy.

The app surfaces what the model saw and why it answered as it did.

- **Visible Context:** Each chat reply lists the snippets that grounded it.
    
- **Debug Info:** Returned metadata includes retrieval mode (similarity or recency), source (rpc or rest), and fallback reason.
    
- **Logging:** FastAPI logs embedding latency, RPC timings, and token usage for performance tuning.
    
- **Graceful Fallbacks:**
    
    - Missing OpenAI key → recency mode.
        
    - RPC failure → default to latest updates.
        
    - Empty embeddings → skip the update
        
    
Even without embeddings, the app remains usable—no blank screens, just reduced semantic fidelity.

---

## **Design Decisions and Trade-Offs**

| **Design Choice**               | **Why It Matters**                                                                 |
| ------------------------------- | ---------------------------------------------------------------------------------- |
| **Separate FastAPI service**    | Keeps secrets safe, allows Python-based retrieval logic, and scales independently. |
| **Latest-per-user retrieval**   | Balances freshness with team coverage; one snippet per person avoids crowding.     |
| **Visible grounding context**   | Builds trust—users see where every summary came from.                              |
| **Fallback-first architecture** | Ensures reliability even when APIs fail or keys are missing.                       |
| **Vector search via pgvector**  | Open-source, efficient, and deeply integrated with Supabase SQL.                   |

---

## **Performance and Cost**

- **Scaling:**
    
    - Next.js scales for concurrent connections.
        
    - FastAPI scales on CPU/memory for embeddings and LLM calls.
        
    
- **Caching:**
    
    - Embedding and answer caching can be added on the backend without changing frontend cache strategies.
        
    
- **Model Agility:**
    
    - Swap chat or embedding models independently (e.g., from GPT-4o-mini to Claude or Gemini).
        
    

---

## **Developer Experience**

- **One clean contract:** POST /chat
    
- **Type-safe models:** Pydantic enforces IO integrity.
    
- **Easy local setup:** Run both services on localhost; proxy keeps things simple.
    
- **Full transparency:** Every answer is reproducible and debuggable.
    

  

This architecture lets front-end developers focus on UX, while backend and ML engineers iterate on embeddings, RAG tuning, and evaluation without touching UI code.

---

## **Roadmap**

- Multi-team and multi-manager scopes.
    
- Project-level metadata and structured updates.
    
- Reminder notifications for weekly posts.
    
- Persistent chat history with saved queries.
    
- Analytics and trend visualizations over time.
    
- Advanced retrieval (MMR, reranking, hybrid semantic filters).
    
