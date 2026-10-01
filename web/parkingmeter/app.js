/*
 * LoRo Scripts · loro_pettycrime_device/web/parkingmeter/app.js
 * © 2026 LoRo Scripts. All rights reserved.
 * Redistribution, resale, re-upload or modification without written
 * permission from LoRo Scripts is strictly prohibited.
 * يُمنع إعادة نشر أو بيع أو تعديل هذا السكربت بدون إذن من متجر LoRo Scripts.
 * Discord: https://discord.gg/sfHsAwZvDG
 */
document.addEventListener('alpine:init', () => {
  Alpine.data('hackDevice', () => ({
    mode: 'boot',
    signalLevel: 0,
    distance: 0,
    hackProgress: 0,
    hackComplete: false,
    showCursor: true,
    frequency: '142.7 MHz',
    progressLabel: 'INJECTING',
    terminalLines: [],
    _freqInterval: null,
    _typeLinesTimer: null,
    sessionPid: '0x' + Math.floor(Math.random() * 0xFFFF).toString(16).padStart(4, '0'),

    // Boot state
    bootLines: [],
    bootProgress: 0,
    bootStatus: 'Initializing...',

    // Result state
    resultSuccess: false,
    resultReason: null,
    hackFailed: false,

    // Radar bearing in degrees (0 = ahead/north on radar, CW)
    _blipBearing: 0,
    // Multiple blips array — each { bearing, level, distance }
    _blips: [],
    // Sweep state — driven by updateSignal messages
    _sweepAngle: 0,
    _sweepAnim: null,
    _sweepDuration: 500, // default, updated from Lua signalInterval

    get signalLabel() {
      if (this.signalLevel === 0) return 'NO TARGET';
      if (this.signalLevel <= 2) return 'FAINT';
      if (this.signalLevel <= 4) return 'DETECTED';
      if (this.signalLevel <= 6) return 'TRACKING';
      return 'LOCKED ON';
    },

    get distanceText() {
      return this.distance > 0 ? this.distance.toFixed(1) + 'm' : '---';
    },

    get blipPosition() {
      if (this.signalLevel === 0) return { display: 'none' };
      // Map signal 1-8 to distance from center (85% -> 15% of radar radius)
      const pct = 0.85 - ((this.signalLevel - 1) / 7) * 0.70;
      // Convert bearing (degrees, 0=up/north, CW) to canvas angle
      // Canvas: 0 rad = right, so rotate -90° and negate for CW
      const rad = (this._blipBearing - 90) * (Math.PI / 180);
      const x = 50 + Math.cos(rad) * pct * 50;
      const y = 50 + Math.sin(rad) * pct * 50;
      return { left: x + '%', top: y + '%' };
    },

    get blipPositions() {
      const positions = [];
      // If we have nearby blips data, use that (includes the nearest as first entry)
      if (this._blips.length > 0) {
        for (let i = 0; i < this._blips.length; i++) {
          const b = this._blips[i];
          const pct = 0.85 - ((b.level - 1) / 7) * 0.70;
          const rad = (b.bearing - 90) * (Math.PI / 180);
          const x = 50 + Math.cos(rad) * pct * 50;
          const y = 50 + Math.sin(rad) * pct * 50;
          positions.push({ left: x + '%', top: y + '%', primary: i === 0, looted: !!b.looted });
        }
      } else if (this.signalLevel > 0) {
        // Fallback: single blip from primary bearing
        const pct = 0.85 - ((this.signalLevel - 1) / 7) * 0.70;
        const rad = (this._blipBearing - 90) * (Math.PI / 180);
        const x = 50 + Math.cos(rad) * pct * 50;
        const y = 50 + Math.sin(rad) * pct * 50;
        positions.push({ left: x + '%', top: y + '%', primary: true, looted: false });
      }
      return positions;
    },

    triggerSweep() {
      if (this._sweepAnim) return; // already running

      let lastTime = performance.now();

      const animate = (now) => {
        const dt = now - lastTime;
        lastTime = now;

        // degrees per ms based on current sweep duration
        const speed = 360 / (this._sweepDuration || 500);
        this._sweepAngle = (this._sweepAngle + dt * speed) % 360;

        const angle = this._sweepAngle;
        const sweepLine = this.$refs.sweepLine;
        const sweepTrail = this.$refs.sweepTrail;
        if (sweepLine) sweepLine.style.transform = `rotate(${angle}deg)`;
        if (sweepTrail) sweepTrail.style.transform = `rotate(${angle}deg)`;

        // Flash blips when sweep crosses their bearing angle
        if (this.signalLevel > 0) {
          const blipEls = this.$refs.radarContainer?.querySelectorAll('.radar-blip');
          if (blipEls) {
            const blips = this._blips.length > 0 ? this._blips : [{ bearing: this._blipBearing }];
            blipEls.forEach((el, i) => {
              if (!blips[i]) return;
              const sweepNorm = ((angle - 90) % 360 + 360) % 360;
              const bearingNorm = ((blips[i].bearing) % 360 + 360) % 360;
              const diff = Math.abs(sweepNorm - bearingNorm);
              if (diff < 15 || diff > 345) {
                if (!el.classList.contains('ping')) {
                  el.classList.add('ping');
                  setTimeout(() => el?.classList.remove('ping'), 400);
                }
              }
            });
          }
        }

        this._sweepAnim = requestAnimationFrame(animate);
      };

      this._sweepAnim = requestAnimationFrame(animate);
    },

    stopSweep() {
      if (this._sweepAnim) {
        cancelAnimationFrame(this._sweepAnim);
        this._sweepAnim = null;
      }
    },

    runBootSequence() {
      if (this._bootRunning) return;
      this._bootRunning = true;
      this.mode = 'boot';
      this.bootLines = [];
      this.bootProgress = 0;
      this.bootStatus = 'Initializing...';

      const lines = [
        '[SYS] Kernel 4.19.2-ds loaded',
        '[HW]  RF module............. OK',
        '[HW]  NFC interface......... OK',
        '[HW]  BLE 5.0 stack........ OK',
        '[NET] Mesh network init.... OK',
        '[DB]  Loading meter sigs... OK',
        '[DB]  Firmware db: 847 entries',
        '[EXP] Payload checksums.... VALID',
        '[SIG] Antenna calibrated',
        '[OK]  DigiScanner ready',
      ];

      let i = 0;
      const step = () => {
        if (i >= lines.length) {
          this.bootStatus = 'Online';
          this.bootProgress = 100;
          setTimeout(() => {
            this._bootRunning = false;
            this.mode = 'signal';
            this.startFrequencyFlicker();
          }, 600);
          return;
        }
        this.bootLines.push(lines[i]);
        this.bootProgress = ((i + 1) / lines.length) * 100;
        this.bootStatus = i < lines.length - 1 ? 'Loading...' : 'Finalizing...';
        i++;
        setTimeout(step, 250 + Math.random() * 300);
      };
      setTimeout(step, 400);
    },

    startFrequencyFlicker() {
      this.stopFrequencyFlicker();
      this._freqInterval = setInterval(() => {
        this.frequency = (433.0 + Math.random() * 1.5).toFixed(1) + ' MHz';
      }, 900);
    },

    stopFrequencyFlicker() {
      if (this._freqInterval) {
        clearInterval(this._freqInterval);
        this._freqInterval = null;
      }
    },

    resetTerminal() {
      this.stopTypeLines();
      this.terminalLines = [];
      this.hackProgress = 0;
      this.hackComplete = false;
      this.hackFailed = false;
      this.resultReason = null;
      this.progressLabel = 'INJECTING';
      this.showCursor = true;
      this.sessionPid = '0x' + Math.floor(Math.random() * 0xFFFF).toString(16).padStart(4, '0');
    },

    addLine(text, type) {
      this.terminalLines.push({ text, type: type || 'info' });
      this.$nextTick(() => {
        const el = this.$refs.terminalOutput;
        if (el) el.scrollTop = el.scrollHeight;
      });
    },

    typeLines(lines, duration) {
      this.stopTypeLines();
      const interval = duration / lines.length;
      let index = 0;
      this._typeLinesTimer = setInterval(() => {
        if (index >= lines.length) {
          this.stopTypeLines();
          return;
        }
        this.addLine(lines[index].text, lines[index].type);
        this.hackProgress = ((index + 1) / lines.length) * 100;
        index++;
      }, interval);
    },

    stopTypeLines() {
      if (this._typeLinesTimer) {
        clearInterval(this._typeLinesTimer);
        this._typeLinesTimer = null;
      }
    },

    showResult(success) {
      this.resultSuccess = success;
      this.mode = 'result';
      setTimeout(() => {
        this.mode = 'signal';
        this.resetTerminal();
        this.startFrequencyFlicker();
      }, 3000);
    },

    init() {
      window.addEventListener('message', (e) => {
        let data = e.data;
        if (typeof data === 'string') {
          try { data = JSON.parse(data); } catch { return; }
        }
        if (!data || !data.action) return;

        switch (data.action) {
          case 'show':
            if (data.mode === 'boot') {
              this.runBootSequence();
            } else {
              this.mode = data.mode || 'signal';
              if (data.mode === 'signal') this.startFrequencyFlicker();
            }
            break;

          case 'hide':
            this._bootRunning = false;
            this.mode = 'boot';
            this.signalLevel = 0;
            this.distance = 0;
            this._blips = [];
            this.resetTerminal();
            this.stopFrequencyFlicker();
            this.stopSweep();
            break;

          case 'updateSignal':
            this.signalLevel = Math.max(0, Math.min(8, data.level || 0));
            this.distance = data.distance || 0;
            // Bearing from Lua: 0 = directly ahead, CW in degrees
            if (data.bearing !== undefined) {
              this._blipBearing = data.bearing;
            }
            // Nearby blips array from Lua (when sendNearbyToUI is enabled)
            if (data.nearbyBlips && data.nearbyBlips.length > 0) {
              this._blips = data.nearbyBlips;
            } else {
              this._blips = [];
            }
            if (data.interval) this._sweepDuration = data.interval;
            if (this.mode === 'signal') this.triggerSweep();
            break;

          case 'startHack':
            this.mode = 'terminal';
            this.resetTerminal();
            this.stopFrequencyFlicker();
            this.stopSweep();
            if (data.lines && data.lines.length > 0) {
              this.typeLines(data.lines, data.duration || 10000);
            }
            break;

          case 'hackResult':
            this.stopTypeLines();
            this.hackComplete = true;
            this.showCursor = false;
            if (data.success) {
              this.hackFailed = false;
              this.hackProgress = 100;
              this.progressLabel = 'CRACKED';
              this.addLine('[+] DEVICE COMPROMISED', 'success');
              this.addLine('[+] Exploit payload delivered.', 'success');
            } else {
              this.hackFailed = true;
              if (data.reason === 'already_looted') {
                this.progressLabel = 'BREACHED';
                this.addLine('', 'warning');
                this.addLine('[!] DEVICE ALREADY BREACHED', 'warning');
                this.addLine('[!] Unit was previously compromised.', 'warning');
                this.addLine('[!] No accessible data streams found.', 'warning');
              } else if (data.reason === 'no_loot') {
                this.progressLabel = 'EMPTY';
                this.hackProgress = 100;
                this.addLine('', 'warning');
                this.addLine('[!] BREACH SUCCESSFUL', 'warning');
                this.addLine('[!] Coin vault is empty.', 'warning');
                this.addLine('[!] Nothing left to recover.', 'warning');
              } else if (data.reason === 'cooldown' || data.reason === 'already_hacking') {
                this.progressLabel = 'BUSY';
                this.addLine('', 'warning');
                this.addLine('[!] DEVICE OVERHEATED', 'warning');
                this.addLine('[!] Wait for the cracker to cool down.', 'warning');
              } else if (data.reason === 'moved_too_far' || data.reason === 'too_far') {
                this.progressLabel = 'ABORTED';
                this.addLine('', 'error');
                this.addLine('[!] SIGNAL LOST', 'error');
                this.addLine('[!] Target out of range. Session killed.', 'error');
              } else {
                this.progressLabel = 'ABORTED';
                this.addLine('', 'error');
                this.addLine('[!] SESSION KILLED', 'error');
                this.addLine('[!] CODE: ' + (data.reason || 'unknown'), 'error');
              }
            }
            this.resultReason = data.reason || null;
            setTimeout(() => this.showResult(!!data.success), 1500);
            break;
        }
      });
    }
  }));
});
