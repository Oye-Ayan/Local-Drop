# Product Requirements Document
## LocalDrop — Cross-Platform Local-Network File & Clipboard Sharing

**Version:** 1.0
**Status:** Draft for build
**Owner:** [Your name]
**Target build tool:** Antigravity (Flutter/Dart)

---

## 1. Overview

### 1.1 Problem
Sharing files and clipboard content between your own devices (phone, laptop, desktop) across different ecosystems (Android, iOS, macOS, Windows, Linux) currently requires either a cloud intermediary (Google Drive, email-to-self, Telegram "Saved Messages") or ecosystem lock-in (AirDrop only works Apple-to-Apple).

### 1.2 Solution
LocalDrop is a zero-cost, zero-cloud, cross-platform app that discovers nearby devices on the same local network and lets users send files and sync clipboard content directly between them over an encrypted peer-to-peer connection.

### 1.3 Goals
- Daily-use utility: replace "email it to myself" / cloud-upload-then-download habits.
- Zero infrastructure cost: no servers, no cloud storage, no subscriptions.
- Works across at least Android + Windows/macOS/Linux desktop for v1 (iOS support if time allows — see constraints).
- Transfers are encrypted by default.

### 1.4 Non-Goals (v1)
- Internet/WAN transfer (local network only, no relay/NAT traversal).
- System performance dashboard (CPU/thermal/battery monitoring) — deferred to v2.
- Multi-device group broadcast (v1 is one-to-one transfer; discovery can show multiple devices, but transfers are 1:1).
- User accounts, login, or any server-side component.

---

## 2. Target User & Use Cases

**Primary user:** the builder (you), someone who moves files/clipboard content between their own personal devices daily.

**Core use cases:**
1. Send a photo/video from phone to laptop without a cable or cloud upload.
2. Send a downloaded file from desktop to phone.
3. Copy text/a link on one device, paste it on another within seconds.
4. Send a file to a specific nearby device when multiple are visible (pick by device name).

---

## 3. Success Metrics (v1, informal since this is personal-use)

- A 500MB file transfers device-to-device in under the time it'd take to upload+download via cloud on the same network.
- Memory usage during a large transfer stays under ~50MB (per the chunked-streaming design).
- Zero crashes across 20 consecutive transfers of varying file sizes (1KB–2GB).
- Clipboard sync round-trip (copy on A, visible on B) completes in under 2 seconds on the same Wi-Fi network.

---

## 4. Functional Requirements

### 4.1 Device Discovery
- **FR-1:** On app launch, the device broadcasts its presence on the local network and shows a live list of other LocalDrop instances on the same network.
- **FR-2:** Each device displays a human-readable name (editable by user, defaults to OS device name) and device type icon (phone/desktop).
- **FR-3:** Discovery uses Bonjour/mDNS-style service advertisement (via the `nsd` or `multicast_dns` Dart package) rather than raw UDP multicast, for iOS/Android reliability.
- **FR-4:** Device list updates in real time as devices join/leave the network (device disappears from list ~5–10s after it stops broadcasting).

### 4.2 File Transfer
- **FR-5:** User can select a file (or multiple files) via OS file picker or platform share-sheet integration ("Share to LocalDrop").
- **FR-6:** User selects a target device from the discovered list to initiate a send.
- **FR-7:** Receiving device shows an incoming-transfer prompt (device name, file name, size) and the user must accept before the transfer begins.
- **FR-8:** Files are chunked (64KB chunks) and streamed over a TCP socket with backpressure so memory usage stays flat regardless of file size.
- **FR-9:** Transfer progress (bytes sent/received, %, speed, ETA) is shown on both sender and receiver in real time.
- **FR-10:** Post-transfer integrity check via SHA-256 checksum comparison; UI flags failed transfers and offers retry.
- **FR-11:** Received files are saved to a dedicated LocalDrop folder (with OS-appropriate default: `Downloads/LocalDrop` on desktop, app-scoped storage + "Save to Files/Gallery" prompt on mobile).
- **FR-12:** Transfer can be cancelled mid-way by either party; partial file is cleaned up.

### 4.3 Clipboard Sync
- **FR-13:** User can manually push current clipboard content to a selected nearby device ("Send Clipboard").
- **FR-14:** Receiving device gets a lightweight notification/toast and the content is copied into its local clipboard automatically.
- **FR-15:** Clipboard sync supports plain text and URLs in v1 (images/rich content deferred to v2).
- **FR-16:** Clipboard payloads go through the same encrypted socket channel as files (small message type, not full file transfer pipeline).

### 4.4 Security
- **FR-17:** On first connection between two devices, an ephemeral ECDH key exchange (via the `cryptography` Dart package) establishes a shared secret.
- **FR-18:** All socket payloads (file chunks and clipboard messages) are encrypted with AES-GCM using the derived shared secret.
- **FR-19:** No persistent device pairing/trust store required for v1 — each session negotiates a fresh key (simpler, acceptable for local-network-only trust model). Note as a v2 candidate: optional persistent trusted-device list to skip the accept-prompt for known devices.

### 4.5 Transfer History
- **FR-20:** Local SQLite (via `sqflite` or `Isar`) log of past transfers: filename, size, direction (sent/received), peer device name, timestamp, success/fail status.
- **FR-21:** User can view history, re-open received files from it, and clear history.

### 4.6 Settings
- **FR-22:** Editable local device name.
- **FR-23:** Default save location (desktop only; mobile uses OS-appropriate picker).
- **FR-24:** Toggle to require manual accept vs. auto-accept from trusted devices (v2 if trust store is deferred).

---

## 5. Non-Functional Requirements

| Category | Requirement |
|---|---|
| **Performance** | Streaming file I/O must not block the UI thread — use isolates for read/chunk/decrypt/write. Memory footprint stays flat (<50MB) regardless of file size. |
| **Reliability** | Backpressure-aware stream pipeline; socket writes must never outpace what the network/receiver can absorb. |
| **Portability** | Flutter codebase targeting Android, Windows, macOS, Linux for v1. iOS is a stretch target — see Constraints. |
| **Cost** | $0 runtime cost. No servers, no cloud storage, no third-party SaaS. Only cost is $99/yr Apple Developer if/when publishing to iOS App Store (not required for personal use/sideloading). |
| **Privacy** | No data leaves the local network. No analytics/telemetry calls to any external service. |
| **Offline-first** | Fully functional with no internet connection — local network only. |

---

## 6. Technical Architecture

### 6.1 Stack
- **Framework:** Flutter (Dart) — single codebase for mobile + desktop.
- **Networking:** `dart:io` raw `Socket`/`ServerSocket` (TCP) for transfer; `multicast_dns` or `nsd` package for discovery.
- **Concurrency:** Dart `Isolate`s for file chunking, encryption/decryption, and disk I/O — kept off the main UI isolate.
- **Crypto:** `cryptography` package — ECDH (X25519) key exchange + AES-GCM authenticated encryption.
- **Local storage:** `sqflite` or `Isar` for transfer history (Isar preferred for isolate-safe concurrent writes).
- **UI:** Standard Flutter widgets; `fl_chart` only needed if/when v2 dashboard is added — not required for v1.

### 6.2 High-Level Flow

**Discovery:**
```
App Start → Register mDNS service (_localdrop._tcp) → Browse for peers
→ Populate live device list → Refresh on service add/remove events
```

**File Transfer:**
```
Sender: pick file → select target device → open TCP socket
  → ECDH handshake → derive shared AES key
  → spawn isolate: read file in 64KB chunks → encrypt each chunk
  → write to socket with backpressure (await socket.flush / listen to buffer)
Receiver: accept incoming connection → show accept/reject prompt
  → on accept: spawn isolate: read chunks from socket → decrypt → write to disk
  → on completion: verify SHA-256 checksum → notify sender of success/fail
```

**Clipboard Sync:**
```
User taps "Send Clipboard" → read clipboard → open/reuse socket to target
→ encrypt small payload → send as a single framed message (not chunked)
→ receiver decrypts → writes to OS clipboard → shows toast
```

### 6.3 Protocol Framing (custom, over TCP)
Each message on the wire needs a minimal header so receiver knows how to interpret bytes:

```
[1 byte: message type] [4 bytes: payload length] [payload bytes]

Message types:
0x01 = HANDSHAKE_INIT (ECDH public key)
0x02 = HANDSHAKE_ACK
0x03 = TRANSFER_REQUEST (filename, size, checksum-to-come)
0x04 = TRANSFER_ACCEPT
0x05 = TRANSFER_REJECT
0x06 = FILE_CHUNK (encrypted chunk data)
0x07 = TRANSFER_COMPLETE (final checksum)
0x08 = CLIPBOARD_PUSH (encrypted text payload)
0x09 = ERROR
```

### 6.4 Data Model (local SQLite/Isar)

**TransferHistory**
| Field | Type |
|---|---|
| id | int (pk) |
| fileName | string |
| fileSizeBytes | int |
| direction | enum (sent/received) |
| peerDeviceName | string |
| peerAddress | string |
| timestamp | datetime |
| status | enum (success/failed/cancelled) |
| checksumVerified | bool |

**DeviceSettings** (key-value or single-row table)
| Field | Type |
|---|---|
| localDeviceName | string |
| defaultSaveDir | string (desktop only) |

---

## 7. Constraints & Known Risks

| Risk | Detail | Mitigation |
|---|---|---|
| **iOS local network restrictions** | iOS requires `NSLocalNetworkUsageDescription` + Bonjour service type declaration in Info.plist, and shows a system permission prompt. Some multicast behavior is sandboxed. | Use `nsd`/Bonjour-based discovery (not raw multicast). Treat iOS as stretch goal — build/test Android + desktop first. |
| **Background transfer suspension** | Both iOS and Android suspend network activity when the app backgrounds, which can kill in-progress transfers. | v1 constraint: app must stay foregrounded during transfer. Document this as a known limitation, not a bug. Background transfer support is a v2 investigation (platform-specific background task APIs). |
| **NAT/firewall on desktop OS** | Windows Firewall / macOS firewall may block inbound connections to the app on first run. | Show a one-time setup prompt guiding user to allow the app through firewall; document manual steps as fallback. |
| **Large file storage permissions (Android/iOS)** | Writing to shared storage requires scoped storage handling on modern Android, and file-provider setup on iOS. | Use `path_provider` + platform-appropriate save flows (`Downloads/LocalDrop` on Android via MediaStore API, share-sheet "Save to Files" on iOS). |
| **No relay = same-network only** | If two devices aren't on the same LAN/Wi-Fi, discovery and transfer won't work at all. | Explicitly a v1 non-goal. Document clearly in-app ("Works when both devices are on the same Wi-Fi network"). |

---

## 8. Build Phases (suggested order)

1. **Phase 1 — Discovery:** Get two devices to see each other on the network via mDNS. No transfer yet, just a live list.
2. **Phase 2 — Raw transfer (no encryption):** TCP socket connection, request/accept flow, chunked file transfer with progress UI. Validate backpressure and memory flatness with a large test file.
3. **Phase 3 — Crypto layer:** Add ECDH handshake + AES-GCM encryption on top of the working transfer pipeline.
4. **Phase 4 — Clipboard sync:** Reuse the socket/crypto layer for the lightweight clipboard message type.
5. **Phase 5 — History + settings + polish:** SQLite/Isar logging, settings screen, error states, retry/cancel UX.
6. **Phase 6 (stretch) — iOS support:** Info.plist permissions, Bonjour service declaration, background limitations testing.

---

## 9. Out of Scope for v1 (explicitly deferred)

- System performance/telemetry dashboard (CPU, thermals, battery) — the original concept's "impressive but not daily-use" feature. Candidate for a v2/portfolio-focused iteration once core app is stable and in daily use.
- Persistent trusted-device pairing (skip manual accept for known devices).
- Rich clipboard content (images, files via clipboard rather than explicit share).
- Group/broadcast send to multiple devices at once.
- Internet/WAN transfer via relay server (would reintroduce cost + infra — against the zero-cost goal).

---

## 10. Open Questions

- [ ] Desktop targets for v1: Windows + macOS + Linux, or just one to start?
- [ ] Preferred local storage engine: `sqflite` vs `Isar` (Isar has better isolate-safe concurrent write support, worth it given the isolate-heavy architecture)?
- [ ] Should the accept/reject prompt have a timeout (auto-reject after N seconds) to avoid hanging transfers?
