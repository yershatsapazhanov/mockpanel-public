# Architecture

## Components

```
Browser (static site, plain JS)
   |  Supabase client: auth, reads, queued writes
   |  fetch: Edge Functions (AI calls)
   v
Supabase
   - Auth (email + password)
   - Postgres with Row Level Security on every table that holds a user id
   - Edge Functions: registration, AI grading, speaking turns
   |
   v
AI provider API (called only from Edge Functions, key stored as a server secret)

Cloudflare Pages: static site and, in a separate project, large audio files
```

## Why this shape

- **No build step.** The site is plain HTML, CSS and JavaScript. It can be hosted on any static host and debugged in a browser without tooling.
- **Row Level Security instead of app-level checks.** A user's rows are visible only to that user because the database enforces it, not because the front end hides them.
- **AI only on the server.** An API key in client code is visible to anyone who opens developer tools. Every model call goes through an Edge Function that also checks login and per-user limits.
- **Audio hosted separately.** Audio files are large and rarely change. Keeping them in their own static project means a site update does not re-upload them.
- **Three interface languages** (Russian, Kazakh, English) from one string table. Exam screens stay in English.

## AI usage pattern

1. Deterministic checking first. Reading and Listening answers are checked by code.
2. A model is called only where judgement is needed (Writing feedback, Speaking turns, explanations).
3. Every model response that must be JSON is parsed defensively: one retry with a stricter instruction before an error is shown.
4. Each call has a timeout and one retry with backoff.
5. Login is required before any endpoint that costs money. A per-user and a global daily cap are enforced server-side.
6. Prompt, rubric and model versions are stored with every result.

## Reliability details

- Answers are queued in the browser and flushed in batches; if the connection drops, the queue is kept in local storage and sent later.
- Registration is a server function: it validates the invite, creates the user, writes profile and consent, and rolls back on failure.
- Account deletion is a single database function that removes every row carrying the user id.

## Testing approach

The interface is tested end to end with a browser automation tool against a mock of the backend, at three screen sizes, including offline queueing and account deletion. Database rules are tested in SQL under the `authenticated` role: other users' rows must be unreadable and unwritable.
