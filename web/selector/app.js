/*
 * LoRo Scripts · loro_pettycrime_device/web/selector/app.js
 * © 2026 LoRo Scripts. All rights reserved.
 * Redistribution, resale, re-upload or modification without written
 * permission from LoRo Scripts is strictly prohibited.
 * يُمنع إعادة نشر أو بيع أو تعديل هذا السكربت بدون إذن من متجر LoRo Scripts.
 * Discord: https://discord.gg/sfHsAwZvDG
 */
document.addEventListener('alpine:init', () => {
  Alpine.data('selector', () => ({
    visible: false,
    modules: [],
    selectedIndex: 0,
    confirmed: false,

    init() {
      window.addEventListener('message', (e) => this.onMessage(e.data));
    },

    onMessage(data) {
      if (!data || !data.action) return;

      switch (data.action) {
        case 'show':
          this.modules = data.modules || [];
          this.selectedIndex = (data.selected || 1) - 1; // Lua 1-indexed → JS 0-indexed
          this.confirmed = false;
          this.visible = true;
          break;

        case 'select':
          this.confirmed = false;
          this.selectedIndex = (data.selected || 1) - 1;
          break;

        case 'confirm':
          this.selectedIndex = (data.selected || 1) - 1;
          this.confirmed = true;
          break;

        case 'hide':
          this.visible = false;
          break;
      }
    },
  }));
});
