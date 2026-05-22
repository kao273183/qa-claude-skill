---
name: push-notification-test
description: Push notification test workflow across APNs (iOS), FCM (Android), Web Push. Verifies delivery rate, click behavior (cold start / warm / background), deep link routing, permission denial fallback, dynamic type layout, batch push performance. Trigger phrases — "push notification test", "APNs", "FCM", "deep link", "notification click", "push permission", "delivery rate", "silent push", "notification action button".
disable-model-invocation: false
allowed-tools: Read, Grep, Glob, Write, Edit, Bash
argument-hint: "[platform ios|android|web] [--scenario=delivery|click|deeplink|permission|all]"
---

# push-notification-test (English)

> ⚙️ Read [`modules/config-loader.md`](./modules/config-loader.md) first.

## Why Push Tests Fail Often
Push flow crosses 4 systems: backend → APNs/FCM → OS → App. Only real devices test the full path (simulators don't support push).

## When to Use
- App uses push (marketing / order / IM / reminders)
- Before changing push payload schema (deep links break easily)
- After major iOS/Android upgrade (permission mechanics change)

## 8 Test Scenarios

### 1. Delivery rate
Background / foreground / killed-app / weak network / silent push.

### 2. Click handling
Cold start / warm / active / locked state — each must route to correct screen.

### 3. Deep link routing
For each payload type: verify route, ID parsing, logged-out fallback, deleted-resource fallback.

### 4. Permission handling
First launch timing, denial recovery, iOS 15+ provisional auth.

### 5. Action buttons (rich push)
Display label/icon, route action, handle without launching app (Notification Service Extension).

### 6. Dynamic type
Title not truncated, body has ellipsis, emoji consistent across sizes.

### 7. Localization
Translated correctly, length doesn't break banner.

### 8. Batch performance
Sending 1M+ recipients within SLA, throttle handling, app cold-start not blocked.

## Workflow

### Phase 1: Setup
- iOS: APNs sandbox/prod cert + real device
- Android: FCM server key + real device or emulator with Google Play
- Tools: Postman / Apple Push Notification Tool / Knuff / Firebase Console

### Phase 2: Generate payloads + send
APNs HTTP/2 curl / Firebase Console / Pusher tool.

### Phase 3: Auto + manual split

| Scenario | Auto | Manual |
|----------|------|--------|
| Deep link parsing | ✅ Unit test | Push trigger needs human |
| Payload schema | ✅ Contract test | - |
| Dynamic type banner | ❌ | ✅ Screenshot |
| Lock screen a11y | ❌ | ✅ VoiceOver read |

### Phase 4: Monitor metrics post-launch
Delivery rate > 95%, click-through rate, permission grant rate, token registration success.

## Safety
- ❌ Push tests not sent to real users (use dev token list)
- ✅ Production cert strict IAM control
- ⚠️ Silent push not for user tracking (privacy compliance)

## Config Dependencies

| Key | Purpose |
|-----|---------|
| `push_notification.platforms` | [ios, android, web] |
| `push_notification.test_devices` | Dev token list |
| `push_notification.deep_link_scheme` | App URL scheme |
| `push_notification.payload_templates_dir` | Templates dir |
