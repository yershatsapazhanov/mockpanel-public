# Data model

## Principles

1. **Store events, derive state.** Answers and attempts are append-only rows. Anything shown to a student (level, streak, weak areas, vocabulary estimate) is computed from events and cached in small state tables. Storing only the current level would make it impossible to change a formula and re-run it on history.
2. **Every stored field must feed a concrete use:** selection of the next item, the student's own progress, item quality control, or cost control. A field with no such use is not collected.
3. **Version everything a score depends on** (rubric, prompt, model, item), so a score can be interpreted or recomputed later.
4. **Separate personal from non-personal data**, so hosting or retention rules can apply to one group only.
5. **Band scores come from the server.** Writing and Speaking feedback is written
   by an Edge Function under a service role and is read-only to the learner.
   Reading and Listening practice attempts are inserted by the client into its
   own append-only row; see point 2 of the README for why, and what replaces it.

## Tables (summary)

| Group | Purpose |
|---|---|
| `profiles`, `consents` | Account settings; versioned, append-only consent records |
| `answer_log` | One row per vocabulary answer: card and card version, question type, option shown and chosen, correct, response time, mode |
| `card_state` | Per user and word: memory estimate, last outcome, counts. Lets selection run without scanning the log |
| `level_history` | Level and vocabulary-size range over time |
| `attempts` | Exam attempts by skill, with criteria and versions |
| `item_stats` | Per item: attempts, facility, discrimination, per-option pick counts. Contains no user id |
| `usage_log` | Per call: endpoint, model, tokens, cost, latency, status. Used for per-user caps |

## Row Level Security

Every table that holds a user id allows a user to read only their own rows. Profile and consent rows are written only by the registration function. Content tables are readable by anyone but only for rows with status `published`; writing is done by the owner through the database dashboard.

## Retention

- Raw answer logs: 12 months, then aggregated.
- Essays and speaking transcripts: kept until the student deletes them.
- Audio of speaking is not stored; only the transcript is.
- Account deletion removes every row carrying the user id. `item_stats` survive because they contain no user id.

## Not collected

Phone number, home address, national ID numbers, card data, device fingerprints.
