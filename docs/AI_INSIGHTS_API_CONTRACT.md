# AI Insights — API contract (authoritative)

This document is the **single source of truth** for the Flutter app and matches the Node server in this repository as of the last update to this file.

**OpenAPI (Swagger UI):** when the server is running, open **`/api-docs`** (e.g. `http://localhost:5000/api-docs`) and find **`GET /api/ai/insights`** under tag **AI Insights** — schemas **`AiInsightsGet200`**, **`AiInsightDocument`**, etc., are generated from JSDoc in `src/routes/aisinsightsRoutes.js`.

There are **two different** “insights” systems:

| Base path | Purpose |
|-----------|---------|
| **`GET /api/ai/insights`** | **Category AI insights** (nutrition / exercise / precautions / wellness): cached `AiInsight` documents, AI refresh when stale. **This is the primary screen contract below.** |
| **`GET /api/v1/insights`** | Separate **rule-based dynamic insights** (6h TTL, cron). Different schema — do not mix parsers. |
| **`POST /api/ai/insights`** | Modular AI gateway flow (`insights.controller.js`): JSON body, cache by Redis — **different request/response** than GET. |

---

## 1) `GET /api/ai/insights` (category insights — AI Insights screen)

| Item | Detail |
|------|--------|
| **Method & path** | `GET /api/ai/insights` |
| **Auth** | **Required:** `Authorization: Bearer <JWT>` (or `auth-token` / `x-auth-token` per server middleware). |
| **User identity** | **Only from JWT** (`req.user.id`). **`userId` query parameter is ignored** (and should not be sent for security/clarity). |
| **Query: `category`** | **Required.** Allowed values **exactly** (lowercase): `nutrition` \| `exercise` \| `precautions` \| `wellness`. Validated in `checkAiInsightAccess` — invalid → **400**. |
| **Query: `week`** | **Optional.** Integer **1–42** when sent. If omitted, server uses `User.pregnancyWeek` when set (1–42), otherwise **1**. Use for pregnancy personalization; non-pregnancy users may omit. |
| **“All categories”** | **No** `category=all` on this endpoint. Loading four tabs with **four GETs** (one per category) **is the intended** pattern here. For a single “all” bucket see `GET /api/v1/insights?category=all` (different product). |

### Subscription / plan gating

Handled by **`checkAiInsightAccess`** **before** the controller:

- **403** `NO_SUBSCRIPTION` — no active subscription  
- **403** `FEATURE_NOT_INCLUDED` — subscription active but plan does not include the feature mapped from that category  

Category → internal feature keys: `nutrition` / `precautions` → `nutritionist_dietitian_consultation`; `exercise` → `yoga_fitness_coaches`; `wellness` → `weekly_wellness_tips`.

---

## 2) Canonical **200 OK** JSON shape (GET)

Top-level:

```json
{
  "success": true,
  "data": {
    "source": "database",
    "dataexit": { }
  }
}
```

- **`source`**: `"database"` (cached row &lt; 7 days old) **or** `"ai-api"` (freshly generated and stored).  
- **`dataexit`**: The insight document (see below).  
- **Authoritative nesting:** the insight payload is always **`data.dataexit`**.  
  - There is **no** `data.data` wrapper for this GET in the controller.  
  - Older docs that showed only `data.data` were **incorrect** for this handler.  
  - Legacy `dataexit` naming is **intentional** in this codebase (Mongo field / historical name).

### `dataexit` object (serialized `AiInsight`)

| Field | Type | Notes |
|------|------|--------|
| `_id` | string | Mongo id |
| `userId` | string | Owner |
| `week` | number | Pregnancy week used (1–42) |
| `category` | string | Same enum as query |
| `items` | array | See items[] below |
| `quick_tip` | object \| null | `{ "emoji": string?, "text": string? }` |
| `createdAt` | string (ISO) | |
| `updatedAt` | string (ISO) | |

### `items[]` elements

| Field | Type |
|------|------|
| `title` | string |
| `emoji` | string (optional / null) |
| `description` | string |
| `_id` | May be present on subdocs depending on Mongoose; treat as optional |

### Example (sanitized) — `GET /api/ai/insights?category=nutrition`

```json
{
  "success": true,
  "data": {
    "source": "database",
    "dataexit": {
      "_id": "507f1f77bcf86cd799439011",
      "userId": "507f191e810c19729de860ea",
      "week": 16,
      "category": "nutrition",
      "items": [
        {
          "title": "Iron-rich snacks",
          "emoji": "🥗",
          "description": "Pair vitamin C with plant iron sources to support absorption."
        }
      ],
      "quick_tip": {
        "emoji": "💧",
        "text": "Hydrate before meals when you can."
      },
      "createdAt": "2026-04-01T10:00:00.000Z",
      "updatedAt": "2026-04-04T08:00:00.000Z"
    }
  }
}
```

Same nesting for `exercise` / `precautions` / `wellness`; only `category` and content differ.

---

## 3) Errors

| Situation | HTTP | Body notes |
|-----------|------|------------|
| Missing / invalid JWT | **401** | `success: false` via auth middleware |
| Missing `category` | **400** | `{ "success": false, "message": "Category is required" }` |
| Invalid `category` | **400** | `{ "success": false, "message": "Invalid category" }` |
| Invalid `week` (not 1–42 when provided) | **400** | `{ "success": false, "message": "week must be an integer between 1 and 42 when provided" }` |
| No subscription | **403** | `success: false`, `error.code: "NO_SUBSCRIPTION"`, `requiresSubscription: true` |
| Plan missing feature | **403** | `success: false`, `error.code: "FEATURE_NOT_INCLUDED"`, `requiresUpgrade: true` |
| AI upstream failure | **502** / **503** | `success: false` via error handler (no **200** with `success: false` for hard errors) |

**Empty insights:** If the AI returns valid JSON with `items: []`, you may still get **200** with `success: true` and empty `items` — treat as **“no rows to show”**, not necessarily an error.

---

## 4) Related endpoints

### `GET /api/menstruals/dashboard/insight`

- **Different feature:** menstrual dashboard AI insight (`menstrualController.insight` / `menstrualServices.insight`).  
- **User id:** from JWT only (`req.user.id`).  
- **Response:** `{ success, message?, data: { insights, message, ... } }` — **not** the same shape as `data.dataexit` above.

### `GET /api/ai/insights` vs `POST /api/ai/insights`

- **GET** → `aisinsightsRoutes` + `insightController.getAiInsights` → **`data.source` + `data.dataexit`**.  
- **POST** → `routes/ai/insights.routes.js` + `insights.controller.generateInsights` → `{ success, requestId, data: <AI payload> }` — **different**; used for aggregated AI generation with body `days`, `stage`, `pregnancyWeek`, `category`.

There is **no** separate legacy path `/api/aisinsights/` mounted in `app.js`; the canonical path is **`/api/ai/insights`**.

---

## 5) Parser recommendation (Flutter)

1. Read **`response['success'] == true`**.  
2. Read **`response['data']['dataexit']`** for the insight document (not `data.data`).  
3. Map **`items`** and **`quick_tip`** from `dataexit`.  
4. Do **not** depend on a nested `success` inside `data` (removed server-side for consistency).

---

## 6) Changelog (server)

- **`data.dataexit` only** under `success: true` (no duplicate `success` inside `data`).  
- **`week` query** optional; **JWT** is the only user id source.  
- **`userId` query** ignored.
