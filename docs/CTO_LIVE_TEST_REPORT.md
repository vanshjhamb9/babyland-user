# CTO live test report — App Store remediation

**Date:** 2026-09-16 (retest)  
**API under test:** `http://164.52.197.176/api/v1`  
**StoreKit / TestFlight:** not runnable from this Windows environment  

## Verdict: **CONDITIONAL GO** on backend contracts

Previous critical blockers are fixed. Residual: profile-update still forces phone for phone-less users. Real IAP sheet still needs TestFlight.

---

## Retest results (2026-09-16)

| Check | Before | After |
|------|--------|--------|
| Fake Apple receipt | 500 + activated Pro | **422**, no Pro (`subscriptions: []`, `subscriptionActive: false`) |
| Multiple signups with no phone | 2nd → `PHONE_EXISTS` | **3/3 succeed** |
| Report / block / unblock / delete account | OK | OK |
| Block with real user ids | OK | OK (`200 User blocked`) |

Fake verify message:  
`Receipt could not be verified. Ensure you pass a valid JWS signed transaction from StoreKit.`

---

## Residual (should fix, not as critical as before)

### Profile update still requires phone for phone-less users
`PUT /users/profile-update` with only `{ "name": "..." }` for a user created without phone:

`400` — `"Mobile number is mandatory after signup"`

Signup without phone works; editing profile then fails. Prefer allowing name/email updates without requiring phone (Guideline 5.1.1).

---

## Still required outside API probe
- Real StoreKit purchase on TestFlight / sandbox
- App Store Connect product `babyland_pro_monthly` submitted with binary
- iOS screenshots / privacy labels / review recordings

---

## Probe scripts
- `tools/cto_apple_verify_side_effect.dart`
- `tools/cto_app_store_live_probe_v2.dart`
- `tools/cto_retest_blockers.dart`
