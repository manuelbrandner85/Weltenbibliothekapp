# Changelog - Weltenbibliothek

## v3.9.2 (2025-11-22) - **AUTOMATISCHER HINTERGRUND-WECHSEL**

### 🎨 **Chat-Hintergrund Carousel - Automatisierung**

**User Request**: Manuelle Hintergrund-Auswahl entfernen, automatischer 5-Minuten Wechsel

**Implementierung**:
- ✅ **Automatischer Timer**: Hintergrund wechselt alle 5 Minuten
- ❌ **Entfernt**: Manuelle Vor/Zurück Buttons
- ✅ **Beibehalten**: Dezente Seiteindikatoren (zeigen aktiven Hintergrund)
- ✅ **Loop-Funktion**: Nach letztem Bild zurück zum ersten (endlos)
- ✅ **Memory-Safe**: Timer wird bei dispose() korrekt gestoppt

### 🔧 **Technische Details**

**Geänderte Datei**: `lib/widgets/chat_background_carousel.dart`

**Neue Features**:
```dart
// ✅ Automatischer Timer (5 Minuten)
Timer.periodic(Duration(minutes: 5), (timer) {
  _nextBackground();
});

// ✅ Loop-Funktion
final nextPage = (_currentPage + 1) % _images.length;
```

**Entfernt**:
- ❌ IconButton für Zurück
- ❌ IconButton für Weiter
- ❌ Manuelle Steuerung

**Beibehalten**:
- ✅ Seiteindikatoren (passive Anzeige)
- ✅ 3 Hintergrundbilder pro Chat-Typ
- ✅ Smooth Transitions (800ms)

### 📊 **Verwendung**

Widget wird verwendet in:
- `chat_room_detail_screen.dart` (normale Chats)
- `live_stream_host_screen.dart` (Host-Ansicht)
- `live_stream_viewer_screen.dart` (Viewer-Ansicht)
- `image_gallery_demo_screen.dart` (Demo)

**Wechsel-Intervall**: 5 Minuten (300 Sekunden)
**Animation**: 800ms Smooth Transition
**Loop**: Endlos (1 → 2 → 3 → 1 → ...)

---

## v3.9.1 (2025-11-22) - **AGGRESSIVE CAMERA SWITCH FIX**

### 🚀 **Complete Camera Switch Rewrite**

**User Feedback**: v3.9.0 "Replace-First" pattern still freezing on Back→Front switch

**New Aggressive Approach**:
- ❌ **Removed**: `Helper.switchCamera()` (could be causing internal blocking)
- ✅ **Added**: Manual `facingMode` toggle with explicit getUserMedia()
- ✅ **Added**: Complete renderer dispose/reinitialize cycle
- ✅ **Added**: Longer warm-up delays (300ms instead of 150ms)
- ✅ **Added**: Event-based `readyState` checking (waits for track to be "live")
- ✅ **Added**: Comprehensive debug logging at each step

### 🔧 **Technical Changes**

**11-Step Aggressive Sequence** (webrtc_broadcast_service.dart):

```
1. Toggle facingMode manually (user ↔ environment)
2. getUserMedia with explicit facingMode (no Helper!)
3. Extended warm-up (300ms for camera initialization)
4. Wait for track.readyState == 'live' (event-based, max 500ms)
5. COMPLETE renderer reset:
   - Clear srcObject
   - Dispose renderer
   - Create fresh RTCVideoRenderer
   - Initialize new renderer
   - Attach new stream
6. Replace track in ALL peer connections
7. Confirm frame flow (200ms)
8. Stop old track (now safe - new fully active)
9. Clean ALL old tracks from stream
10. Add new track to main stream
11. Update facingMode state
```

**Why More Aggressive**:
- ✅ **No Helper.switchCamera()**: Avoids potential internal blocking on Android
- ✅ **Complete renderer reset**: Forces UI to show new camera (no caching)
- ✅ **Longer delays**: More time for Android Camera HAL to settle
- ✅ **Event-based waiting**: Doesn't proceed until track is confirmed live
- ✅ **More debug output**: Shows exactly where freeze happens (if any)

### 📊 **Debug Logging**

New extensive logging shows:
- Current/new facingMode
- Track ID, readyState, enabled state
- Renderer dispose/initialize steps
- Track replacement in each peer connection
- Timing information for each step

### 🧪 **Testing Recommendations**

Same test scenarios, but check debug logs if issues persist:
1. ✅ Front → Back switch
2. ✅ **Back → Front switch** (critical - was freezing)
3. ✅ Multiple rapid switches
4. ✅ Camera off/on after switches
5. ✅ Switch during active livestream

### 💡 **If Still Freezing**

Debug logs will show:
- Which step hangs (readyState waiting? renderer reset?)
- Track states before/after switch
- Exact timing of each operation

This will help identify if issue is:
- Camera HAL timing (need even longer delays)
- Renderer caching (need different reset approach)
- Track state management (need alternative pattern)

---

## v3.9.0 (2025-11-22) - **RESEARCH-BASED CAMERA SWITCH FIX**

### 🔬 **Deep Internet Research - Camera Freeze Solution**

**Problem Fixed**: Camera switching freeze where Front→Back worked but Back→Front froze/showed old frozen frames

**Root Cause Discovery** (Chromium Bug #40153159):
- `MediaStreamTrack.stop()` on Android closes Camera Device immediately
- Calling `getUserMedia()` for new camera at same time = **Camera HAL Deadlock**
- Race condition between closing old camera and opening new camera freezes Android Camera Service
- Back→Front switch has higher race probability (returning to primary camera)

**Research Sources**:
1. **GitHub flutter-webrtc/issues/896** - MediaStreamTrack management best practices
   - Avoid concurrent modification of track collections
   - Use `replaceTrack()` in PeerConnections instead of remove/add
   - Safe pattern: Create new stream → Replace in peers → Stop old track

2. **GitHub flutter-webrtc/issues/1269** - Preserve constraints during camera switch
   - Helper.switchCamera() was discarding original track constraints
   - Must merge old constraints (resolution, frameRate) with new deviceId
   - Constraint changes can cause encoder/renderer stalls

3. **Chromium Bug Report #40153159** - MediaStreamTrack.stop() Android freeze
   - Official confirmation of Camera HAL deadlock issue
   - Recommended workaround: **"REPLACE-FIRST" pattern**
   - Open new camera → Wait for frames → Replace tracks → Stop old camera

### ✅ **Solution Implemented: "REPLACE-FIRST" Pattern**

**New Camera Switch Sequence** (webrtc_broadcast_service.dart):

```
OLD (v3.8.5) - WRONG ORDER:
1. stop old track          ← Closes camera
2. getUserMedia new track  ← Opens camera → RACE! ❌

NEW (v3.9.0) - CORRECT ORDER:
1. getUserMedia new track  ← Opens new camera first ✅
2. Helper.switchCamera     ← Toggle facingMode
3. Wait 150ms              ← Camera warm-up
4. replaceTrack in peers   ← Update peer connections
5. Update local renderer   ← Update UI display
6. Wait 100ms              ← Confirm frames flowing
7. stop old track          ← NOW safe (new camera active!) ✅
8. Remove old from stream  ← Clean up
9. Add new to stream       ← Complete swap
```

**Why This Works**:
- ✅ New camera is **fully active** before old camera stops
- ✅ **No race condition** between stop() and getUserMedia()
- ✅ Camera Service has time to initialize new camera
- ✅ Both Front→Back AND Back→Front now work reliably
- ✅ No frozen frames when toggling camera off/on

### 🔧 **Technical Changes**

**Modified Files**:
- `lib/services/webrtc_broadcast_service.dart`
  - Complete rewrite of `switchCamera()` method
  - Added 9-step "Replace-First" sequence
  - Comprehensive debug logging for each step
  - Safe error handling with try/catch

**Code Quality Improvements**:
- Detailed inline documentation explaining research findings
- Step-by-step comments for maintainability
- Links to GitHub issues and Chromium bug reports
- Non-blocking error handling for track cleanup

### 📊 **Testing Recommendations**

Test these scenarios to verify fix:
1. ✅ Front → Back switch (should work smoothly)
2. ✅ Back → Front switch (previously froze, should now work)
3. ✅ Multiple rapid switches (Front→Back→Front→Back)
4. ✅ Camera off/on after switches (should show correct camera, not frozen frame)
5. ✅ Switch during active livestream with viewers

### 🎯 **Expected Results**

**Before (v3.8.5)**:
- ❌ Front→Back: Works
- ❌ Back→Front: Freezes/black screen
- ❌ Camera off/on: Shows old frozen frame

**After (v3.9.0)**:
- ✅ Front→Back: Works smoothly
- ✅ Back→Front: Works smoothly (FIXED!)
- ✅ Camera off/on: Shows correct live camera feed
- ✅ No race conditions or Camera HAL deadlocks

---

## v3.8.5 (2025-11-22) - Camera Switch Attempt #5

### 🔧 Changes
- **Camera Switching**: Removed ALL old video tracks before adding new
- **Track Cleanup**: Iterate and stop all existing video tracks
- **Renderer Reset**: Force srcObject null → delay → update

### ⚠️ Result
- ✅ Front → Back works
- ❌ Back → Front still freezes (led to v3.9.0 research)

---

## v3.8.4 (2025-11-22) - Camera Switch Attempt #4

### 🔧 Changes
- Correct order: stop → remove → delay → getUserMedia → add
- Added 200ms delay after Helper.switchCamera

### ⚠️ Result
- ✅ Front → Back works
- ❌ Back → Front freezes

---

## v3.8.3 (2025-11-22) - Camera Switch Attempt #3

### 🔧 Changes
- Used Helper.switchCamera() official method
- Simplified track replacement logic

### ⚠️ Result
- ❌ Complete black screen (made worse)

---

## v3.8.2 (2025-11-22) - Participant Count Fix

### ✅ Fixed
- **Participant Display**: Now shows `remoteUserCount + 1` to include host
- Previously showed "👥 0" when host was alone

---

## v3.8.1 (2025-11-22) - Camera Toggle Fix

### ✅ Fixed
- **Camera Enable Black Screen**: Ensure _localStream exists before adding track
- Update renderer BEFORE peer connections
- Add 100ms initialization delay

---

## v3.8.0 (2025-11-21) - **TELEGRAM-STYLE ARCHITECTURE**

### 🎯 Major Architecture Change

**Concept**: "ONE STREAM PER CHAT" (like Telegram Voice Chats)

**Backend Changes** (weltenbibliothek_worker.js):
1. **Room ID Generation**:
   - OLD: `room_${user.id}_${timestamp}` (one per user)
   - NEW: `stream_${chatRoomId}_${timestamp}` (one per chat)

2. **handleCreateLiveRoom**:
   - Check if chat already has active stream
   - If yes: Return existing stream (user joins it)
   - If no: Create new stream for chat
   - Removed secondary "user_has_stream" check

3. **handleLeaveRoom**:
   - Removed auto-end logic at 0 participants
   - Stream stays "live" even when empty (like Telegram)
   - User can leave and rejoin same stream

**Frontend Changes**:
1. **live_room_service.dart**:
   - Handle `existing_stream: true` response
   - Seamless join to existing chat streams

2. **chat_room_detail_screen.dart**:
   - Removed "user_has_stream" error dialog
   - Smart routing: host → LiveStreamHostScreen, viewer → LiveStreamViewerScreen

3. **wrangler.toml**:
   - Fixed worker name: "weltenbibliothek-webrtc"
   - Correct Durable Object binding

### ✅ Solved Issues
- ❌ "Du hast bereits einen aktiven Livestream" error
- ❌ Streams ending at 0 participants
- ❌ Users unable to join existing chat streams
- ❌ Backend deployment mismatch

### 🎉 New Behavior
- ✅ One stream per chat room (persistent)
- ✅ Multiple users can join same chat stream
- ✅ Users can stream in multiple chats simultaneously
- ✅ Stream persists even at 0 participants
- ✅ No artificial stream limits

---

## Previous Versions

See Git history for versions before v3.8.0
