/// 📊 TELEGRAM-STYLE VOICE CHAT SYSTEM - VISUAL ARCHITECTURE
/// 
/// Dieses File zeigt die visuelle Architektur des Voice-Chat-Systems

/*

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📱 USER INTERFACE FLOW
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

┌─────────────────────────────────────────────────────────────────┐
│                      CHAT SCREEN                                │
│  ┌────────────────────────────────────────────────────────┐    │
│  │  🎙 Voice Chat Available                              │    │
│  │  Join and discuss with others in real-time           │    │
│  │                              [Join Voice Chat] ──────────┐  │
│  └────────────────────────────────────────────────────────┘  │  │
│                                                               │  │
│  [Messages...]                                               │  │
│  [Messages...]                                               │  │
│  [Messages...]                                               │  │
│                                                               │  │
│  ┌────────────────────────────────────────┐                  │  │
│  │ 🎙 Sprachchat aktiv | 3 members  [X] │ ◄────────────────┘  │
│  └────────────────────────────────────────┘                     │
│           ▲                                                     │
│           │ (Minimized Overlay)                                │
│           │                                                     │
│           │ [TAP to maximize]                                  │
│           │                                                     │
│           ▼                                                     │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │            TELEGRAM VOICE SCREEN                        │  │
│  │  ┌──────────────────────────────────────────────────┐  │  │
│  │  │  🎭 Geopolitik & Weltordnung      [–] [X]       │  │  │
│  │  │  3 members                                        │  │  │
│  │  └──────────────────────────────────────────────────┘  │  │
│  │                                                         │  │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐               │  │
│  │  │  ┌───┐  │  │  ┌───┐  │  │  ┌───┐  │               │  │
│  │  │  │ 🟢 │  │  │  │ MB │  │  │  │ JS │  │               │  │
│  │  │  └───┘  │  │  └───┘  │  │  └───┘  │               │  │
│  │  │ Manuel  │  │  Maria  │  │  John   │               │  │
│  │  │ (You)   │  │ Bauer   │  │  Smith  │               │  │
│  │  └─────────┘  └─────────┘  └─────────┘               │  │
│  │         ▲                                              │  │
│  │         │ (Pulsing Ring = Speaking)                   │  │
│  │                                                         │  │
│  │              [🎤 Mute]    [📞 Leave]                   │  │
│  └─────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🏗️ SYSTEM ARCHITECTURE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

                  ┌────────────────────────────────┐
                  │    Flutter App (UI Layer)     │
                  └────────────┬───────────────────┘
                               │
        ┌──────────────────────┼──────────────────────┐
        │                      │                      │
┌───────▼─────────┐   ┌────────▼────────┐   ┌───────▼────────┐
│ Telegram        │   │ Minimized       │   │ Voice Chat     │
│ Voice Screen    │   │ Voice Overlay   │   │ Button         │
│                 │   │                 │   │                │
│ • User Tiles    │   │ • Floating Bar  │   │ • Join Button  │
│ • Speaking Anim │   │ • Tap → Max     │   │ • Status       │
│ • Mute Toggle   │   │ • Leave Button  │   │ • Participant  │
│ • Leave Call    │   │ • Room Info     │   │   Count        │
└────────┬────────┘   └────────┬────────┘   └───────┬────────┘
         │                     │                     │
         └─────────────────────┼─────────────────────┘
                               │
                  ┌────────────▼───────────────┐
                  │   VoiceCallController      │
                  │   (ChangeNotifier)         │
                  │                            │
                  │  • Global State            │
                  │  • Participant List        │
                  │  • Speaking Detection      │
                  │  • Minimize/Maximize       │
                  │  • Stream Management       │
                  └────────────┬───────────────┘
                               │
                  ┌────────────▼───────────────┐
                  │   WebRTCVoiceService       │
                  │   (Singleton)              │
                  │                            │
                  │  • Audio Streams           │
                  │  • Peer Connections        │
                  │  • ICE Servers (STUN/TURN) │
                  │  • Echo Cancellation       │
                  │  • Noise Suppression       │
                  └────────────┬───────────────┘
                               │
         ┌─────────────────────┼─────────────────────┐
         │                     │                     │
┌────────▼────────┐   ┌────────▼────────┐   ┌──────▼────────┐
│ Local Stream    │   │ Remote Streams  │   │ ICE Servers   │
│                 │   │                 │   │               │
│ • Microphone    │   │ • Peer Audio    │   │ • STUN        │
│ • Echo Cancel   │   │ • Multiple      │   │ • TURN        │
│ • Noise Supress │   │   Participants  │   │   (optional)  │
└─────────────────┘   └─────────────────┘   └───────────────┘


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔄 DATA FLOW: Join Voice Chat
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  User                UI                Controller           WebRTC
   │                  │                    │                   │
   │  [Tap Join]      │                    │                   │
   ├─────────────────►│                    │                   │
   │                  │  joinVoiceRoom()   │                   │
   │                  ├───────────────────►│                   │
   │                  │                    │  initialize()     │
   │                  │                    ├──────────────────►│
   │                  │                    │                   │
   │                  │                    │ ◄─────getUserMedia()
   │                  │                    │   (Mic Permission)
   │                  │                    │                   │
   │                  │                    │  joinRoom()       │
   │                  │                    ├──────────────────►│
   │                  │                    │                   │
   │                  │  State: Connected  │                   │
   │                  │ ◄──────────────────┤                   │
   │                  │                    │                   │
   │  [Voice Screen]  │                    │                   │
   │ ◄────────────────┤                    │                   │
   │                  │                    │                   │
   │  [See Tiles]     │  participantsStream│                   │
   │ ◄────────────────┤ ◄──────────────────┤                   │
   │                  │                    │                   │


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎤 SPEAKING DETECTION LOGIC
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

┌─────────────────────────────────────────────────────────────────┐
│                    Speaking Detection Timer                      │
│                    (Every 100ms)                                 │
└────────────────────────────┬────────────────────────────────────┘
                             │
         ┌───────────────────┼───────────────────┐
         │                   │                   │
┌────────▼────────┐ ┌────────▼────────┐ ┌───────▼────────┐
│ User A          │ │ User B          │ │ User C         │
│                 │ │                 │ │                │
│ Audio Level:    │ │ Audio Level:    │ │ Audio Level:   │
│   0.05          │ │   0.01          │ │   0.00         │
│                 │ │                 │ │                │
│ > Threshold?    │ │ > Threshold?    │ │ > Threshold?   │
│   ✅ YES        │ │   ❌ NO         │ │   ❌ NO        │
│                 │ │                 │ │                │
│ Frames: 3/3     │ │ Frames: 0/3     │ │ Frames: 0/3    │
│                 │ │                 │ │                │
│ → SPEAKING! 🟢  │ │ → Listening     │ │ → Listening    │
└─────────────────┘ └─────────────────┘ └────────────────┘
         │
         │
         ▼
┌─────────────────────────────────────────┐
│  UI Update: Show Pulsing Ring on User A │
└─────────────────────────────────────────┘


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎨 UI STATE TRANSITIONS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   IDLE                  CONNECTING              CONNECTED
┌────────┐              ┌─────────┐            ┌──────────────┐
│        │  Join Room   │         │   Success  │              │
│  ⚪    ├─────────────►│   🟡    ├───────────►│     🟢       │
│        │              │         │            │              │
└────────┘              └─────────┘            └──────┬───────┘
                              │                       │
                              │ Error                 │ Minimize
                              ▼                       ▼
                        ┌─────────┐            ┌──────────────┐
                        │   ❌    │            │  MINIMIZED   │
                        │  ERROR  │            │     🟢📉     │
                        └─────────┘            └──────┬───────┘
                                                      │ Maximize
                                                      ▼
                                               ┌──────────────┐
                                               │  CONNECTED   │
                                               │     🟢       │
                                               └──────────────┘


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📱 RESPONSIVE GRID LAYOUT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Mobile (< 600px):           Tablet (600-900px):        Desktop (> 900px):
2-3 Columns                 3-4 Columns                4-6 Columns

┌─────┬─────┐              ┌─────┬─────┬─────┐         ┌────┬────┬────┬────┐
│  A  │  B  │              │  A  │  B  │  C  │         │ A  │ B  │ C  │ D  │
├─────┼─────┤              ├─────┼─────┼─────┤         ├────┼────┼────┼────┤
│  C  │  D  │              │  D  │  E  │  F  │         │ E  │ F  │ G  │ H  │
├─────┼─────┤              └─────┴─────┴─────┘         ├────┼────┼────┼────┤
│  E  │  F  │                                           │ I  │ J  │ K  │ L  │
└─────┴─────┘                                           └────┴────┴────┴────┘

(Automatically adjusts based on participant count)


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔊 AUDIO PIPELINE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Microphone Input
      │
      ▼
┌──────────────────┐
│ Echo Cancellation│ ← Removes echo
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│Noise Suppression │ ← Removes background noise
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│Auto Gain Control │ ← Normalizes volume
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Local Stream    │ ← Your audio
└────────┬─────────┘
         │
         ├─────────────────────┐
         │                     │
         ▼                     ▼
┌──────────────────┐   ┌──────────────────┐
│  WebRTC Peer     │   │  Audio Level     │
│  Connection      │   │  Monitoring      │
└────────┬─────────┘   └────────┬─────────┘
         │                      │
         │                      ▼
         │              ┌───────────────┐
         │              │  Speaking     │
         │              │  Detection    │
         │              └───────┬───────┘
         │                      │
         ▼                      ▼
┌──────────────────┐   ┌───────────────┐
│  Remote Peers    │   │  UI Updates   │
│  (Other Users)   │   │  (Pulsing)    │
└──────────────────┘   └───────────────┘


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 COMPONENT RESPONSIBILITIES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

┌────────────────────────────────────────────────────────────────┐
│                    VoiceCallController                         │
│  ✅ Global State Management                                   │
│  ✅ Participant Tracking                                       │
│  ✅ Speaking Detection Logic                                   │
│  ✅ Minimize/Maximize State                                    │
│  ✅ UI Notifications (ChangeNotifier)                          │
└────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────┐
│                    WebRTCVoiceService                          │
│  ✅ Audio Stream Management                                    │
│  ✅ Peer Connection Handling                                   │
│  ✅ ICE Server Configuration                                   │
│  ✅ Media Constraints (Echo Cancel, etc.)                      │
│  ✅ Signaling (TODO: Server Implementation)                    │
└────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────┐
│                    TelegramVoiceScreen                         │
│  ✅ User Tile Grid Rendering                                   │
│  ✅ Speaking Animation (Pulsing Ring)                          │
│  ✅ Control Bar (Mute, Leave)                                  │
│  ✅ Responsive Layout                                          │
└────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────┐
│                    MinimizedVoiceOverlay                       │
│  ✅ Floating Banner Display                                    │
│  ✅ Room Info + Participant Count                              │
│  ✅ Tap to Maximize                                            │
│  ✅ Quick Leave Button                                         │
└────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────┐
│                    VoiceChatButton                             │
│  ✅ Join Voice Chat Action                                     │
│  ✅ Visual Status Indicator                                    │
│  ✅ Switch Room Dialog                                         │
│  ✅ Participant Count Display                                  │
└────────────────────────────────────────────────────────────────┘


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

*/
