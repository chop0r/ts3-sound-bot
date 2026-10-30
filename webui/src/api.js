const BASE = '/api/v2'
const TOKEN_KEY = 'ab_token'

// Remove credentials persisted by older releases; do not migrate them silently.
localStorage.removeItem(TOKEN_KEY)
export function getToken() { return sessionStorage.getItem(TOKEN_KEY) || '' }
export function setToken(t) { sessionStorage.setItem(TOKEN_KEY, t) }
export function clearToken() {
  sessionStorage.removeItem(TOKEN_KEY)
  localStorage.removeItem(TOKEN_KEY)
}

export function clearCredentials() {
  clearToken()
}

// remembered access key (optional, localStorage of this browser): the token lives 8 hours and is lost when the bot restarts,
// so on a 401 the panel signs in again by itself
const SAVED_KEY = 'ab_saved_key'
export function getSavedKey() { try { return localStorage.getItem(SAVED_KEY) || '' } catch { return '' } }
export function setSavedKey(k) { try { localStorage.setItem(SAVED_KEY, k) } catch { /* without storage the key is simply not remembered */ } }
export function clearSavedKey() { try { localStorage.removeItem(SAVED_KEY) } catch { /* ignore */ } }

class AuthError extends Error {}

async function req(method, path, body, headers = {}, retried = false) {
  const opt = { method, headers: { ...headers } }
  const token = getToken()
  if (token) opt.headers['Authorization'] = 'Bearer ' + token
  if (body !== undefined) {
    opt.headers['Content-Type'] = 'application/json'
    opt.body = JSON.stringify(body)
  }
  const resp = await fetch(BASE + path, opt)
  if (resp.status === 401) {
    const saved = getSavedKey()
    if (saved && !retried && path !== '/auth/login') {
      try {
        const r = await req('POST', '/auth/login', { key: saved }, {}, true)
        setToken(r.token)
        return req(method, path, body, headers, true)
      } catch { clearSavedKey() }
    }
    if (getToken() === token) clearCredentials()
    throw new AuthError('auth required')
  }
  let data = null
  try { data = await resp.json() } catch { /* empty body */ }
  if (!resp.ok) {
    const msg = data?.error || data?.message || `HTTP ${resp.status}`
    throw new Error(msg)
  }
  return data
}

export const api = {
  AuthError,
  login: async (key) => {
    const r = await req('POST', '/auth/login', { key })
    setToken(r.token)
    return r
  },
  authState: () => req('GET', '/auth/state'),
  logout: async () => {
    const token = getToken()
    try { return await req('POST', '/auth/logout', {}) }
    finally { clearSavedKey(); if (getToken() === token) clearCredentials() }
  },

  status: () => req('GET', '/status'),
  tree: (bot) => req('GET', `/bot/${bot}/tree`),
  treeMove: (bot, channelId) => req('POST', `/bot/${bot}/tree/move`, { channelId }),
  serverInfo: (bot) => req('GET', `/bot/${bot}/serverinfo`),
  commands: () => req('GET', '/commands'),
  runCommand: (bot, line) => req('POST', `/bot/${bot}/cmd`, { line }),

  player: (bot) => req('GET', `/bot/${bot}/player`),
  play: (bot, url) => req('POST', `/bot/${bot}/play`, url ? { url } : {}),
  playNext: (bot, url) => req('POST', `/bot/${bot}/playnext`, { url }),
  pause: (bot, value) => req('POST', `/bot/${bot}/pause`, value === undefined ? {} : { value }),
  stop: (bot) => req('POST', `/bot/${bot}/stop`),
  next: (bot) => req('POST', `/bot/${bot}/next`),
  previous: (bot) => req('POST', `/bot/${bot}/previous`),
  volume: (bot, value) => req('POST', `/bot/${bot}/volume`, { value }),
  seek: (bot, seconds) => req('POST', `/bot/${bot}/seek`, { value: seconds }),

  queue: (bot) => req('GET', `/bot/${bot}/queue`),
  enqueue: (bot, payload) => req('POST', `/bot/${bot}/queue`, payload),
  clearQueue: (bot) => req('POST', `/bot/${bot}/queue/clear`),
  removeQueue: (bot, index) => req('DELETE', `/bot/${bot}/queue/${index}`),
  playQueueIndex: (bot, index) => req('POST', `/bot/${bot}/queue/${index}/play`),

  playlists: (bot) => req('GET', `/bot/${bot}/playlists`),
  playlist: (bot, id) => req('GET', `/bot/${bot}/playlists/${encodeURIComponent(id)}`),
  playPlaylist: (bot, id, opts = {}) => req('POST', `/bot/${bot}/playlists/${encodeURIComponent(id)}/play`, opts),
  deletePlaylist: (bot, id) => req('DELETE', `/bot/${bot}/playlists/${encodeURIComponent(id)}`),
  search: (bot, q) => req('GET', `/bot/${bot}/search?q=${encodeURIComponent(q)}`),
  createPlaylist: (bot, title) => req('POST', `/bot/${bot}/playlists`, { title }),
  renamePlaylist: (bot, id, title) => req('PUT', `/bot/${bot}/playlists/${encodeURIComponent(id)}`, { title }),
  addPlaylistItem: (bot, id, url) => req('POST', `/bot/${bot}/playlists/${encodeURIComponent(id)}/items`, { url }),
  removePlaylistItem: (bot, id, index) => req('DELETE', `/bot/${bot}/playlists/${encodeURIComponent(id)}/items/${index}`),
  movePlaylistItem: (bot, id, index, to) => req('POST', `/bot/${bot}/playlists/${encodeURIComponent(id)}/items/${index}/move`, { value: to }),

  bots: () => req('GET', '/bots'),
  createBot: (payload) => req('POST', '/bots/create', payload),
  connectBot: (nameOrId, payload = {}) => req('POST', `/bot/${nameOrId}/connect`, payload),
  disconnectBot: (nameOrId) => req('POST', `/bot/${nameOrId}/disconnect`),
  setTsName: (nameOrId, name) => req('POST', `/bot/${nameOrId}/tsname`, { name }),
  setChannel: (nameOrId, channel) => req('POST', `/bot/${nameOrId}/channel`, { channel }),
  setAutoRun: (nameOrId, autoRun) => req('POST', `/bot/${nameOrId}/autorun`, { autoRun }),
  deleteBot: (nameOrId) => req('DELETE', `/bot/${nameOrId}`),
}

// fetch-based SSE with Authorization header (EventSource cannot set headers)
export function connectEvents(onState, onAuthFail) {
  let closed = false
  let controller = null

  async function loop() {
    while (!closed) {
      controller = new AbortController()
      try {
        const token = getToken()
        const resp = await fetch(`${BASE}/events`, {
          headers: { Authorization: 'Bearer ' + token },
          signal: controller.signal,
        })
        if (resp.status === 401) {
          if (getToken() === token) { clearCredentials(); onAuthFail?.() }
          return
        }
        if (!resp.ok) throw new Error(`HTTP ${resp.status}`)
        const reader = resp.body.getReader()
        const decoder = new TextDecoder()
        let buf = ''
        while (true) {
          const { done, value } = await reader.read()
          if (done) break
          buf += decoder.decode(value, { stream: true })
          let idx
          while ((idx = buf.indexOf('\n\n')) >= 0) {
            const chunk = buf.slice(0, idx)
            buf = buf.slice(idx + 2)
            if (chunk.startsWith('data: ')) {
              try { onState(JSON.parse(chunk.slice(6))) } catch { /* ignore */ }
            }
          }
        }
      } catch { /* aborted or network error */ }
      if (!closed) await new Promise(r => setTimeout(r, 3000))
    }
  }
  loop()
  return () => { closed = true; controller?.abort() }
}
