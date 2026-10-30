<script setup>
import { onMounted, onUnmounted, ref, computed } from 'vue'
import { store, selectBot, switchTab, activeBotId, activeBotState, refreshStatus, showToast, bump } from './store.js'
import { api, connectEvents, getToken, clearCredentials, getSavedKey, clearSavedKey } from './api.js'
import { t } from './i18n.js'
import { APP_NAME } from './brand.js'
import Icon from './components/Icon.vue'
import PlayerBar from './components/PlayerBar.vue'
import LoginView from './components/LoginView.vue'
import HomeTab from './components/HomeTab.vue'
import PlaylistsTab from './components/PlaylistsTab.vue'
import BotsTab from './components/BotsTab.vue'
import SettingsTab from './components/SettingsTab.vue'

const tabs = [
  { id: 'home', icon: 'home', label: 'nav.home' },
  { id: 'playlists', icon: 'list', label: 'nav.playlists' },
  { id: 'instances', icon: 'server', label: 'nav.instances' },
]

const loggedIn = ref(!!getToken())
let closeEvents = null

function onEvent(data) {
  for (const b of data.bots || []) {
    store.botState[b.id] = { ...(store.botState[b.id] || {}), ...b.state }
  }
}

function onAuthFail() {
  clearCredentials()
  loggedIn.value = false
  closeEvents?.()
  closeEvents = null
  store.bots = []
  store.botState = {}
  store.activeBot = ''
}

async function logout() {
  // Capture and send the token before clearing this tab's sensitive state.
  const ending = api.logout()
  onAuthFail()
  try {
    await ending
    showToast(t('toast.loggedOut'))
  } catch {
    showToast(t('toast.logoutUnconfirmed'), 'error')
  }
}

function onLogin() {
  loggedIn.value = true
  start()
}

async function start() {
  await refreshStatus()
  closeEvents?.()
  closeEvents = connectEvents(onEvent, onAuthFail)
}

// keyboard shortcuts: space - pause, left/right - seek 10 s, up/down - volume, N/P - next/previous
async function onKey(e) {
  if (!loggedIn.value || e.ctrlKey || e.metaKey || e.altKey) return
  const el = document.activeElement
  if (el && (el.tagName === 'INPUT' || el.tagName === 'TEXTAREA' || el.tagName === 'SELECT' || el.isContentEditable)) return
  const id = activeBotId()
  const s = activeBotState()
  if (id < 0 || !s) return
  const k = e.key
  try {
    if (k === ' ') { e.preventDefault(); await (s.paused || !s.playing ? api.play(id) : api.pause(id, 1)) }
    else if (k === 'ArrowRight') { e.preventDefault(); await api.seek(id, Math.min(Math.floor((s.position || 0) + 10), Math.floor(s.length || 0))) }
    else if (k === 'ArrowLeft') { e.preventDefault(); await api.seek(id, Math.max(Math.floor((s.position || 0) - 10), 0)) }
    else if (k === 'ArrowUp') { e.preventDefault(); await api.volume(id, Math.min((s.volume ?? 0) + 5, 100)) }
    else if (k === 'ArrowDown') { e.preventDefault(); await api.volume(id, Math.max((s.volume ?? 0) - 5, 0)) }
    else if (k === 'n' || k === 'N') await api.next(id)
    else if (k === 'p' || k === 'P') await api.previous(id)
    else return
    bump()
  } catch (err) { showToast(err.message, 'error') }
}

onMounted(async () => {
  window.addEventListener('keydown', onKey)
  if (!loggedIn.value && getSavedKey()) {
    try { await api.login(getSavedKey()); loggedIn.value = true } catch { clearSavedKey() }
  }
  if (loggedIn.value) start()
})
onUnmounted(() => { closeEvents?.(); window.removeEventListener('keydown', onKey) })

const state = computed(() => activeBotState())
</script>

<template>
  <LoginView v-if="!loggedIn" @ok="onLogin" />

  <div v-else class="app">
    <header class="topbar">
      <div class="logo">
        <div class="logo-dot"><Icon name="music" :size="16" /></div>
        <span class="logo-text">{{ APP_NAME }}</span>
      </div>

      <nav class="tabs">
        <button v-for="tb in tabs" :key="tb.id" class="tab" :class="{ active: store.tab === tb.id }" @click="switchTab(tb.id)">
          <Icon :name="tb.icon" :size="19" />
          <span>{{ $t(tb.label) }}</span>
        </button>
      </nav>

      <div class="top-right">
        <select v-if="store.bots.length > 0" class="bot-select" :value="store.activeBot" :title="$t('nav.botInstance')"
          @change="selectBot($event.target.value)">
          <option v-for="b in store.bots" :key="b.name" :value="b.name">
            {{ b.tsName || b.name }}{{ b.running ? '' : ' (' + $t('state.offline') + ')' }}
          </option>
        </select>
        <button class="icon-btn" :class="{ on: store.tab === 'settings' }" :title="$t('nav.settings')" @click="switchTab('settings')">
          <Icon name="settings" :size="20" />
        </button>
        <button class="icon-btn" :title="$t('nav.logout')" @click="logout"><Icon name="logout" :size="19" /></button>
      </div>
    </header>

    <main class="content">
      <HomeTab v-show="store.tab === 'home'" />
      <PlaylistsTab v-show="store.tab === 'playlists'" />
      <BotsTab v-show="store.tab === 'instances'" />
      <SettingsTab v-show="store.tab === 'settings'" />
    </main>

    <PlayerBar v-if="state" />
  </div>
  <div v-if="store.toast" class="toast" :class="store.toast.kind">
    {{ store.toast.msg }}
  </div>
</template>
