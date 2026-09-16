# Backend contracts — App Store rejection remediation

Flutter-only client is wired to these endpoints. Implement on the API so App Review and production work.

## 1. Apple IAP subscription (monthly Pro)

### `POST /api/v1/subscriptions/apple/verify`

Authenticate with the user JWT.

**Request body**

```json
{
  "platform": "ios",
  "productId": "babyland_pro_monthly",
  "transactionId": "<StoreKit purchaseID>",
  "receiptData": "<serverVerificationData / JWS>",
  "localVerificationData": "<optional>",
  "source": "app_store"
}
```

**Server must**

1. Verify the receipt / signed transaction with Apple (App Store Server API).
2. Activate Pro for this user for **exactly one month** from purchase (or Apple’s period end for auto-renewable).
3. Return `{ "success": true, ... }` and ensure `GET /subscriptions/me` then reports `status: active` (or equivalent) plus ideally `expiresAt` ISO-8601.

**Product ID in App Store Connect:** `babyland_pro_monthly` (must match Flutter constant).

### `GET /api/v1/subscriptions/me`

When active, include:

```json
{
  "status": "active",
  "expiresAt": "2026-10-14T12:00:00.000Z"
}
```

When the month ends, mark expired/inactive so the client shows **Upgrade to Pro** again and locks Insights / AI / other Pro gates.

---

## 2. UGC moderation (Guideline 1.2)

### `POST /api/v1/moderation/reports`

```json
{
  "targetType": "post",
  "targetId": "<postId>",
  "reason": "spam|harassment|hate|sexual|other",
  "notes": "optional"
}
```

Notify / store for developer moderation.

### `POST /api/v1/users/:userId/block`

Block user; record for developer notice. Client also filters the feed immediately.

### `DELETE /api/v1/users/:userId/block`

Unblock (optional).

### `GET /api/v1/users/blocked`

Return list of blocked user ids (or `{ data: [ { "_id": "..." } ] }`).

---

## 3. Account deletion (Guideline 5.1.1)

### `DELETE /api/v1/users/me`

Permanently delete the authenticated account and associated personal data.  
Do **not** only deactivate. Client clears local session after success.

---

## 4. Phone optional (Guideline 5.1.1)

Stop requiring `phone` on signup / Google / Apple / profile update.  
Client no longer hard-blocks empty phone; backend should accept accounts without phone.
