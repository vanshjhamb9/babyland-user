# Post-Pregnancy Dashboard — Backend Integration Guide

**Audience:** Backend / API team (`Baby-Land-Node-Server-main`)  
**Mobile reference:** Flutter rebuild in `lib/features/post_pregnancy/` (May 2026)  
**Base URL:** `https://<host>/api/v1` (production example: `http://164.52.197.176/api/v1`)  
**Auth:** `Authorization: Bearer <JWT>` on all endpoints below unless noted.

---

## 1. Executive summary

**Yes — the backend must implement or fix several APIs** for the postpartum dashboard to be fully server-driven (not client-estimated).

The Flutter app now includes a **Postpartum Recovery Engine** that can compute scores locally when the API returns empty data, but **production quality requires the server to own**:

| Priority | Item | Why |
|----------|------|-----|
| **P0** | `GET /health-insights` returns **dashboard contract** with `healthSummary.postpartumRecovery` | App’s Recovery Score™ and enrichment read this first |
| **P0** | Align `POST/GET /postpartums/logs` with stored schema + computed `scores` | Full recovery assessment + trends |
| **P0** | `GET /postpartums/get/recovery-task` returns **aggregated** task bundle (not raw task array only) | Hero shows task %; feeding list embedded |
| **P1** | `GET /postpartums/logs` supports **date range** (7-day trend) | Weekly recovery chart without 7 round-trips |
| **P1** | Server-side **recovery analytics** endpoint (recommended new) | Single source for overall %, weekly delta, streak |
| **P2** | Unify journal + daily log + mental health into consistent read model | Mood/hydration/sleep on dashboard |
| **P2** | `GET /postpartums/ai-insights` → structured insights matching `aiInsights[]` | IRA / insight cards |

**Out of scope for this doc:** Consultation checkout PostgreSQL (`CONSULTATION_DATABASE_URL`) — separate booking/payments workstream.

---

## 2. Architecture (data flow)

```text
Patient logs (Mongo)
  ├─ PostpartumLog        POST/GET /postpartums/logs
  ├─ PostpartumJournal    POST      /postpartums/journal
  ├─ FeedingLog           POST/GET  /postpartums/feeding/*
  ├─ RecoveryTask         GET/POST  /postpartums/get/recovery-task
  └─ Hydration (Phase 3)  GET/POST  /hydration

                    ↓ aggregate + score (server)

  GET /health-insights  ──► healthSummary.postpartumRecovery
                      ──► hydration, sleep, symptoms
                      ──► aiInsights[] (category: recovery)
                      ──► recommendations[]

                    ↓

              Flutter Postpartum Dashboard
```

---

## 3. Critical gap: `GET /health-insights`

### 3.1 What the mobile app expects today

`DashboardService` calls **`GET /api/v1/health-insights`** and parses:

```json
{
  "success": true,
  "data": {
    "healthSummary": { ... },
    "aiInsights": [ ... ],
    "predictiveAlerts": [ ... ],
    "recommendations": [ ... ],
    "lastUpdated": "2026-05-24T07:00:00.000Z"
  }
}
```

`healthSummary.postpartumRecovery` (required for postpartum stage):

| Field | Type | Range | Notes |
|-------|------|-------|--------|
| `physicalHealingScore` | number | 0–100 | Also accepts nested `scores.physicalScore` |
| `uterineRecoveryScore` | number | 0–100 | |
| `energyStrengthScore` | number | 0–100 | |
| `overallScore` | number | 0–100 | **Shown in hero**; also `scores.overallScore` |
| `alertsTriggered` | boolean | | Clinical alert flag |
| `physicalStatus` | string | | e.g. `Improving`, `Monitor`, `Normal` |
| `uterineStatus` | string | | |
| `energyStatus` | string | | e.g. `Strong`, `Building` |

**Alternate nested shape (supported by Flutter parser):**

```json
"postpartumRecovery": {
  "scores": {
    "physicalScore": 78,
    "uterineScore": 72,
    "energyScore": 81,
    "overallScore": 77
  },
  "physicalStatus": "Improving",
  "uterineStatus": "Normal",
  "energyStatus": "Strong",
  "alertsTriggered": false
}
```

`healthSummary.hydration` (used for charts + scoring):

| Field | Type | Example |
|-------|------|---------|
| `today` | int | ml consumed today |
| `weeklyAverage` | number | ml/day avg |
| `goal` | int | default 2500 if omitted |
| `trend` | string | `up` \| `down` \| `stable` |

`healthSummary.sleep`:

| Field | Type | Example |
|-------|------|---------|
| `lastNight` | int | minutes |
| `weeklyAverage` | number | minutes |
| `goal` | int | default 480 |
| `quality` | number | 0–100 optional |

`aiInsights[]` (recovery cards):

| Field | Type | Example |
|-------|------|---------|
| `id` | string | |
| `title` | string | |
| `description` | string | |
| `category` | string | **`recovery`** for postpartum dashboard |
| `generatedAt` | ISO datetime | |

### 3.2 What the server returns today (gap)

Current `src/modules/healthInsights/service.js` returns AI/trend payload (`insights`, `healthData`, `source`) — **not** the `healthSummary` dashboard envelope.

**Action:** Extend `GET /health-insights` (or add `GET /health-insights/dashboard?stage=postpregnancy`) that:

1. Detects user stage = `postpregnancy`.
2. Aggregates last 7 days: postpartum logs, journal, hydration, tasks, feeding.
3. Runs server scoring (section 6).
4. Returns the JSON shape in §3.1.

Until fixed, Flutter **fills gaps client-side** (`postpartum_dashboard_enrichment.dart`) — acceptable for dev, **not** for production analytics integrity.

---

## 4. Existing endpoints the app uses (postpartum)

All paths are under **`/api/v1/postpartums`** (mounted in `app.js`).

### 4.1 Profile / onboarding

| Method | Path | Purpose |
|--------|------|---------|
| `POST` | `/add` | Create postpartum tracker after delivery |

**Request body (Flutter):**

```json
{
  "deliveryDate": "2026-01-15",
  "deliveryType": "Normal",
  "babyDetails": {
    "name": "Baby Name",
    "date": "2026-01-15",
    "gender": "Male"
  }
}
```

`deliveryType`: `Normal` \| `c_section` (Flutter normalizes `C-Section` → `c_section`).

**Response:** `{ "success": true, "data": { ...profile } }`

---

### 4.2 Daily logs (mood, symptoms, stress, sleep, recovery payload)

| Method | Path | Purpose |
|--------|------|---------|
| `POST` | `/logs` | Create **one log per calendar day** (duplicate day → error) |
| `GET` | `/logs` | List logs; query `?date=YYYY-MM-DD` optional |

**POST body after Flutter `_buildDailyLogContractPayload`:**

```json
{
  "date": "2026-05-24",
  "mentalHealth": {
    "mood": "Good",
    "notes": "",
    "score": 8
  },
  "hydration": {
    "waterIntake": 1200,
    "target": 2000
  },
  "sleepQuality": 4,
  "physical": {
    "pain": 2,
    "woundHealing": 4,
    "swelling": "none"
  },
  "uterine": {
    "bleedingLevel": 3,
    "cramps": "mild"
  },
  "energy": {
    "energyLevel": "moderate",
    "fatigue": "low",
    "sleepQuality": 4
  }
}
```

**Full recovery log (Recovery Track & Scale screen)** uses the same `POST /logs` with structured `physical` / `uterine` / `energy` as above (`pain` 0–10).

**GET response (Flutter `MenstrualLogsListModel`):**

```json
{
  "success": true,
  "message": "Get Logs Successfully",
  "data": [
    {
      "date": "2026-05-24",
      "mood": "good",
      "stressLevel": "low",
      "anxietyLevel": null,
      "symptoms": ["fatigue"],
      "sleepQuality": 4,
      "mentalHealth": { "mood": "Good", "score": 8, "notes": "" },
      "hydration": { "waterIntake": 1200, "target": 2000 }
    }
  ]
}
```

**Backend gaps to fix:**

- Mongoose `PostpartumLog` model (`physicalHealing` 1–5) **does not match** service `addLog` (`physical.pain` 0–10) — align schema or map on write.
- Persist and return **`scores`** on every log: `physicalScore`, `uterineScore`, `energyScore`, `overallScore`.
- Return **`sleepQuality`** at top level (alias from `energy.sleepQuality`) — Flutter reads both.
- Support **`?from=YYYY-MM-DD&to=YYYY-MM-DD`** for 7-day dashboard trend (P1).

---

### 4.3 Journal (quick daily progress)

| Method | Path | Purpose |
|--------|------|---------|
| `POST` | `/journal` | Upsert journal for a day |

**Request (Flutter `submitJournalLog`):**

```json
{
  "date": "2026-05-24",
  "painScore": 2,
  "woundHealingScore": 4,
  "swellingScore": 5,
  "mobilityScore": 4,
  "energyScore": 4,
  "strengthScore": 5,
  "physicalHealing": { "score": 75 },
  "energyStrength": { "score": 90 },
  "mood": "Good"
}
```

**Backend should:**

- Map 1–5 sliders → 0–100 pillar scores (same weights as §6 or store raw + computed).
- Merge into daily read model so `GET /logs?date=today` or `/health-insights` reflects journal without a second full assessment.

---

### 4.4 Recovery tasks

| Method | Path | Purpose |
|--------|------|---------|
| `GET` | `/get/recovery-task` | Dashboard task list + metadata |
| `POST` | `/recovery-task/add` | Mark task complete (body includes task fields) |
| `POST` | `/recovery-task/update/:taskId` | Update task |

**Query:** `?date=YYYY-MM-DD` (Flutter sends today).

**Response shape required by Flutter (`RecoveryProgressModel`):**

```json
{
  "success": true,
  "tasks": {
    "totalTasks": "5",
    "completedTasks": "2",
    "completionPercentage": "40.0",
    "tasks": [
      {
        "task": "Take prescribed medication",
        "dateAssigned": "2026-05-24T00:00:00.000Z",
        "dueDate": "2026-05-24T00:00:00.000Z",
        "completed": false,
        "_id": "..."
      }
    ],
    "logDate": "2026-05-24",
    "mood": "good",
    "stressLevel": null,
    "anxietyLevel": null,
    "symptoms": [],
    "feedings": [
      {
        "notes": "Morning feed",
        "type": "breast",
        "time": "2026-05-24T08:00:00.000Z"
      }
    ]
  }
}
```

**Note:** Flutter parses top-level `tasks` object (not only `data.tasks`). Confirm controller wraps accordingly.

**Gap:** `getRecoveryTasks` currently returns a **raw task array** from Mongo — implement **aggregator** that adds `completionPercentage`, embeds today’s **feedings** and **mood** from logs.

---

### 4.5 Feeding

| Method | Path | Purpose |
|--------|------|---------|
| `POST` | `/feeding/add` | Add feeding entry |
| `GET` | `/feeding` | List feeding logs |

After `POST /feeding/add`, mobile refreshes **`GET /get/recovery-task`** (not only `/feeding`) so feedings appear on home.

---

### 4.6 Recovery progress (legacy)

| Method | Path | Purpose |
|--------|------|---------|
| `GET` | `/progress` | Returns `{ progress: number }` (0–100 formula) |

**Not used** by the new dashboard hero (uses weighted engine + tasks). Can remain for backward compatibility.

---

### 4.7 Postpartum AI insights (legacy route)

| Method | Path | Purpose |
|--------|------|---------|
| `GET` | `/ai-insights` | Query `?category=recovery` |

**Current response** is a simple object (`insight`, `recommendations`, `postpartumWeek`).  

**Target:** Either map into `GET /health-insights` → `aiInsights[]`, or return:

```json
{
  "success": true,
  "data": {
    "insights": [
      {
        "id": "...",
        "title": "Hydration on track",
        "description": "...",
        "category": "recovery",
        "generatedAt": "2026-05-24T07:00:00.000Z"
      }
    ]
  }
}
```

---

## 5. Phase 3 trackers (hydration — already used)

| Method | Path | Purpose |
|--------|------|---------|
| `GET` | `/hydration` | Paginated logs; query `from`, `to`, `page`, `limit` |
| `POST` | `/hydration` | Add water intake (`amountMl`, `timestamp`, `type`) |
| `GET` | `/hydration/daily-total` | Optional shortcut for “today” total |

**Hydration log item:**

```json
{
  "_id": "...",
  "userId": "...",
  "amountMl": 250,
  "type": "water",
  "timestamp": "2026-05-24T06:52:18.796Z",
  "timezone": "UTC",
  "source": "manual"
}
```

Flutter aggregates last **7 days** client-side for charts. Server should also expose totals in `healthSummary.hydration.today` / `weeklyAverage`.

---

## 6. Recommended server recovery scoring engine

Align with Flutter `PostpartumRecoveryEngine` (weights below) so web/admin and mobile match.

### 6.1 Pillar scores (0–100)

**Physical** (from log/journal):

- Pain: 0–10 inverted → up to 25 pts  
- Wound / swelling / mobility: categorical → up to 25 pts each  

**Uterine:**

- Cramps + belly reduction progress  

**Energy:**

- Energy level + fatigue + activity + sleep quality (1–5)

Existing `calculateScores()` in `postpartumService.js` is a **simplified** version — extend to match Flutter `TrackerMath` or adopt this weighted model:

### 6.2 Overall score (0–100)

```
clinical =
  physical * 0.22 +
  uterine * 0.12 +
  energy * 0.18 +
  hydrationConsistency * 0.12 +
  moodScore * 0.12 +
  sleepScore * 0.10 +
  symptomWellness * 0.08 +
  logConsistency * 0.06

overall = clinical * 0.88 + taskCompletionPercent * 0.12
```

| Input | Source |
|-------|--------|
| `hydrationConsistency` | min(100, todayMl / goal * 100), goal default **2000 ml** |
| `moodScore` | mental health score 1–10 → ×10 |
| `sleepScore` | sleepQuality 1–5 → ×20 |
| `symptomWellness` | max(0, 100 - symptomCount * 15) |
| `logConsistency` | days with any log in last 7 / 7 × 100 |
| `taskCompletionPercent` | from recovery tasks |

### 6.3 Weekly trend (7 points)

For each day `d` in [today-6, today]:

```json
{
  "date": "2026-05-24",
  "overallScore": 72,
  "moodScore": 8,
  "hydrationMl": 1800
}
```

---

## 7. Recommended new endpoint (P1)

### `GET /api/v1/postpartums/recovery-analytics`

**Query:** `?days=7` (default 7)

**Response:**

```json
{
  "success": true,
  "data": {
    "overallScore": 78,
    "physicalHealingScore": 80,
    "uterineRecoveryScore": 74,
    "energyStrengthScore": 76,
    "taskCompletionPercent": 40,
    "weeklyDeltaPercent": 12,
    "recoveryStreakDays": 6,
    "logsThisWeek": 5,
    "weeklyTrend": [
      { "date": "2026-05-18", "score": 65, "moodScore": 7, "hydrationMl": 900 },
      { "date": "2026-05-19", "score": 0, "moodScore": 0, "hydrationMl": 0 }
    ],
    "insights": [
      {
        "title": "Strong weekly momentum",
        "body": "You are recovering faster this week (+12% trend).",
        "tone": "positive"
      }
    ],
    "breakdown": [
      { "label": "Physical", "value": 80, "unit": "%", "iconKey": "pain" },
      { "label": "Streak", "value": 6, "unit": "days", "iconKey": "streak" }
    ],
    "computedAt": "2026-05-24T07:39:54.282Z"
  }
}
```

Flutter can switch to this endpoint later; **`GET /health-insights` must still populate `postpartumRecovery`** for other dashboard widgets.

---

## 8. MongoDB collections (datasets)

| Collection / model | Key fields | Indexes |
|--------------------|------------|---------|
| `PostpartumProfile` | `userId`, `deliveryDate`, `deliveryType`, `babyDetails` | `userId` unique |
| `PostpartumLog` | `userId`, `date`, `physical*`, `uterine*`, `energy*`, `scores`, `alertsTriggered` | `{ userId, date }` unique |
| `PostpartumJournal` | `userId`, `date`, slider scores, nested healing scores | `{ userId, date }` |
| `FeedingLog` | `userId`, `time`, `type`, `notes` | `userId` |
| `RecoveryTask` | `userId`, `task`, `completed`, `dateAssigned`, `dueDate` | `userId`, `dueDate` |
| Hydration (Phase 3) | `userId`, `timestamp`, `amountMl` | `userId`, `timestamp` |

**Sample `PostpartumLog.scores` (persist on every write):**

```json
{
  "physicalScore": 82,
  "uterineScore": 75,
  "energyScore": 79,
  "overallScore": 78
}
```

---

## 9. Personalization inputs (P2)

Pass into scoring / AI context:

| Field | Source |
|-------|--------|
| `deliveryType` | `PostpartumProfile.deliveryType` (`Normal` \| `c_section`) |
| `daysSinceDelivery` | from `deliveryDate` |
| `postpartumWeek` | `ceil(daysSinceDelivery / 7)` |
| `breastfeeding` | infer from feeding logs frequency |
| Doctor recommendations | future: `/postpartums/doctor-appointment` notes |

---

## 10. Error & edge cases

| Case | Expected API behavior |
|------|------------------------|
| No profile | `GET /get/recovery-task` → `success: false` or 404; Flutter redirects to onboarding |
| Duplicate log same day | `POST /logs` → **409** or 400 with clear message |
| No logs yet | `postpartumRecovery` scores = `0` or omit; Flutter shows onboarding empty state |
| Timezone | Store UTC dates; accept `YYYY-MM-DD` query in user-local or UTC consistently |
| Journal same day as full log | Upsert/merge strategy — last write wins or merge fields |

---

## 11. Acceptance criteria (backend QA)

- [ ] `GET /health-insights` for a postpartum user with logs returns `data.healthSummary.postpartumRecovery.overallScore` > 0.
- [ ] `physicalHealingScore`, `uterineRecoveryScore`, `energyStrengthScore` populated and consistent with last log.
- [ ] `data.healthSummary.hydration.today` matches sum of `/hydration` for today.
- [ ] `GET /postpartums/get/recovery-task?date=today` returns `completionPercentage`, `tasks[]`, `feedings[]`, `mood`.
- [ ] `POST /postpartums/logs` returns `scores` + `alertsTriggered` in response `data`.
- [ ] `GET /postpartums/logs?date=YYYY-MM-DD` returns mentalHealth + hydration envelope.
- [ ] At least one `aiInsights[]` item with `category: "recovery"` when AI service available.
- [ ] (P1) `GET /postpartums/logs?from=&to=` returns 7 days in one call.
- [ ] (P1) Optional `GET /postpartums/recovery-analytics` matches §7 shape.

---

## 12. Implementation checklist (suggested order)

1. **Fix `GET /health-insights`** dashboard envelope + postpartum aggregation.  
2. **Normalize `PostpartumLog` schema** vs `addLog` payload; always save `scores`.  
3. **Aggregate `GET /get/recovery-task`** (%, feedings, mood).  
4. **Hydration daily total** in health summary (or call internal hydration service).  
5. **Date-range on `GET /logs`**.  
6. **New `GET /postpartums/recovery-analytics`** (optional but ideal).  
7. Wire **AI insights** into `aiInsights[]` with `category: recovery`.

---

## 13. References (repo paths)

| Area | Flutter | Node |
|------|---------|------|
| Dashboard parser | `lib/core/services/dashboard_service.dart` | `src/modules/healthInsights/` |
| Recovery engine | `lib/features/post_pregnancy/recovery_engine/` | implement in `postpartumService.js` |
| Analytics repo | `lib/features/post_pregnancy/data/postpartum_analytics_repository.dart` | new route suggested §7 |
| Legacy postpartum API | `lib/app/data/repository/repository.dart` | `src/routes/postpartumRoutes.js` |
| Hydration | `lib/core/services/health_tracker_service.dart` | `src/modules/hydration/` |
| Scoring (client) | `lib/features/trackers/utils/tracker_math.dart` | align server formulas |

---

## 14. Contact / versioning

- Document version: **1.0** (2026-05-24)  
- Breaking changes to `health-insights` shape must be coordinated with mobile **before** release APK cut.  
- Flutter can ship with client-side fallback until P0 backend items are live.
