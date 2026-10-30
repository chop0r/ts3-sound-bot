<script setup>
import { ref } from 'vue'
import { api, setSavedKey } from '../api.js'
import { t } from '../i18n.js'
import { APP_NAME } from '../brand.js'
import Icon from './Icon.vue'
import LangSwitch from './LangSwitch.vue'

const emit = defineEmits(['ok'])
const key = ref('')
const busy = ref(false)
const remember = ref(true)
const error = ref('')

async function doLogin() {
  if (!key.value.trim() || busy.value) return
  busy.value = true
  error.value = ''
  try {
    await api.login(key.value.trim())
    if (remember.value) setSavedKey(key.value.trim())
    key.value = ''
    emit('ok')
  } catch (e) {
    error.value = e.message === 'auth required' ? t('login.wrongKey') : e.message
  }
  busy.value = false
}
</script>

<template>
  <div class="login-mask">
    <div class="login-card">
      <div class="logo" style="justify-content: center; margin-bottom: 6px">
        <div class="logo-dot"><Icon name="music" :size="16" /></div>
      </div>
      <div class="login-title">{{ APP_NAME }}</div>
      <div class="login-sub">{{ $t('login.prompt') }}</div>
      <input
        v-model="key"
        type="password"
        autocomplete="off"
        :placeholder="$t('login.key')"
        autofocus
        @keydown.enter="doLogin"
      />
      <label style="display: flex; gap: 8px; align-items: center; font-size: 13px; color: var(--text-dim); cursor: pointer">
        <input v-model="remember" type="checkbox" style="width: auto" /> {{ $t('login.remember') }}
      </label>
      <button class="btn primary" style="justify-content: center" :disabled="busy || !key.trim()" @click="doLogin">
        <span v-if="busy" class="spin"></span>
        <template v-else>{{ $t('login.submit') }}</template>
      </button>
      <div v-if="error" class="login-error">{{ error }}</div>
      <div style="display: flex; justify-content: center"><LangSwitch /></div>
    </div>
  </div>
</template>

<style scoped>
.login-mask {
  position: fixed; inset: 0;
  background: var(--bg);
  z-index: 200;
  display: flex; align-items: center; justify-content: center;
}
.login-card {
  width: min(360px, 90vw);
  background: var(--card);
  border: 1px solid var(--border);
  border-radius: 18px;
  padding: 34px 30px;
  display: flex; flex-direction: column; gap: 13px;
  box-shadow: var(--shadow);
}
.login-title { text-align: center; font-size: 19px; font-weight: 700; }
.login-sub { text-align: center; color: var(--text-dim); font-size: 13px; margin-bottom: 8px; }
.login-error { color: var(--accent2); font-size: 13px; text-align: center; }
</style>
