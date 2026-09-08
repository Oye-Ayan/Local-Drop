class WebPortalHtml {
  /// Generates the self-contained, responsive Obsidian Dark Web Portal HTML.
  /// Zero external CDN or internet dependencies — 100% offline.
  static String build({
    required String deviceName,
    required String pin,
    required String token,
  }) {
    return '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <title>LocalDrop • $deviceName</title>
  <style>
    :root {
      --bg-dark: #0B0E14;
      --card-bg: #131823;
      --card-elevated: #182030;
      --border-color: #232D42;
      --primary: #10B981;
      --primary-light: #34D399;
      --primary-glow: rgba(16, 185, 129, 0.18);
      --accent: #06B6D4;
      --text-primary: #F3F4F6;
      --text-secondary: #94A3B8;
      --text-muted: #64748B;
      --danger: #EF4444;
      --radius: 16px;
    }
    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
      -webkit-tap-highlight-color: transparent;
    }
    body {
      background-color: var(--bg-dark);
      color: var(--text-primary);
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      align-items: center;
      padding: 20px 16px 40px;
    }
    .container {
      width: 100%;
      max-width: 580px;
      display: flex;
      flex-direction: column;
      gap: 20px;
    }
    .header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 12px 16px;
      background: var(--card-bg);
      border: 1px solid var(--border-color);
      border-radius: var(--radius);
    }
    .logo-group {
      display: flex;
      align-items: center;
      gap: 12px;
    }
    .logo-badge {
      width: 38px;
      height: 38px;
      background: linear-gradient(135deg, var(--primary), var(--accent));
      border-radius: 10px;
      display: flex;
      align-items: center;
      justify-content: center;
      font-weight: 900;
      font-size: 18px;
      color: #0B0E14;
      box-shadow: 0 4px 12px var(--primary-glow);
    }
    .header-title {
      font-size: 16px;
      font-weight: 700;
      letter-spacing: -0.3px;
    }
    .header-subtitle {
      font-size: 12px;
      color: var(--text-secondary);
    }
    .status-pill {
      display: flex;
      align-items: center;
      gap: 6px;
      font-size: 11px;
      font-weight: 600;
      padding: 6px 10px;
      border-radius: 20px;
      background: rgba(16, 185, 129, 0.12);
      color: var(--primary-light);
      border: 1px solid rgba(16, 185, 129, 0.3);
    }
    .status-dot {
      width: 6px;
      height: 6px;
      border-radius: 50%;
      background: var(--primary);
      box-shadow: 0 0 8px var(--primary);
    }
    .card {
      background: var(--card-bg);
      border: 1px solid var(--border-color);
      border-radius: var(--radius);
      padding: 20px;
      display: flex;
      flex-direction: column;
      gap: 14px;
    }
    .card-title {
      font-size: 15px;
      font-weight: 700;
      display: flex;
      align-items: center;
      justify-content: space-between;
    }
    .badge-count {
      background: var(--card-elevated);
      color: var(--primary-light);
      border: 1px solid var(--border-color);
      font-size: 11px;
      font-weight: 700;
      padding: 2px 8px;
      border-radius: 12px;
    }
    .file-item {
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 12px 14px;
      background: var(--card-elevated);
      border: 1px solid var(--border-color);
      border-radius: 12px;
      gap: 12px;
      transition: border-color 0.2s;
    }
    .file-item:hover {
      border-color: rgba(16, 185, 129, 0.4);
    }
    .file-info {
      display: flex;
      flex-direction: column;
      gap: 3px;
      overflow: hidden;
      flex: 1;
    }
    .file-name {
      font-size: 13.5px;
      font-weight: 600;
      color: var(--text-primary);
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }
    .file-meta {
      font-size: 11.5px;
      color: var(--text-muted);
    }
    .btn {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      gap: 6px;
      padding: 9px 16px;
      font-size: 13px;
      font-weight: 600;
      border-radius: 10px;
      border: none;
      cursor: pointer;
      text-decoration: none;
      transition: all 0.2s;
    }
    .btn-primary {
      background: var(--primary);
      color: #0B0E14;
      font-weight: 700;
    }
    .btn-primary:hover {
      background: var(--primary-light);
      box-shadow: 0 4px 14px var(--primary-glow);
    }
    .btn-secondary {
      background: var(--card-elevated);
      color: var(--text-primary);
      border: 1px solid var(--border-color);
    }
    .btn-secondary:hover {
      background: #202b40;
      border-color: #3b4968;
    }
    .dropzone {
      border: 2px dashed var(--border-color);
      background: var(--card-elevated);
      border-radius: 14px;
      padding: 28px 16px;
      text-align: center;
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 10px;
      cursor: pointer;
      transition: all 0.2s;
    }
    .dropzone.dragover {
      border-color: var(--primary);
      background: rgba(16, 185, 129, 0.08);
      box-shadow: 0 0 16px var(--primary-glow);
    }
    .dropzone-icon {
      width: 44px;
      height: 44px;
      border-radius: 12px;
      background: rgba(16, 185, 129, 0.12);
      color: var(--primary-light);
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 22px;
    }
    .dropzone-title {
      font-size: 14px;
      font-weight: 600;
      color: var(--text-primary);
    }
    .dropzone-hint {
      font-size: 12px;
      color: var(--text-muted);
    }
    .progress-box {
      display: none;
      flex-direction: column;
      gap: 8px;
      padding: 12px 14px;
      background: var(--card-elevated);
      border: 1px solid var(--border-color);
      border-radius: 12px;
    }
    .progress-bar-bg {
      height: 8px;
      background: var(--card-bg);
      border-radius: 6px;
      overflow: hidden;
      position: relative;
    }
    .progress-bar-fill {
      height: 100%;
      width: 0%;
      background: linear-gradient(90deg, var(--primary), var(--accent));
      transition: width 0.2s ease;
    }
    .progress-status {
      display: flex;
      justify-content: space-between;
      font-size: 12px;
      color: var(--text-secondary);
    }
    /* Auth Modal / Gate */
    #auth-screen {
      display: none;
      text-align: center;
      padding: 30px 20px;
    }
    .pin-input {
      font-size: 28px;
      letter-spacing: 12px;
      text-align: center;
      background: var(--card-elevated);
      border: 2px solid var(--border-color);
      color: var(--text-primary);
      padding: 12px;
      border-radius: 12px;
      width: 180px;
      margin: 16px auto;
      outline: none;
    }
    .pin-input:focus {
      border-color: var(--primary);
    }
    .notice {
      font-size: 11.5px;
      color: var(--text-muted);
      text-align: center;
      margin-top: 10px;
    }
  </style>
</head>
<body>
  <div class="container">
    <!-- Header -->
    <div class="header">
      <div class="logo-group">
        <div class="logo-badge">⚡</div>
        <div>
          <div class="header-title">LocalDrop Portal</div>
          <div class="header-subtitle">Host: $deviceName</div>
        </div>
      </div>
      <div class="status-pill">
        <span class="status-dot"></span>
        Direct P2P
      </div>
    </div>

    <!-- Auth PIN Gate (shown if session token is missing) -->
    <div id="auth-screen" class="card">
      <div class="dropzone-icon" style="margin: 0 auto;">🔒</div>
      <h2 style="font-size: 18px; margin-top: 8px;">Security Verification</h2>
      <p style="font-size: 13px; color: var(--text-secondary);">Enter the 4-digit PIN displayed on the host screen to access this session.</p>
      <input id="pin-entry" type="password" maxlength="4" class="pin-input" placeholder="••••" autofocus />
      <button onclick="verifyPin()" class="btn btn-primary" style="width: 180px; margin: 0 auto;">Unlock Session</button>
      <p id="pin-error" style="color: var(--danger); font-size: 12px; display: none; margin-top: 8px;">Incorrect PIN. Please try again.</p>
    </div>

    <!-- Main Content (shown after auth) -->
    <div id="main-content" style="display: flex; flex-direction: column; gap: 20px;">
      <!-- Shared Files from Host (Download) -->
      <div class="card">
        <div class="card-title">
          <span>Files Ready for Download</span>
          <span id="files-count" class="badge-count">0</span>
        </div>
        <div id="files-list" style="display: flex; flex-direction: column; gap: 10px;">
          <!-- Dynamically populated -->
        </div>
      </div>

      <!-- Upload to Host Dropzone -->
      <div class="card">
        <div class="card-title">
          <span>Send Files to Host ($deviceName)</span>
          <span class="badge-count">Upload</span>
        </div>
        <input type="file" id="file-input" multiple style="display: none;" onchange="handleFileSelect(event)" />
        <div class="dropzone" id="dropzone" onclick="document.getElementById('file-input').click()">
          <div class="dropzone-icon">📥</div>
          <div class="dropzone-title">Click to browse or drop files here</div>
          <div class="dropzone-hint">Uploads directly to host's LocalDrop Downloads folder</div>
        </div>
        <div class="progress-box" id="upload-progress-box">
          <div class="progress-status">
            <span id="upload-filename">Uploading...</span>
            <span id="upload-percent">0%</span>
          </div>
          <div class="progress-bar-bg">
            <div class="progress-bar-fill" id="upload-bar"></div>
          </div>
          <div id="upload-speed" style="font-size: 11px; color: var(--text-muted); text-align: right;"></div>
        </div>
      </div>

      <!-- Text / Clipboard Drop -->
      <div class="card">
        <div class="card-title">
          <span>Quick Note / Link Drop</span>
        </div>
        <textarea id="note-input" rows="2" placeholder="Type or paste a link/text to drop onto host..." style="width: 100%; background: var(--card-elevated); border: 1px solid var(--border-color); border-radius: 10px; color: var(--text-primary); padding: 10px; font-size: 13px; outline: none; resize: vertical;"></textarea>
        <div style="display: flex; justify-content: flex-end;">
          <button onclick="sendNote()" class="btn btn-secondary">Drop Text to Host</button>
        </div>
      </div>

      <p class="notice">🔒 100% Local Network Transfer • No Cloud • End-to-End Private</p>
    </div>
  </div>

  <script>
    // Embedded Token & PIN from Host
    const EMBEDDED_TOKEN = "$token";
    const EXPECTED_PIN = "$pin";

    // URL token handling
    const urlParams = new URLSearchParams(window.location.search);
    let activeToken = urlParams.get('token') || sessionStorage.getItem('localdrop_token');

    function checkAuth() {
      if (activeToken === EMBEDDED_TOKEN) {
        sessionStorage.setItem('localdrop_token', activeToken);
        document.getElementById('auth-screen').style.display = 'none';
        document.getElementById('main-content').style.display = 'flex';
        loadStatus();
      } else {
        document.getElementById('auth-screen').style.display = 'block';
        document.getElementById('main-content').style.display = 'none';
      }
    }

    async function verifyPin() {
      const entered = document.getElementById('pin-entry').value.trim();
      if (entered === EXPECTED_PIN) {
        activeToken = EMBEDDED_TOKEN;
        sessionStorage.setItem('localdrop_token', activeToken);
        document.getElementById('pin-error').style.display = 'none';
        checkAuth();
      } else {
        document.getElementById('pin-error').style.display = 'block';
        document.getElementById('pin-entry').value = '';
      }
    }

    // Load file list from host
    async function loadStatus() {
      try {
        const res = await fetch('/api/status?token=' + encodeURIComponent(activeToken));
        if (!res.ok) {
          if (res.status === 403) {
            sessionStorage.removeItem('localdrop_token');
            activeToken = null;
            checkAuth();
          }
          return;
        }
        const data = await res.json();
        renderFiles(data.files || []);
      } catch (err) {
        console.error('Failed to load status:', err);
      }
    }

    function renderFiles(files) {
      const listEl = document.getElementById('files-list');
      const countEl = document.getElementById('files-count');
      countEl.textContent = files.length;

      if (files.length === 0) {
        listEl.innerHTML = '<div style="color: var(--text-muted); font-size: 13px; text-align: center; padding: 12px;">Host has not queued any download files yet.</div>';
        return;
      }

      listEl.innerHTML = files.map(file => `
        <div class="file-item">
          <div class="file-info">
            <span class="file-name" title="\${escapeHtml(file.name)}">\${escapeHtml(file.name)}</span>
            <span class="file-meta">\${formatBytes(file.sizeBytes)}</span>
          </div>
          <a href="/api/download?id=\${encodeURIComponent(file.id)}&token=\${encodeURIComponent(activeToken)}" download="\${escapeHtml(file.name)}" class="btn btn-primary">
            Download
          </a>
        </div>
      `).join('');
    }

    function escapeHtml(str) {
      return String(str).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
    }

    function formatBytes(bytes) {
      if (bytes < 1024) return bytes + ' B';
      if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB';
      if (bytes < 1024 * 1024 * 1024) return (bytes / (1024 * 1024)).toFixed(1) + ' MB';
      return (bytes / (1024 * 1024 * 1024)).toFixed(2) + ' GB';
    }

    // Drag and Drop
    const dropzone = document.getElementById('dropzone');
    ['dragenter', 'dragover'].forEach(name => {
      dropzone.addEventListener(name, (e) => { e.preventDefault(); dropzone.classList.add('dragover'); }, false);
    });
    ['dragleave', 'drop'].forEach(name => {
      dropzone.addEventListener(name, (e) => { e.preventDefault(); dropzone.classList.remove('dragover'); }, false);
    });
    dropzone.addEventListener('drop', (e) => {
      const files = e.dataTransfer.files;
      if (files && files.length > 0) uploadFiles(files);
    });

    function handleFileSelect(e) {
      const files = e.target.files;
      if (files && files.length > 0) uploadFiles(files);
    }

    async function uploadFiles(files) {
      const progressBox = document.getElementById('upload-progress-box');
      const filenameEl = document.getElementById('upload-filename');
      const percentEl = document.getElementById('upload-percent');
      const barEl = document.getElementById('upload-bar');
      const speedEl = document.getElementById('upload-speed');
      progressBox.style.display = 'flex';

      for (let i = 0; i < files.length; i++) {
        const file = files[i];
        filenameEl.textContent = 'Uploading: ' + file.name + ' (' + (i + 1) + '/' + files.length + ')';
        percentEl.textContent = '0%';
        barEl.style.width = '0%';

        await new Promise((resolve, reject) => {
          const xhr = new XMLHttpRequest();
          const startTime = Date.now();
          xhr.open('POST', '/api/upload?name=' + encodeURIComponent(file.name) + '&token=' + encodeURIComponent(activeToken));
          xhr.setRequestHeader('X-LocalDrop-Token', activeToken);

          xhr.upload.onprogress = (e) => {
            if (e.lengthComputable) {
              const pct = Math.round((e.loaded / e.total) * 100);
              percentEl.textContent = pct + '%';
              barEl.style.width = pct + '%';
              const elapsedSec = (Date.now() - startTime) / 1000;
              if (elapsedSec > 0.3) {
                const mbps = ((e.loaded / (1024 * 1024)) / elapsedSec).toFixed(1);
                speedEl.textContent = mbps + ' MB/s';
              }
            }
          };

          xhr.onload = () => {
            if (xhr.status >= 200 && xhr.status < 300) {
              resolve();
            } else {
              alert('Upload failed: ' + xhr.responseText);
              reject(new Error(xhr.responseText));
            }
          };
          xhr.onerror = () => reject(new Error('Network error during upload'));
          xhr.send(file);
        });
      }

      filenameEl.textContent = '✓ All files uploaded successfully to host!';
      percentEl.textContent = '100%';
      barEl.style.width = '100%';
      speedEl.textContent = '';
      setTimeout(() => { progressBox.style.display = 'none'; }, 3000);
      document.getElementById('file-input').value = '';
    }

    async function sendNote() {
      const noteInput = document.getElementById('note-input');
      const text = noteInput.value.trim();
      if (!text) return;

      try {
        const res = await fetch('/api/note?token=' + encodeURIComponent(activeToken), {
          method: 'POST',
          headers: {
            'Content-Type': 'text/plain; charset=utf-8',
            'X-LocalDrop-Token': activeToken
          },
          body: text
        });
        if (res.ok) {
          noteInput.value = '';
          alert('✓ Note sent to host device!');
        } else {
          alert('Failed to send note: ' + res.statusText);
        }
      } catch (err) {
        alert('Error sending note: ' + err.message);
      }
    }

    // Initial auth check
    checkAuth();
  </script>
</body>
</html>''';
  }
}
