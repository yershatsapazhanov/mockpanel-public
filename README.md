# MockPanel

An English exam-practice web platform: adaptive vocabulary training, Reading, Listening, AI-assisted Writing feedback and a conversational Speaking examiner. The interface is available in Russian, Kazakh and English; the exam screens are in English.

> **Status:** working prototype, piloted with a small group of students. This repository contains the application structure, data model and selected modules. It is not a full copy of the production system (see [What is not in this repository](#what-is-not-in-this-repository)).

> **Independence notice:** MockPanel is an independent project. It is not affiliated with, endorsed by, or sponsored by IELTS, British Council, IDP, or Cambridge University Press & Assessment. Exam names are used only to describe the kind of practice offered.

## What it does

| Module | Summary |
|---|---|
| Vocabulary | Adaptive daily practice. Seven question types per word. Item selection is driven by a per-word memory estimate, and vocabulary size is reported as a range, not a single number. |
| Reading | Exam-style tasks (matching, multiple choice, gap fill, sentence insertion) with per-question review. |
| Listening | Timed papers with exam-style playback rules and a per-part result. |
| Writing | The student submits an essay and receives structured AI feedback on the four assessment areas, with quoted evidence from the student's own text. |
| Speaking | A voice or video examiner asks questions, reacts to answers and produces a report at the end. |
| Progress | Level, vocabulary-size range, accuracy by question type, words due for review. |

## Architecture in one page

- **Frontend:** static site, plain JavaScript, no build step. Hosted on Cloudflare Pages.
- **Backend:** Supabase (Postgres with Row Level Security, Auth, Edge Functions).
- **AI:** all model calls are made server-side from Edge Functions. No API key ever reaches the browser.
- **Offline tolerance:** answers are queued in the browser and sent later if the connection drops.

Details: [docs/architecture.md](docs/architecture.md) and [docs/data-model.md](docs/data-model.md).

## Design decisions worth reading

1. **Store events, derive state.** Every answer is an append-only row. Level, streaks and weak areas are computed from events, so formulas can change later and be re-run on history.
2. **Scores are never written by the client.** The browser cannot change its own result.
3. **Everything a score depends on is versioned** (rubric, prompt, model, item), so an old score stays interpretable.
4. **Personal and non-personal data live in separate tables**, so hosting rules for personal data can be applied to one group only.
5. **Deterministic checking where possible.** Reading and Listening answers are checked by code, not by a model. AI is used only where judgement is needed.

## Running locally

The front-end source is not in this repository yet; this first release covers
the architecture, the data model and the tooling. Once `src/` is published, the
steps are:

```bash
cp src/js/config.example.js src/js/config.js   # then fill in your own Supabase URL and anon key
# serve the src/ folder with any static server, for example:
npx serve src
```

You need your own Supabase project. Content (word cards, exam tasks, audio) is not included; see below.

## What is not in this repository

- Exam content banks, audio, and question sets
- AI prompts and scoring rubrics
- Payment and token-economy configuration
- Any user data, keys, or invite codes

This is deliberate: part of the content is under third-party or institutional rights, and part is the commercial core of the product.

## Licence

Code in this repository is released under the MIT Licence (see [LICENSE](LICENSE)). The licence covers code only, not any exam content or third-party materials.

## Author

Yershat Sapazhanov
