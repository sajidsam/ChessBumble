# ♟️ ChessBumble

<p align="center">
  <img src="docs/images/login_screen.png" alt="ChessBumble Login Screen" width="300" style="border-radius: 20px; box-shadow: 0 8px 30px rgba(0,0,0,0.3);"/>
</p>

<p align="center">
  <strong>A premium, modern chess experience built with Flutter, intelligent AI bots, and an encrypted Node.js backend.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart"/>
  <img src="https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=nodedotjs&logoColor=white" alt="Node.js"/>
  <img src="https://img.shields.io/badge/Express.js-000000?style=for-the-badge&logo=express&logoColor=white" alt="Express"/>
  <img src="https://img.shields.io/badge/MongoDB-47A248?style=for-the-badge&logo=mongodb&logoColor=white" alt="MongoDB"/>
</p>

---

## 📖 Overview

**ChessBumble** is a high-performance, aesthetically crafted chess platform designed with a signature crimson & white visual identity. Featuring custom on-screen authentication, an intelligent Minimax-powered chess bot with human-like deliberation, real-time board themes, and an end-to-end encrypted backend data service, ChessBumble offers a sleek and competitive chess arena on mobile and desktop.

---

## ✨ Features

### 🔐 1. Custom On-Screen Authentication
- **Signature Visual Identity:** Bold crimson background paired with crisp white controls and high-contrast typography.
- **Doto Dot-Matrix Branding:** Custom retro-modern digital branding font.
- **Custom Virtual Keyboard:** Dedicated in-app doodle keyboard with tactile red accent keys (`1`, `2`, `p`, `l`, `m`, `DEL`) for quick and secure code entry.
- **Zero-Friction Access:** Instant login/registration with unique ChessBumble codes.

### 🎮 2. Interactive Chess Arena
- **Comprehensive Chess Rules Engine:** Powered by `chess.dart` supporting legal move generation, check/checkmate detection, castling, and en passant.
- **Live Material Counter & Captures:** Real-time visual tray of captured pieces and material advantage indicators (`+1`, `+3`, etc.).
- **Smart Move Hints:** AI-assisted move suggestions with piece and destination square guidance.
- **Live Move Notation Bar:** Real-time PGN ticker displaying recent game moves.
- **Board Perspective Flipping:** Smooth toggling between White and Black player viewpoints.

### 🤖 3. Intelligent AI Opponents
- **Multi-Tier Difficulty Levels:**
  - **Easy (~800 ELO):** Perfect for beginners, with relaxed positional play.
  - **Medium (~1400 ELO):** Tactical awareness with balanced piece evaluation.
  - **Hard (~1850 ELO):** Positional piece-square tables with deep minimax evaluation.
- **Human-Like Thinking Time:** Realistic thinking delays (1.2s – 3.2s) with randomized variance so the bot deliberate naturally rather than playing instantaneously.

### ⏱️ 4. Dynamic Chess Clocks & Time Controls
- **Vibrant Turn Indicators:** Active player's clock highlights in pure red (`#FF0000`) with a white live dot and borderless finish.
- **Flexible Controls:** Instant switching between **10 min**, **5 min**, **3 min**, and **Unlimited (∞)** timers.
- **Timeout Alerts:** Automatic forfeiture detection when time expires.

### 🎨 5. Board Themes & Customization
Choose from curated board themes to match your aesthetic:
- **Glossy Liquid Red:** Signature bold crimson & white board.
- **Classic Wood:** Traditional warm wooden grain.
- **Tournament Green:** Lichess/FIDE style tournament mat.
- **Slate:** Minimalist modern dark theme.

### 👤 6. Player Profiles & Statistics
- Track player rating (ELO), games played, win rate, and career milestones.
- In-game profile customization with editable usernames and rating adjustment.

### 🔒 7. Secure Backend & Encrypted Info Feed
- **RESTful API:** Express.js and MongoDB backend for user authentication and news feeds.
- **AES-256 CBC Client Encryption:** Secure payload encryption and decryption for sensitive data transmissions.

---

## 📸 Screenshots

| Login & Authentication | Chess Arena | Board Themes & Profiles |
|:---:|:---:|:---:|
| <img src="docs/images/login_screen.png" width="240"/> | Dynamic clocks, hints & AI opponent | Wood, Slate, Green & Liquid Red |

---

## 🛠️ Architecture & Tech Stack

```
MSIc/
├── assets/
│   ├── fonts/               # Custom Doto typography
│   └── images/              # Logos, chess piece sprites (vectors)
├── backend/                 # Node.js + Express API
│   ├── models/              # Mongoose schemas (User, PersonInfo)
│   ├── seed_encrypted_data.js
│   └── server.js            # Authentication & info endpoints
├── docs/
│   └── images/              # Documentation assets & screenshots
└── lib/                     # Flutter Client
    ├── main.dart            # Application theme & route entry
    ├── login_page.dart      # Custom keypad & brand login screen
    ├── home_page.dart       # Interactive chess arena & game engine
    ├── profile_page.dart    # Player career dashboard & stats
    ├── info_feed_page.dart  # AES-256 decrypted announcement feed
    └── services/
        ├── api_service.dart # HTTP client for backend communication
        └── chess_ai.dart    # Minimax AI bot & hint generator
```

---

## 🚀 Getting Started

### Prerequisites
- **Flutter SDK:** `>= 3.12.2` ([Install Flutter](https://flutter.dev/docs/get-started/install))
- **Node.js:** `>= 18.x` ([Download Node.js](https://nodejs.org/))
- **MongoDB:** Local instance or [MongoDB Atlas](https://www.mongodb.com/cloud/atlas)

---

### 1. Backend Setup

```bash
cd backend

# Install dependencies
npm install

# Configure environment variables
# Create a .env file with:
# PORT=5000
# MONGODB_URI=mongodb://127.0.0.1:27017/msic
# (or provide DB_USER and DB_PASS for MongoDB Atlas)

# Seed encrypted data (optional)
node seed_encrypted_data.js

# Start backend server
node server.js
```

---

### 2. Flutter App Setup

```bash
# Return to the project root
cd ..

# Install Flutter dependencies
flutter pub get

# Run on an emulator, connected device, or desktop
flutter run
```

---

## 🧪 Testing & Analysis

Run static code analysis to ensure code quality:

```bash
flutter analyze
```

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
