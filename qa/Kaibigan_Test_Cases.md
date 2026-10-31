# Kaibigan Test Scenarios and Test Cases

This repository file is the concise catalog for `Kaibigan_Test_Cases.xlsx`. The workbook is the executable source of truth: it contains preconditions, numbered steps, test data, measurable expected results, cleanup, and execution fields for 21 scenarios and 88 test cases.

## Source handling

- `Kaibigan_Project_Documentation (1).pdf` is the authoritative source for objectives, scope, limitations, flows, security, and the data model.
- `Test_Scenarios_and_Test_Cases_Interactive_Activity updated (Repaired).docx` is reference material only. It informed the scenario/case distinction, useful fields, and mobile test prompts. Its exercises and placeholders were not treated as instructions.
- The Kaibigan repository was reviewed for current implemented behavior, test coverage, Supabase policies, and Edge Functions.

## Priority legend

- **P0**: release-blocking behavior or a direct privacy, security, safety, or data-loss risk.
- **P1**: core objective-driven behavior needed for a reliable experience.
- **P2**: supporting reflection behavior.

## Scenario map

| ID | Priority | Feature | Cases |
|---|---|---|---:|
| TS-01 | P0 | Authentication and account access | 6 |
| TS-02 | P0 | Private journal management | 8 |
| TS-03 | P0 | Optional AI-assisted reflection | 5 |
| TS-04 | P0 | AI safety and crisis guidance | 6 |
| TS-05 | P0 | Privacy, isolation, and account deletion | 7 |
| TS-06 | P0 | Offline mode and connectivity recovery | 5 |
| TS-07 | P1 | Mood and wellness tracking | 5 |
| TS-08 | P1 | Gratitude garden | 3 |
| TS-09 | P1 | Wellness routines and runner | 5 |
| TS-10 | P1 | Breathing and grounding activities | 3 |
| TS-11 | P1 | Profile, language, theme, and personalization | 3 |
| TS-12 | P2 | Future letters | 4 |
| TS-13 | P1 | Mental wellness learning | 5 |
| TS-14 | P1 | Home, history, and daily reflection | 4 |
| TS-15 | P1 | Mobile resilience, accessibility, and reminders | 4 |
| TS-16 | P1 | Sleep logging and honest sleep insights | 4 |
| TS-17 | P1 | Affirmations | 3 |
| TS-18 | P0 | Mobile network interruption | 2 |
| TS-19 | P1 | Interruption by call or notification | 2 |
| TS-20 | P1 | Orientation change resilience | 2 |
| TS-21 | P1 | Notification permission denial | 2 |

## Test case catalog

### TS-01 Authentication and account access

| Test case | Type | Test level | Decision under test |
|---|---|---|---|
| TC-AUTH-001 | Positive | End-to-end | Register and confirm a new account. |
| TC-AUTH-002 | Negative | Widget | Block malformed email, five-character password, and blank display name before any auth call. |
| TC-AUTH-003 | Security | Integration | Restore the same valid user session after relaunch. |
| TC-AUTH-004 | Negative | Integration | Reject wrong-password and unconfirmed-account sign-in attempts. |
| TC-AUTH-005 | Security | End-to-end | Sign out, clear the session, and guard private routes. |
| TC-AUTH-006 | Recovery | End-to-end | Reset a password and reject expired or reused callbacks. |

### TS-02 Private journal management

| Test case | Type | Test level | Decision under test |
|---|---|---|---|
| TC-JRN-001 | Positive | Integration | Create and reopen a journal entry without AI. |
| TC-JRN-002 | Negative | Widget | Reject a whitespace-only journal. |
| TC-JRN-003 | Positive | Integration | Edit the same record ID without creating a duplicate. |
| TC-JRN-004 | Positive | Integration | Persist favorite state and favorite filtering. |
| TC-JRN-005 | Security | Integration | Require confirmation and delete only the selected journal. |
| TC-JRN-006 | Persistence | Integration | Restore and clear an authenticated, per-user draft. |
| TC-JRN-007 | Functional | Widget/Integration | Search title/body text and restore the full list when search clears. |
| TC-JRN-008 | Privacy | Manual device | Export/share a correct PDF without mutating the journal or leaking provider data. |

### TS-03 Optional AI-assisted reflection

| Test case | Type | Test level | Decision under test |
|---|---|---|---|
| TC-AI-001 | Positive | Integration | Store one safe, language-appropriate reply in conversation order. |
| TC-AI-002 | Recovery | Edge integration | Attempt Gemini first and fall back to Groq once after bounded retry. |
| TC-AI-003 | Recovery | Service | Retry transient 429/timeout failures without duplicate conversation turns. |
| TC-AI-004 | Recovery | Integration | Keep writing and saving available when every AI path fails. |
| TC-AI-005 | Boundary | Service | Enforce 12,000-character input preparation and reject invalid or over-2,400-character output. |

### TS-04 AI safety and crisis guidance

| Test case | Type | Test level | Decision under test |
|---|---|---|---|
| TC-SAFE-001 | Safety | Service/Widget | Bypass providers for explicit personal crisis language and show 911/NCMH/trusted-person guidance. |
| TC-SAFE-002 | Boundary | Unit | Detect English, Filipino, mixed-case, and punctuated crisis variants. |
| TC-SAFE-003 | Safety | Unit/Widget | Use supporter guidance when the concern is about someone else. |
| TC-SAFE-004 | Negative | Unit | Avoid crisis false positives for ordinary distress and educational mentions. |
| TC-SAFE-005 | Safety | Service | Replace diagnostic, medication-change, and dependency-forming provider output. |
| TC-SAFE-006 | Security | Service | Block hidden prompts, reasoning, provider metadata, tokens, and private-text leakage. |

### TS-05 Privacy, isolation, and account deletion

| Test case | Type | Test level | Decision under test |
|---|---|---|---|
| TC-PRIV-001 | Security | Isolated DB/Integration | Deny anonymous and cross-user reads while allowing owner reads. |
| TC-PRIV-002 | Security | Isolated DB/Integration | Reject cross-user insert, update, and delete operations. |
| TC-PRIV-003 | Privacy | Widget/Integration | Persist the seven-day wellbeing-context opt-out. |
| TC-PRIV-004 | Privacy | Service | Exclude recent wellbeing memory and unrelated entries from an opted-out AI request. |
| TC-PRIV-005 | Security | Edge integration | Enforce JWT/request bounds and keep private text, keys, tokens, and model output out of logs. |
| TC-PRIV-006 | Security | End-to-end | Require typed `DELETE` and remove auth identity, cascading rows, and Kaibigan local preferences. |
| TC-PRIV-007 | Recovery | End-to-end | Preserve the account on deletion failure and complete one safe retry without orphaned data. |

### TS-06 Offline mode and connectivity recovery

| Test case | Type | Test level | Decision under test |
|---|---|---|---|
| TC-OFF-001 | Persistence | Integration | Enter offline mode with a scoped local identity rather than a fake cloud session. |
| TC-OFF-002 | Persistence | Provider integration | Save/read journal, mood, gratitude, routine-log, and future-letter records locally. |
| TC-OFF-003 | Persistence | Integration | Restore offline choice and valid records after relaunch. |
| TC-OFF-004 | Recovery | Provider integration | Isolate a malformed local record without crashing or erasing valid data. |
| TC-OFF-005 | Recovery | Integration/Manual device | Report backend states accurately and change modes without false sync or local deletion claims. |

### TS-07 Mood and wellness tracking

| Test case | Type | Test level | Decision under test |
|---|---|---|---|
| TC-MOOD-001 | Boundary | Provider integration | Save valid minimum and maximum 1-to-5 scores. |
| TC-MOOD-002 | Positive | Widget/Integration | Edit only the note while preserving the record ID, scores, and timestamp. |
| TC-MOOD-003 | Security | Integration | Cancel or confirm deletion without affecting a control record. |
| TC-MOOD-004 | Negative | Provider | Reject scores 0 and 6 without changing stored data. |
| TC-MOOD-005 | Analytics | Unit/Widget | Sort same-day entries newest first and calculate an exact 3.7 recent average from valid data only. |

### TS-08 Gratitude garden

| Test case | Type | Test level | Decision under test |
|---|---|---|---|
| TC-GRAT-001 | Positive | Integration | Persist one note and its chosen flower placement without duplication. |
| TC-GRAT-002 | Negative | Widget/Provider | Reject a whitespace-only gratitude note without changing counts. |
| TC-GRAT-003 | Boundary | Unit/Integration | Unlock at 10 and keep progression/remaining placements stable after an edit or deletion, with a flower already in Garden 2. |

### TS-09 Wellness routines and runner

| Test case | Type | Test level | Decision under test |
|---|---|---|---|
| TC-RTN-001 | Positive | Integration | Create and reopen a custom routine with exact step order. |
| TC-RTN-002 | Functional | Widget | Skip a step without marking it complete or emitting an extra completion. |
| TC-RTN-003 | Mobile | Manual device | Resume the same routine step after backgrounding without timer double-run. |
| TC-RTN-004 | Recovery | Integration/Manual device | Resume one persisted session after process termination without creating a second session. |
| TC-RTN-005 | Integrity | Provider/Integration | Write one validated completion log and reject an invalid score fixture. |

### TS-10 Breathing and grounding activities

| Test case | Type | Test level | Decision under test |
|---|---|---|---|
| TC-CALM-001 | Positive | Widget | Complete the 5-4-3-2-1 stages in order and log only after the final action. |
| TC-CALM-002 | Positive | Widget | Complete compact 3-2-1 grounding and return one completion to the same routine. |
| TC-CALM-003 | Mobile | Widget/Manual device | Keep a 30-second breathing timer, audio, pause/resume, rotation/background, and cancel/confirm exit behavior consistent. |

### TS-11 Profile, language, theme, and personalization

| Test case | Type | Test level | Decision under test |
|---|---|---|---|
| TC-PERS-001 | Positive | Widget/Integration | Enable Save only for a real name change and persist it without changing unrelated settings. |
| TC-PERS-002 | Localization | Widget/Integration | Persist English/Filipino preference and render supported key screens without placeholders or overflow. |
| TC-PERS-003 | Persistence | Integration | Migrate/persist Dark theme and manual Day garden lighting without local-time override. |

### TS-12 Future letters

| Test case | Type | Test level | Decision under test |
|---|---|---|---|
| TC-LTR-001 | Positive | Integration | Create a future letter whose body stays locked before delivery. |
| TC-LTR-002 | Negative | Widget/Provider | Reject a delivery time in the past. |
| TC-LTR-003 | Boundary | Unit/Integration | Unlock at the exact delivery instant and write `openedAt` once. |
| TC-LTR-004 | Security | Integration | Cancel or confirm deletion without affecting a control letter. |

The current UI does not support editing an existing delivered letter, so the earlier edit expectation was removed.

### TS-13 Mental wellness learning

| Test case | Type | Test level | Decision under test |
|---|---|---|---|
| TC-LRN-001 | Positive | Unit/Widget | Rank relevant vetted content for a plain-language search. |
| TC-LRN-002 | Persistence | Widget/Provider | Resume lesson progress, complete required cards, and save one toolkit idea. |
| TC-LRN-003 | Security | Service simulation/Cloud integration | Restore the same user's progress while isolating another account. |
| TC-LRN-004 | Safety | Service | Keep answers lesson-grounded and block unrelated or injected prompts before model use. |
| TC-LRN-005 | Safety | Service | Route diagnosis, medication, and crisis questions to the correct safe boundary. |

### TS-14 Home, history, and daily reflection

| Test case | Type | Test level | Decision under test |
|---|---|---|---|
| TC-HOME-001 | Positive | Widget/Integration | Show correct greeting/streak, at most three favorites, and route current work without duplicate sessions. |
| TC-HOME-002 | Persistence | Integration | Persist Today's Focus, Highlight, and Daily Reflection only for the owning date/identity. |
| TC-HOME-003 | Analytics | Unit/Widget | Generate insights from valid recent evidence without fabricated patterns or crisis-text motivation. |
| TC-HOME-004 | Navigation | Widget | Open the correct unified-history viewer and show a genuine empty state. |

### TS-15 Mobile resilience, accessibility, and reminders

| Test case | Type | Test level | Decision under test |
|---|---|---|---|
| TC-MOB-001 | Accessibility | Widget/Manual device | Avoid overflow and keep primary actions reachable at 320x700 and 1.6 text scale. |
| TC-MOB-002 | Accessibility | Manual accessibility | Provide unique labels, logical focus order, usable states, and operable touch targets. |
| TC-MOB-003 | Mobile | Manual device | Preserve an authenticated journal draft and routine step across rotation, background, and relaunch. |
| TC-MOB-004 | Permissions | Manual device | Handle notification denial, grant, update, cancel, and later revocation without duplicates or guaranteed-delivery claims. |

### TS-16 Sleep logging and honest sleep insights

| Test case | Type | Test level | Decision under test |
|---|---|---|---|
| TC-SLEEP-001 | Positive | Widget/Provider | Save 23:00-to-07:00 as one eight-hour sleep log with the correct feeling/times. |
| TC-SLEEP-002 | Compatibility | Unit | Parse current and legacy sleep logs while excluding non-sleep routine logs. |
| TC-SLEEP-003 | Analytics | Unit/Widget | Calculate 6.8-hour average and 4.5-hour debt from exact recent fixtures while excluding old data. |
| TC-SLEEP-004 | Boundary | Unit/Widget | Show honest empty, slight, high/deprived, and severe statuses with bounded recovery guidance. |

### TS-17 Affirmations

| Test case | Type | Test level | Decision under test |
|---|---|---|---|
| TC-AFF-001 | Content | Unit | Validate six categories with 30 unique safe English and Filipino reminders each. |
| TC-AFF-002 | Persistence | Unit/Widget | Persist the selected focus and keep the daily reminder stable for the same date. |
| TC-AFF-003 | Localization | Widget | Use the selected category's complete Filipino feed and correct finite counter. |

### TS-18 Mobile network interruption

| Test case | Type | Test level | Decision under test |
|---|---|---|---|
| TC-NET-001 | Recovery | Manual device | Preserve a journal entry, name the unreachable backend, and avoid a duplicate when the connection drops during save. |
| TC-NET-002 | Recovery | Integration / Manual device | End a failed AI reflection within the bounded wait without storing a partial reply or blocking saving. |

### TS-19 Interruption by call or notification

| Test case | Type | Test level | Decision under test |
|---|---|---|---|
| TC-INT-001 | Mobile | Manual device | Suspend a timed session and its ambient audio across a phone call and log exactly one completion. |
| TC-INT-002 | Mobile | Manual device | Return to the same grounding stage with earlier answers intact and no duplicate completion. |

### TS-20 Orientation change resilience

| Test case | Type | Test level | Decision under test |
|---|---|---|---|
| TC-ORI-001 | Mobile | Manual device | Preserve unsaved journal text, cursor, and reachable controls through a rotation. |
| TC-ORI-002 | Mobile | Manual device | Continue a session timer, animation, and audio through a rotation without reset or double-run. |

### TS-21 Notification permission denial

| Test case | Type | Test level | Decision under test |
|---|---|---|---|
| TC-PERM-001 | Permissions | Manual device | Keep the app usable and the reminder state honest when notification permission is denied. |
| TC-PERM-002 | Permissions | Manual device | Follow an out-of-app permission change without duplicate schedules or false delivery claims. |

TS-18 to TS-21 come from the Activity 3 mobile scenario work. Notifications are the only runtime permission Kaibigan requests, so TS-21 is written against it rather than camera, microphone, location, or storage.

## Execution guidance

1. Use disposable QA identities and synthetic wellness text. Never use a real person's sensitive journal or crisis content.
2. Run P0 cases before P1 and P2.
3. Record Actual Result, Status, and Defect/Evidence in the workbook. A non-`Not Run` status should have an observed result; a failure should also have evidence or a defect ID.
4. Run provider failures, RLS checks, Edge Function security, and account deletion only in a controlled QA Supabase project.
5. Run mobile coverage on at least one narrow phone with large text, screen-reader review, rotation/background/resume, and notification permission changes.
