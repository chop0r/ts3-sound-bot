import { reactive } from 'vue'
import { api } from './api.js'
import { t } from './i18n.js'

export const TABS = ['home', 'playlists', 'instances', 'settings']

function saved(key, fallback) {
  try { return localStorage.getItem(key) || fallback } catch { return fallback }
}

export const store = reactive({
  bots: [],
  activeBot: saved('ab_active_bot', ''),  // template name (stable key)
  botState: {},           // per running-bot-id live player state from SSE
  tab: TABS.includes(saved('tab', 'home')) ? saved('tab', 'home') : 'home',
  version: '',            // bot version from /status
  tick: 0,                // grows after player actions: the queue and other panels reload their data
  toast: null,
})

export function bump() { store.tick++ }

export function selectBot(name) {
  store.activeBot = name
  try { localStorage.setItem('ab_active_bot', name) } catch { /* ignore */ }
}

export function switchTab(id) {
  store.tab = id
  try { localStorage.setItem('tab', id) } catch { /* ignore */ }
}

let toastTimer = null
export function showToast(msg, kind = 'info') {
  store.toast = { msg, kind }
  clearTimeout(toastTimer)
  toastTimer = setTimeout(() => { store.toast = null }, 3200)
}

/// <summary>Numeric id of the RUNNING instance for the selected template, or -1.</summary>
export function activeBotId() {
  const sel = store.bots.find(b => b.name === store.activeBot)
  if (sel) return sel.running ? sel.runId : -1
  // nothing selected (or selection vanished): prefer a running instance
  const first = store.bots.find(b => b.running)
  return first ? first.runId : -1
}

export function activeBotState() {
  const id = activeBotId()
  return id >= 0 ? store.botState[id] : null
}

export async function refreshStatus() {
  try {
    // merge the on-disk bot templates with the running instances so the
    // selector lists every instance, not just the connected ones
    const [botList, status] = await Promise.all([api.bots(), api.status()])
    store.version = status.version || ''
    const runningByName = {}
    for (const b of status.bots || []) {
      runningByName[(b.Name ?? b.name ?? '').toLowerCase()] = b
    }
    store.bots = (botList.bots || []).map((b, i) => {
      const run = runningByName[(b.name || '').toLowerCase()]
      return {
        name: b.name,
        tsName: b.tsName,
        server: b.server,
        running: !!b.running,
        runId: run ? (run.Id ?? run.id ?? i) : -1,
      }
    })
    for (const b of status.bots || []) {
      const id = b.Id ?? b.id
      store.botState[id] = { ...store.botState[id], ...b, ...(b.state || {}) }
    }
    // keep the saved selection if it still exists, otherwise pick a running bot
    if (!store.bots.some(b => b.name === store.activeBot)) {
      const first = store.bots.find(b => b.running) || store.bots[0]
      selectBot(first ? first.name : '')
    }
  } catch (e) {
    if (!(e instanceof api.AuthError)) showToast(t('err.connect', { msg: e.message }), 'error')
  }
}

export function fmtTime(sec) {
  if (sec == null || isNaN(sec)) return '--:--'
  const s = Math.floor(sec % 60), m = Math.floor(sec / 60) % 60, h = Math.floor(sec / 3600)
  const mm = h ? String(m).padStart(2, '0') : m
  return (h ? h + ':' : '') + mm + ':' + String(s).padStart(2, '0')
}

/** a link, path or numeric id is added as is; anything else is treated as a search query */
export function isLink(v) {
  return /^(https?:\/\/|\/|[a-zA-Z]:[\\/]|\\\\|\d+$)/.test(v)
}
