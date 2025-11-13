+++
title = 'Automating Compliance Evidence Review with an Agentic Architecture (and why I will probably not use this architecture again)'
date = 2025-11-10T07:07:07+01:00
draft = false
+++

*For all code discussed here, visit the Github repository*
https://github.com/Sput/compliance_app

  

Audits are notorious for being a mix of detective work and paperwork. Every compliance framework—SOC 2, PCI DSS, ISO 27001, HIPAA, GDPR—requires collecting “evidence” that proves a security control is implemented and operating correctly. The problem: finding, uploading, classifying, and reviewing hundreds of artifacts is slow, manual, and inconsistent.

  

This application streamlines that process from **artifact upload to human-approved classification**, using **Next.js**, **Supabase**, and a **Python-based agentic backend**. It’s small enough to deploy quickly but architected to grow from deterministic heuristics to multi-agent reasoning as your review needs scale. Scroll to the last paragraph if you want to skip to why I don't think I will use this type of agentic architecture again. 

---

## **What the App Does**

  

At its core, the system is a **compliance evidence pipeline**:

1. **Upload** an artifact (PDF, image, or text file).
    
2. **Extract** its text and parse basic metadata (system name, date).
    
3. **Classify** it against framework controls using deterministic and agentic models.
    
4. **Review** the recommendation in a simple UI and mark it Accepted or Rejected.
    

  

The result is a repeatable, transparent workflow that turns unstructured evidence into structured, reviewable data—complete with explainability and traceability.


---

## **The Agentic Architecture**

  

The application follows a **hierarchical supervisor-worker model**, common in agentic systems. A **supervisor agent** orchestrates three **specialized sub-agents**, each with a narrow, auditable purpose:

1. **Supervisor Agent:** Oversees all actions taken by subordinate agents
![Supervisor Agent](/images/Screenshot%202025-11-13%20at%208.25.57%20AM.png)


2. **Date Guard:**  Verifies that an artifact’s date falls within the audit window.
    
    - Output: { status: PASS|FAIL, parsed_date, reason }
        
    ![Date Guard](/images/Screenshot%202025-11-13%20at%208.15.54%20AM.png)
3. **Action Describer:**  Summarizes what the document demonstrates in ≤120 words.
    
    - Output: { actions_summary }
        
    ![Action Describer](/images/Screenshot%202025-11-13%20at%208.17.20%20AM%201.png)
4. **Control Assigner:**  Chooses the best-matching security control and provides rationale.
    
    - Output: { control_id, rationale }
        
    ![Control Assigner](/images/Screenshot%202025-11-13%20at%208.17.41%20AM.png)

  

The supervisor executes them sequentially:

**Date Guard → (if PASS) Control Assigner (+ optional Action Describer)**.

This hierarchy allows deterministic pre-checks (date validation) to gate costly LLM steps (semantic classification), yielding both reliability and scalability.

---

## **Architecture Overview**

### **Frontend — Next.js + Supabase**

The frontend, built in **Next.js (TypeScript/React)**, handles uploads, displays classification results, and provides an in-browser review dashboard.

- **File Uploader:** Drag-and-drop with upload progress and storage integration.
    
- **Results View:** Shows classification candidates, confidence levels, and parsed fields.
    
- **Score & Status Cards:** Indicate whether evidence is accepted, rejected, or awaiting review.
    

  

Authentication and artifact storage use **Supabase Auth** and **Supabase Storage**. Evidence records, audit metadata, and classifications live in **Supabase Postgres**.

  

### **Backend — Python Processing Service**

  

The Python backend (FastAPI or CLI-invoked in development) performs the heavy lifting:

1. **OCR Extraction:** Provider-agnostic implementation (stub or Tesseract/managed OCR).
    
2. **Parsing:** Extracts key data points like system and evidence_date.
    
3. **Classification:** Maps artifacts to candidate controls and returns confidence scores.
    
4. **Supervisor Orchestration:** Coordinates sub-agents when agentic mode is enabled.
    

  

All results are persisted via Supabase’s REST interface or direct Postgres connection.


---

## **Evidence Lifecycle**

  

The evidence review process blends automation with human oversight:

1. **Uploaded → Processing → Classified → Needs Review → Accepted/Rejected**
    
2. **Automated Gate (Date Guard):** Reject immediately if the evidence is out of range.
    
3. **Agent Recommendation:** Control Assigner produces a proposed control and rationale.
    
4. **Human Review:**
    
    - Reviewer sees parsed date, action summary, rationale, and raw text snippet.
        
    - Can Accept (finalize control mapping), Reject (with reason), or Request Changes.
        
    
5. **Optional Auto-Accept Policy:** If confidence is high and policy allows, the artifact can auto-accept and queue for spot-check.
    

  

This design keeps humans in the loop but lets agents handle the tedious pattern matching.

---

## **Data Model Highlights**

| **Table**           | **Purpose**               | **Key Fields**                                                    |
| ------------------- | ------------------------- | ----------------------------------------------------------------- |
| **audits**          | Audit metadata            | audit_start, audit_end                                            |
| **evidence**        | Each uploaded artifact    | file_ref, extracted_text, system, evidence_date, status           |
| **classifications** | Candidate control matches | framework_id, control_id, confidence                              |
| **reviews**         | Reviewer actions          | review_status, reviewed_by, reviewed_at, rationale, reject_reason |

All outputs—especially those from agents—are **JSON-contracted** for predictability and auditability.

---

## **Observability and Guardrails**

- **Deterministic where it matters:** Date and range checks are pure Python logic.
    
- **Explainable outputs:** Every agent emits structured JSON, not free-form text.
    
- **Debug tracing:** All intermediate inputs/outputs can be logged for audit trails.
    
- **Safety limits:** Token bounds, fallback parsers, and circuit breakers prevent runaway costs or timeouts.
    

  

This ensures that every agentic decision is reproducible and defensible during compliance reviews.

---

## **Roadmap**

- UI improvements to make navigation more intuitive for the user
    
- OCR to expand file types accepted
    
- additional detail of checks (more detail on why evidence is rejected)
    

---

## **Why I will think twice before using this architecture again**

  

The application follows a **hierarchical supervisor-worker model**, which has been hyped in the AI assisted development community, which is why I wanted to try it. The problem is the level of complexity, and how easily the logical flow fails. The guardrails necessary to keep the agents on track, made it so that it would have been easier to use a traditional function calling application. Two reasons I might be wrong: the agents come in to play more as the application scales up in functionality, and agent re-use plays a bigger part OR I just need to gain more experience with this architecture. 