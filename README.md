# Hotspot Hosts – Onboarding Questionnaire

A Flutter application for onboarding **Hotspot Hosts**, designed to assess potential hosts through experience selection and intent-based questions with multimedia input.

Hotspot Hosts facilitate community events and gatherings.  
This onboarding flow helps evaluate their intent, creativity, and readiness by collecting textual, audio, and video responses in a clean, interactive interface.

---

##  Implemented Features

### 1. Experience Type Selection Screen
- Fetches experiences from API.
- Supports multiple selection & deselection.
- Cards show grayscale when unselected.
- Includes a multi-line textfield (limit: 600 characters).
- Navigates to the onboarding question screen.

### 2. Onboarding Question Screen
- Multi-line textfield (limit: 600 characters).
- **Audio Recording** with live waveform animation.
- **Video Recording** using the device camera.
- Option to cancel while recording.
- Delete existing recordings.
- UI dynamically hides record buttons when assets exist.
- Responsive layout — handles keyboard visibility safely.
- “Next” button animates width when record buttons disappear.

---

## Brownie Points Implemented
- State management handled via **Riverpod**.
- Local storage using **Hive** for saving and retrieving recordings.
- Optional playback for audio and video implemented.
- Safe disposal of controllers to prevent app freeze.
---

## ⚙️ Tech Stack
- **Flutter**
- **Riverpod** (state management)
- **Dio** (API integration)
- **Hive** (local storage)
- **record / camera / audio_waveforms** (recording)
- **path_provider** (file management)

---


