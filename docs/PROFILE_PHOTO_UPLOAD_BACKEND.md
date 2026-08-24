# Profile Photo Upload — Backend Fix Guide

Production API: `http://164.52.197.176/api/v1`

## Summary

Profile photo upload fails for **prepregnancy** (and most non-postpregnancy) users because multipart upload endpoints return **HTTP 500**. JSON-only profile updates work; only file upload paths are broken.

## Observed failure (2026-08-23)

| Field | Value |
|---|---|
| User | Vansh Jhamb (`vansh@gmail.com`, `+916398253031`) |
| Stage | `prepregnancy` |
| Client payload | `{name: Vansh Jhamb, phone: +916398253031}` + multipart `photo` |
| Server timestamps (UTC) | `2026-08-23T13:49:15Z`, `13:49:27Z`, `13:49:34Z` |
| Client log | `Multipart profile photo DioException (status=500), trying fallback` |

## Broken endpoints

| Endpoint | Method | Field | Status |
|---|---|---|---|
| `/users/profile-update` | PUT | `photo` (multipart) | **500** |
| `/fileuploads/single` | POST | `file` (multipart) | **500** |

## Working endpoints (reference)

| Endpoint | Method | Notes |
|---|---|---|
| `/users/profile-update` | PUT JSON | `{name, phone, photo: "<url>"}` returns 200 |
| `/users/getUser` | GET | Returns user profile |
| `/babygrowths/add/photo` | POST multipart | Works only for postpregnancy users with baby tracker |

## Reproduction (authenticated)

Replace `<JWT>` with a valid token from a prepregnancy user.

```bash
# 1. Multipart profile update — currently 500
curl -X PUT 'http://164.52.197.176/api/v1/users/profile-update' \
  -H 'auth-token: <JWT>' \
  -H 'Authorization: Bearer <JWT>' \
  -F 'name=Vansh Jhamb' \
  -F 'phone=+916398253031' \
  -F 'photo=@/path/to/test.jpg'

# 2. Generic file upload — currently 500
curl -X POST 'http://164.52.197.176/api/v1/fileuploads/single' \
  -H 'auth-token: <JWT>' \
  -H 'Authorization: Bearer <JWT>' \
  -F 'file=@/path/to/test.jpg'

# 3. JSON-only update — works (proves auth + route OK)
curl -X PUT 'http://164.52.197.176/api/v1/users/profile-update' \
  -H 'auth-token: <JWT>' \
  -H 'Authorization: Bearer <JWT>' \
  -H 'Content-Type: application/json' \
  -d '{"name":"Vansh Jhamb","phone":"+916398253031","photo":"https://example.com/test.jpg"}'
```

## Automated probe

From the repo root:

```bash
dart run tools/test_profile_photo_e2e.dart --token=<JWT>
```

## Backend investigation targets

- Multer / file-storage middleware on `profile-update` and `fileuploads/single` (Cloudinary/S3 config, missing env vars)
- Server logs at failure timestamps above
- Confirm `photo` field name on profile-update and `file` on fileuploads/single
- Confirm `stage=prepregnancy` is not rejected server-side
- Expected multipart success: `{ success: true, ... }` with updated user including `photo` / `profilePicture` URL

## Acceptance criteria

- Prepregnancy user can upload via direct multipart `PUT /users/profile-update`
- `POST /fileuploads/single` returns `{ success: true, data: { url: "..." } }`
- `dart run tools/test_profile_photo_e2e.dart --token=<JWT>` passes all probes
