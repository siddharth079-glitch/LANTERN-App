# 🚨 LANTERN — Light When Communication Fails

> **Offline-First Disaster SOS Coordination & Peer-to-Peer Rescue Platform**

LANTERN is a resilient emergency response and disaster coordination mobile application designed to operate reliably when conventional communications, cellular networks, and internet connectivity fail. Featuring an offline-first architecture, local SQLite queuing, multi-hop mesh relay simulation, an interactive dark-mode incident tactical map, and a centralized rescue operations backend.

---

## 🌟 Key Features

- **🚨 Instant SOS Dispatch & Beaconing:** One-touch SOS distress beacon generation with automated GPS telemetry, severity scoring, and category tagging (Medical, Structural Collapse, Flood, Fire, Hazardous Materials, Missing Persons).
- **📡 Offline-First Store-and-Forward Engine:** Incidents are captured locally in an ACID-compliant SQLite outbox database and queued for automatic synchronization the moment connectivity is restored or relayed.
- **🔄 Multi-Hop Peer-to-Peer Mesh Relay:** Supports store-and-forward relay across nearby peer devices with hop tracking, relay path logging, and cryptographic idempotency.
- **🗺️ Interactive Dark Tactical Map:** Real-time visual disaster map powered by `flutter_map` and OpenStreetMap with glowing beacon rings, responder location pins, shelter clusters, and offline tile caching.
- **🏥 Evacuation Shelters & Resources Directory:** Searchable directory of emergency shelters, triage field hospitals, safe havens, and supply distribution hubs with real-time occupancy and capacity tracking.
- **🛡️ Offline First-Aid & Safety Guidelines:** Comprehensive, offline-accessible disaster guides covering earthquake, flood, fire, hurricane, trauma stabilization, and emergency triage protocols.
- **👥 Community Broadcast & Incident Timeline:** Live feed of verified neighborhood incidents, responder status updates (DISPATCHED, EN_ROUTE, ON_SCENE, RESOLVED), and safety alerts.
- **🖥️ Central Operations Backend & Rescue Dashboard:** Node.js WebSocket and HTTP REST backend with real-time live ops dispatch dashboard (`/dashboard`) and telemetry sync engine.

---

## 🏗️ Architecture & Technology Stack

### Mobile Application (`/lib`)
- **Framework:** [Flutter](https://flutter.dev) (Dart 3.x)
- **State Management:** [Riverpod](https://riverpod.dev) (`flutter_riverpod: ^2.6.1`)
- **Navigation:** [GoRouter](https://pub.dev/packages/go_router) (`go_router: ^14.8.1`)
- **Local Database:** [sqflite](https://pub.dev/packages/sqflite) (`sqflite: ^2.4.1`)
- **Mapping & Geolocation:** [flutter_map](https://pub.dev/packages/flutter_map) (`^7.0.2`), [latlong2](https://pub.dev/packages/latlong2), [geolocator](https://pub.dev/packages/geolocator)
- **Networking:** [dio](https://pub.dev/packages/dio), [connectivity_plus](https://pub.dev/packages/connectivity_plus)
- **UI Design System:** Glassmorphism, dark tactical HUD theme, Google Fonts (`Inter`), Flutter SVG

### Central Backend Service (`/backend`)
- **Runtime:** Node.js (v18+)
- **Protocols:** HTTP/1.1 REST API + WebSockets (`ws: ^8.18.0`)
- **Database:** SQLite (`node:sqlite` DatabaseSync with automated schema migration)
- **Live Ops Dashboard:** Real-time tactical incident command console (`backend/public/dashboard/index.html`)

---

## 📁 Repository Structure

```
├── android/               # Android native configuration and Gradle build files
├── assets/                # Application brand assets, vectors, and imagery
│   ├── icons/             # Custom SVG icons and logos
│   └── images/            # Hero imagery and promotional graphics
├── backend/               # Central Operations Backend service
│   ├── data/              # SQLite database storage (runtime auto-created)
│   ├── public/dashboard/  # Real-time incident command web dashboard
│   ├── test/              # Backend integration and endpoint test suite
│   ├── package.json       # Node.js dependencies and run scripts
│   └── server.js          # Central HTTP/WebSocket dispatch engine
├── lib/                   # Flutter application source code
│   ├── app/               # Navigation routing and dark tactical theme
│   ├── core/              # Core infrastructure services
│   │   ├── database/      # SQLite helper, schema definitions, and migrations
│   │   ├── location/      # GPS telemetry and permission handlers
│   │   ├── relay/         # Multi-hop mesh relay protocols
│   │   └── sync/          # Store-and-forward outbox synchronization engine
│   ├── features/          # Domain feature modules
│   │   ├── auth/          # User verification and profile setup
│   │   ├── community/     # Community alert feeds and volunteer coordination
│   │   ├── contacts/      # Emergency contacts and direct calling
│   │   ├── home/          # Tactical HUD home screen and quick actions
│   │   ├── incidents/     # Incident tracking, filtering, and detail views
│   │   ├── map/           # Interactive live disaster map and beacon layer
│   │   ├── messages/      # Peer-to-peer and responder messaging
│   │   ├── onboarding/    # First-run permissions and safety briefing
│   │   ├── relay/         # Mesh relay diagnostics and active hops
│   │   ├── safety_guide/  # Offline disaster preparedness and first-aid guides
│   │   ├── settings/      # Network configuration, host IPs, and telemetry
│   │   ├── shelters/      # Shelter directory and occupancy stats
│   │   ├── sos/           # One-touch SOS emergency creation sheet
│   │   └── splash/        # Application launch sequence
│   ├── shared/            # Reusable UI widgets, cards, badges, and controls
│   └── main.dart          # Mobile application entry point
├── test/                  # Unit and widget test suite
├── web/                   # Web application deployment manifest and shell
├── analysis_options.yaml  # Dart analyzer and linting rules
├── pubspec.yaml           # Flutter package manifest and dependencies
└── README.md              # Project documentation
```

---

## 🚀 Getting Started

### 1. Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (version 3.13.5 or newer)
- [Node.js](https://nodejs.org/) (v18.0.0 or newer)
- Android Studio / Android SDK (for Android device or emulator testing)

### 2. Start the Central Operations Backend
```bash
# Navigate to the backend directory
cd backend

# Install dependencies
npm install

# Start the operations server
node server.js
```
The backend starts at:
- **REST API:** `http://localhost:3000`
- **WebSocket Feed:** `ws://localhost:3000/ws`
- **Live Ops Dashboard:** `http://localhost:3000/dashboard`

### 3. Run the Mobile Application
In a separate terminal at the project root:
```bash
# Install Flutter packages
flutter pub get

# Run tests
flutter test

# Launch on connected device or emulator
flutter run
```

To configure the Central Operations Backend IP address on physical test devices, open the **Settings** tab in the LANTERN app and enter your host machine's local network IP address (e.g., `http://192.168.x.x:3000`).

---

## 🔒 Security & Privacy

- All sensitive build outputs, local keys, and temporary cache directories are strictly excluded from source control via `.gitignore`.
- Offline incident records are securely stored on-device using isolated SQLite storage.
- Real-world deployment supports end-to-end payload signature verification across mesh relay hops.

---

## 📄 License

This project is licensed under the MIT License — see the repository files for details.
