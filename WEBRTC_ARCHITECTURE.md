# WebRTC Architektur - Weltenbibliothek

## 📋 Übersicht

Vollständige WebRTC-Implementierung mit Mesh-Netzwerk-Topologie für Multi-User Live-Streaming.

## 🏗️ Architektur-Komponenten

### 1. **ICE Server Konfiguration**

```dart
final Map<String, dynamic> _iceServers = {
  'iceServers': [
    {
      'urls': ['stun:stun.cloudflare.com:3478']
    },
    {
      'urls': ['turn:relay.cloudflare.com:3478?transport=udp'],
      'username': 'cf_turn',
      'credential': 'cf_turn'
    }
  ],
  'iceCandidatePoolSize': 10,
  'sdpSemantics': 'unified-plan'
};
```

**Features:**
- ✅ Cloudflare STUN Server für NAT-Traversal
- ✅ Cloudflare TURN Server für Firewall-Umgehung
- ✅ Optimierte ICE Candidate Pool Size
- ✅ Unified Plan SDP Semantics (Standard)

### 2. **Peer Connection Management**

#### Datenstruktur:
```dart
class RoomConnection {
  final Map<String, RTCPeerConnection> peerConnections;  // peerId -> PeerConnection
  final Map<String, MediaStream> remoteStreams;          // peerId -> MediaStream
  final Map<String, RTCVideoRenderer> remoteRenderers;   // peerId -> VideoRenderer
  final Map<String, PeerInfo> participants;              // peerId -> Metadata
}
```

#### Implementierte Funktionen:

**createPeerConnection()**
```dart
Future<void> _createPeerConnection(String roomId, String peerId) async {
  // 1. WebRTC PeerConnection erstellen
  final pc = await createPeerConnection(_iceServers);
  
  // 2. Lokale Tracks hinzufügen
  _localStream?.getTracks().forEach((track) {
    pc.addTrack(track, _localStream!);
  });
  
  // 3. Remote Track Handler
  pc.onTrack = (RTCTrackEvent event) {
    // Video Renderer initialisieren
    final renderer = RTCVideoRenderer();
    renderer.initialize().then((_) {
      renderer.srcObject = event.streams[0];
      room.remoteRenderers[peerId] = renderer;
    });
  };
  
  // 4. ICE Candidate Handler
  pc.onIceCandidate = (RTCIceCandidate candidate) {
    _sendSignalingMessage(roomId, {
      'type': 'ice_candidate',
      'to': peerId,
      'candidate': candidate.toMap(),
    });
  };
  
  // 5. State Monitoring
  pc.onIceConnectionState = (state) { /* Logging */ };
  pc.onConnectionState = (state) { /* Logging */ };
  pc.onSignalingState = (state) { /* Logging */ };
  
  // 6. In Map speichern
  room.peerConnections[peerId] = pc;
}
```

**createOffer()**
```dart
Future<void> _createOffer(String roomId, String peerId) async {
  final pc = room.peerConnections[peerId];
  
  // 1. SDP Offer erstellen
  final offer = await pc.createOffer();
  
  // 2. Als lokale Description setzen
  await pc.setLocalDescription(offer);
  
  // 3. An Peer senden
  _sendSignalingMessage(roomId, {
    'type': 'offer',
    'to': peerId,
    'from': _currentUsername,
    'sdp': offer.toMap(),
  });
}
```

**createAnswer()**
```dart
Future<void> _handleOffer(String roomId, Map<String, dynamic> message) async {
  final from = message['fromPeerId'] as String;
  final sdp = message['sdp'];
  
  // 1. Peer Connection erstellen (falls nicht vorhanden)
  if (!room.peerConnections.containsKey(from)) {
    await _createPeerConnection(roomId, from);
  }
  
  final pc = room.peerConnections[from];
  
  // 2. Remote Description setzen
  await pc.setRemoteDescription(
    RTCSessionDescription(sdp['sdp'], sdp['type'])
  );
  
  // 3. Answer erstellen
  final answer = await pc.createAnswer();
  await pc.setLocalDescription(answer);
  
  // 4. Answer senden
  _sendSignalingMessage(roomId, {
    'type': 'answer',
    'to': from,
    'from': _currentUsername,
    'sdp': answer.toMap(),
  });
}
```

**handleIceCandidates()**
```dart
Future<void> _handleIceCandidate(String roomId, Map<String, dynamic> message) async {
  final from = message['from'] as String;
  final candidateMap = message['candidate'] as Map<String, dynamic>;
  
  final pc = room.peerConnections[from];
  
  // ICE Candidate hinzufügen
  final candidate = RTCIceCandidate(
    candidateMap['candidate'],
    candidateMap['sdpMid'],
    candidateMap['sdpMLineIndex'],
  );
  
  await pc.addCandidate(candidate);
}
```

**closeConnection()**
```dart
Future<void> leaveRoom(String roomId) async {
  final room = _rooms[roomId];
  
  // 1. Alle Peer Connections schließen
  for (final pc in room.peerConnections.values) {
    await pc.close();
  }
  
  // 2. Alle Renderer aufräumen
  for (final renderer in room.remoteRenderers.values) {
    await renderer.dispose();
  }
  
  // 3. WebSocket schließen
  room.signalingChannel?.sink.close();
  
  // 4. Raum entfernen
  _rooms.remove(roomId);
}
```

### 3. **Signaling System**

#### Cloudflare Worker (Durable Objects)

**Architektur:**
```
Client 1 ←→ WebSocket ←→ Durable Object ←→ WebSocket ←→ Client 2
                              ↓
                         Room State
                         (Sessions Map)
```

**Unterstützte Nachrichten:**

```javascript
// 1. Raum beitreten
{
  "type": "join",
  "peerId": "user123",
  "roomId": "room456",
  "uid": "user123"
}

// Response: Peer-Liste
{
  "type": "peers-list",
  "peers": ["user456", "user789"]
}

// Broadcast an andere:
{
  "type": "peer-joined",
  "peerId": "user123",
  "roomId": "room456"
}

// 2. Raum verlassen
{
  "type": "leave"
}

// Broadcast:
{
  "type": "peer-left",
  "peerId": "user123"
}

// 3. SDP Offer
{
  "type": "offer",
  "toPeerId": "user456",
  "fromPeerId": "user123",
  "sdp": { ... }
}

// 4. SDP Answer
{
  "type": "answer",
  "toPeerId": "user123",
  "fromPeerId": "user456",
  "sdp": { ... }
}

// 5. ICE Candidate
{
  "type": "ice-candidate",
  "toPeerId": "user456",
  "fromPeerId": "user123",
  "candidate": { ... }
}
```

**Mesh Network Implementation:**
- Jeder neue Peer erhält Liste aller bestehenden Peers
- Jeder Peer erstellt Verbindungen zu allen anderen
- Vollständiges Mesh: N Peers = N×(N-1)/2 Verbindungen

### 4. **Multi-User Support**

#### Beispiel: 3 Nutzer im Raum

```
User A (Host)  ←─────→  User B (Viewer 1)
    ↓                       ↓
    ↓                       ↓
    └──────→  User C (Viewer 2)  ←───┘

Verbindungen:
- A ↔ B (1 PeerConnection)
- A ↔ C (1 PeerConnection)
- B ↔ C (1 PeerConnection)
Total: 3 Verbindungen
```

**State Management:**
```dart
Map<String, RTCPeerConnection> peers = {
  'userB': RTCPeerConnection(...),
  'userC': RTCPeerConnection(...),
};

Map<String, RTCVideoRenderer> remoteRenderers = {
  'userB': RTCVideoRenderer(...),
  'userC': RTCVideoRenderer(...),
};
```

### 5. **UI-Komponenten**

#### Host Screen
```dart
Widget _buildViewerGrid() {
  final remoteRenderers = _webrtcService.remoteRenderers;
  
  return Column(
    children: remoteRenderers.entries.map((entry) {
      return RTCVideoView(
        entry.value,  // RTCVideoRenderer
        mirror: false,
        objectFit: RTCVideoViewObjectFitCover,
      );
    }).toList(),
  );
}
```

#### Viewer Screen
```dart
Widget _buildMainVideoView() {
  final renderer = _webrtcService.remoteRenderers[_mainStreamPeerId];
  
  return RTCVideoView(
    renderer,
    mirror: false,
    objectFit: RTCVideoViewObjectFitCover,
  );
}

Widget _buildParticipantsGrid() {
  final otherParticipants = remoteRenderers.entries
      .where((entry) => entry.key != _mainStreamPeerId)
      .toList();
  
  return Column(
    children: [
      // Eigene Kamera
      if (_webrtcService.isCameraEnabled)
        RTCVideoView(_webrtcService.localRenderer),
      
      // Andere Teilnehmer
      ...otherParticipants.map((entry) => 
        RTCVideoView(entry.value)
      ),
    ],
  );
}
```

### 6. **Fehlerbehandlung**

#### WebSocket Wiederverbindung
```dart
class AutoReconnectManager {
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  
  void scheduleReconnect(String roomId) {
    _reconnectTimer = Timer(
      Duration(seconds: _getBackoffDelay()),
      () async {
        await _webrtcService.reconnectToRoom(roomId);
        _reconnectAttempts++;
      },
    );
  }
  
  int _getBackoffDelay() {
    // Exponential Backoff: 2, 4, 8, 16, 32 Sekunden
    return min(pow(2, _reconnectAttempts).toInt(), 32);
  }
}
```

#### ICE Restart bei Verbindungsabbruch
```dart
pc.onIceConnectionState = (RTCIceConnectionState state) {
  if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
    // ICE Restart
    _restartIce(roomId, peerId);
  }
};

Future<void> _restartIce(String roomId, String peerId) async {
  final pc = room.peerConnections[peerId];
  
  // Neue Offer mit ICE Restart erstellen
  final offer = await pc.createOffer({'iceRestart': true});
  await pc.setLocalDescription(offer);
  
  _sendSignalingMessage(roomId, {
    'type': 'offer',
    'to': peerId,
    'sdp': offer.toMap(),
  });
}
```

#### State Logging
```dart
// ICE Connection State
pc.onIceConnectionState = (state) {
  debugPrint('🧊 [WebRTC] ICE State: $state');
  
  switch (state) {
    case RTCIceConnectionState.RTCIceConnectionStateConnected:
      debugPrint('✅ ICE Connected');
      break;
    case RTCIceConnectionState.RTCIceConnectionStateFailed:
      debugPrint('❌ ICE Failed');
      break;
    case RTCIceConnectionState.RTCIceConnectionStateDisconnected:
      debugPrint('⚠️ ICE Disconnected');
      break;
  }
};

// Connection State
pc.onConnectionState = (state) {
  debugPrint('🔗 [WebRTC] Connection State: $state');
};

// Signaling State
pc.onSignalingState = (state) {
  debugPrint('📡 [WebRTC] Signaling State: $state');
};
```

## 🚀 Setup-Anleitung

### 1. Flutter-Projekt einrichten

```bash
# Dependencies installieren
flutter pub get

# Android Build
flutter build apk --release
```

### 2. Cloudflare Worker deployen

```bash
# Worker erstellen
wrangler publish

# Durable Objects Binding konfigurieren
# In wrangler.toml:
[[durable_objects.bindings]]
name = "WEBRTC_ROOMS"
class_name = "WebRTCRoom"
script_name = "webrtc-signaling"
```

### 3. App konfigurieren

In `lib/services/webrtc_broadcast_service.dart`:
```dart
final String _signalingUrl = 'wss://your-worker.workers.dev';
```

## 📊 Performance-Metriken

**Bandbreiten-Anforderungen:**
- 1 Video-Stream (720p): ~1-2 Mbps
- 3 Nutzer (Mesh): ~4-6 Mbps pro Nutzer
- 5 Nutzer (Mesh): ~8-12 Mbps pro Nutzer

**Skalierungs-Limits:**
- Empfohlen: Bis 5 Nutzer (Mesh)
- Maximum: 8-10 Nutzer (abhängig von Bandbreite)

## ✅ Checkliste - Implementierte Features

- [x] **ICE Server Konfiguration** (Cloudflare STUN/TURN)
- [x] **createPeerConnection()** - Vollständige Implementierung
- [x] **addLocalTracks()** - Automatisch in createPeerConnection
- [x] **createOffer()** - SDP Offer Generation
- [x] **createAnswer()** - SDP Answer Generation
- [x] **handleRemoteDescription()** - In handleOffer/handleAnswer
- [x] **handleIceCandidates()** - ICE Candidate Processing
- [x] **closeConnection()** - In leaveRoom()
- [x] **Signaling System** - Cloudflare Workers WebSocket
- [x] **Nutzer tritt bei** - join Message
- [x] **Nutzer verlässt** - leave Message
- [x] **Peer-ID Verteilung** - peers-list Message
- [x] **SDP Routing** - offer/answer Forwarding
- [x] **ICE Routing** - ice-candidate Forwarding
- [x] **Mesh Network** - Jeder verbindet sich mit jedem
- [x] **Map<String, RTCPeerConnection>** - In RoomConnection
- [x] **UI - Remote Videos** - ViewerGrid Widget
- [x] **UI - Lokales Video** - LocalRenderer
- [x] **UI - Join/Leave** - In LiveStreamScreens
- [x] **WebSocket Wiederverbindung** - AutoReconnectManager
- [x] **ICE Restart** - Bei Connection Failed
- [x] **ICE State Logging** - onIceConnectionState
- [x] **Signaling State Logging** - onSignalingState
- [x] **Connection State Logging** - onConnectionState

## 🎯 Nächste Schritte

1. **Testen mit mehreren Geräten**
2. **Monitoring im Production-Einsatz**
3. **Performance-Optimierung** (adaptive Bitrate)
4. **SFU-Migration** (für >10 Nutzer)
