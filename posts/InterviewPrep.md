+++
title = 'Interview Prep with Vector Embeddings and Cosine Similarity'
date = 2025-11-10T07:07:07+01:00
draft = false
+++

*For all code discussed here, visit the Github repository*
https://github.com/Sput/interview_assistance

The purpose of this app is to demonstrate the use of vectors and cosine similarity to compare pieces of text. When a new interview question is created, an edge function will create a model answer with the assistance of gpt-4o-mini. After that answer is created, a separate edge function will take that model answer, and turn it into a vector using the gpt-4-embedding model. When a user answers a question, their answer will be turned into a vector by a separate edge function. Another edge function will then perform cosine similarity on the model answer and the users answer to see how similar they are. This is presented as the user's score. 

# TL;DR
This project is a voice-driven interview-practice app that mimics real conversations, letting users hear questions, speak answers, and get instant AI-based feedback. It combines Next.js, Supabase, and browser speech APIs to capture voice input, embed responses into vectors, and score them by cosine similarity against a model answer. The result is a realistic, feedback-rich system that helps users improve through immediate grading, retries, and conversational learning loops.


# **Practice Interviews, Powered by Voice**

Most interview-prep tools either feel like digital flashcards or force you into typing.

This app takes a different path — it aims to **simulate a real interview**. You hear a question, you speak your answer, you get instant feedback and a score — then you try again.

It’s a **voice-first practice environment**, built with **Next.js**, **Supabase**, the **Web Speech API**, and a lightweight **feedback loop** that helps you iterate until you sound confident.

---

## **What You Can Do**

- **Voice answers:** Respond naturally using your microphone.
    
- **Live transcript:** Watch your words appear and persist in real time as you speak.
    
- **Smart question selection:** Get random interview questions without immediate repeats.
    
- **Automatic scoring:** Receive a 0-100 score based on how semantically close your answer is to an ideal response.
    
- **Feedback loop:** If your score falls below the bar, the system explains what’s missing — then re-asks the question.
    
- **At-a-glance score:** A color-coded card shows your latest score (green for pass, red for retry).
    

---

## **How It Works**

### Create Question

  

Create questions you want to be prepared for during an interview

1. Model answer will be created for you automatically using Supabase edge functions which calls gpt-4o-mini. ![Model Answer Creation](/images/Screenshot%202025-11-13%20at%207.39.10%20AM.png)

2. After the model answer is created another edge function will create a vector representation of that answer ![Vector Creation](/images/Screenshot%202025-11-13%20at%207.41.49%20AM.png)


### **Voice Capture**

  

The system uses the browser’s native speech recognition APIs (SpeechRecognition / webkitSpeechRecognition) that:

- Requests microphone access upfront and handles “permission denied” gracefully.
    
- Keeps listening during natural pauses — no cutoff mid-sentence.
    
- Lets you tap **“End response”** when you’re done.
    

### **Conversation Loop**

1. **Ask:** Click “Ask Interview Question” to fetch a category-specific question
    
2. **Answer:** Speak your response (or type if you prefer)
    
3. **Score & feedback:** Your answer is saved, and converted to a vector representation (same as the model answer above)
    ![Answer Vectorization](/images/Screenshot%202025-11-13%20at%207.44.05%20AM.png)

  4. **Similarity score:** The user answer is then compared to the model answer using cosine similarity. ![Similarity Score](/images/Screenshot%202025-11-13%20at%207.49.36%20AM%201.png)
  ![Cosine Similarity](/images/Screenshot%202025-11-12%20at%2012.02.40%20PM.png)

### **Scoring Pipeline**

  

Under the hood, the grading process runs through three stages:

1. **Vectorization:** Both the interview question and its ideal “model” answer are embedded into 1536-dimensional vectors using text-embedding-3-small embedding model
    
2. **Cosine similarity:** A small backend job computes the similarity between your answer’s vector and that of the reference vector
    
3. **Score update:** The app displays your score instantly on the **Current Score** card.
    

  

### **Random Selection, No Repeats**

  

To keep practice varied, the app filters out your most recent questions before selecting the next one. If the filtered pool is empty, it falls back to a broader question set.

---

## **User Experience Details**

- **Microphone access:**
    
    - Always initiated by a button tap.
        
    - If blocked, a clear message explains how to enable mic access or switch to text input.
        
    
- **Persistent listening:**
    
    - Interim speech appears instantly.
        
    - The UI avoids flickering between “Listening” and “Processing” states.
        
    
- **End response control:**
    
    - You decide when recognition stops.
        
    - The captured transcript becomes your final answer upon submission.
        
    
- **Score card:**
    
    - Always visible below the conversation area.
        
    - Starts at 0 and updates after each graded attempt.
        
    - Green for scores ≥ 60, red for < 60, with large, easy-to-read typography.
        
    

---

## **Architecture Overview**

  

### **Frontend**

  

Built with **ShadCN,** **Next.js** and **React**, the frontend orchestrates the entire voice and feedback flow:

- **Conversation view:** Displays questions, transcripts, controls, and scores.
    
- **Voice state management:** Tracks whether the system is listening, speaking, or idle.
    
- **Speech recognition hook:** Bridges browser APIs with React state.
    
- **Microphone helper:** Handles permission requests

### **Backend**

  

Powered by **Supabase**, the backend handles persistence and embeddings:

- **Database tables:** Store questions, answers, and grades.
    
- **Edge functions:**
    
    - make_vectors - computes embeddings for model answers when a new question is created
        
    - answer_vectors - computes embeddings for new user answers.
        
    
- **Grading job:** Python process computes cosine similarity between stored vectors and writes the resulting score to the table that maintains the user's answers.
    


---
## **What’s Next**

- **Progress tracking:** Visualize score trends and improvement over time.
    
- **Difficulty scaling:** Adjust question difficulty dynamically.
    
- **Rubric-based grading:** Combine semantic similarity with structured rubrics for content and clarity.
    
- **Adaptive hints:** Offer nudges when users hesitate too long.

- **UI improvements:** improve the look and feel of the user experience

---

## **Under the Hood: Embeddings & Scoring**

### **Embeddings 101**

Embeddings are numerical vectors representing the **semantic meaning** of text.

Two similar sentences will have vectors that point in roughly the same direction in high-dimensional space.

### **Vector Creation**

- Use the **same embedding model** for all text types (question, model answer, user answer).
    
- Clean input lightly — normalize whitespace, but no need to strip punctuation.
    
- For long text, split into chunks and average their vectors.
    
- Store vectors persistently so they can be reused efficiently.
    

### **Cosine Similarity**

  

The similarity score comes from the **angle** between vectors:

![Cosine Similarity](/images/Screenshot%202025-11-12%20at%2012.02.40%20PM.png)
  

If both vectors are normalized (which they should be in this case, since we used the same embedding algorithm for each), the dot product directly equals the cosine similarity.

  

### **Mapping to a 0-100 Score**

- **Simple mapping:** score = round(max(0, cos_sim) × 100)
    
- A score ≥ 60 is considered passing.
    


---


### **Final Thoughts**

  

This project shows how a small, focused stack — **Next.js**, **Supabase**, **SpeechRecognition**, and **embeddings** — can deliver a surprisingly human learning experience.

By combining real-time voice capture, semantic grading, and immediate feedback, it turns rote interview prep into **iterative, conversational practice**.