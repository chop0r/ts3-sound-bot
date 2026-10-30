// Mock server for developing the panel without a real bot: node dev/mock-server.mjs, then npm run dev:mock. Login key: test.
// The data is made up; actions change the state in memory only.
import http from 'node:http'

const PORT = +process.env.PORT || 58914

const state = {
  playing: true, paused: false, position: 83, length: 214, volume: 42,
  current: { title: 'Sample Song', artist: 'Sample Artist', cover: null },
}
let queue = [
  { index: 0, title: 'Second Song', artist: 'Another Artist', duration: 187 },
  { index: 1, title: 'A very long track title that should be truncated nicely on narrow screens', artist: 'Some Band', duration: 251 },
  { index: 2, title: 'Third Song', artist: 'Third Artist', duration: 199 },
]
const playlists = [
  { id: 'list-1', title: 'Favorites', count: 12 },
  { id: 'list-2', title: 'Chill', count: 4 },
]
const tree = {
  channels: [
    { id: 1, parent: 0, order: 0, name: "Lobby" },
    { id: 2, parent: 0, order: 1, name: 'Music' },
    { id: 3, parent: 2, order: 0, name: 'Chill room' },
    { id: 4, parent: 0, order: 2, name: 'AFK' },
  ],
  clients: [
    { id: 10, name: 'Music bot', channel: 1, self: true, micMuted: false, spkMuted: false },
    { id: 11, name: 'Alice', channel: 1, self: false, micMuted: false, spkMuted: false },
    { id: 12, name: 'Bob', channel: 3, self: false, micMuted: true, spkMuted: false },
  ],
  selfChannel: 1,
}
const commands = [
  { name: 'play', description: 'Plays the song with the given link, or resumes a paused one.', overloads: [
    { parameters: [], usage: [], returns: 'Void' },
    { parameters: [{ name: 'link', type: 'String', optional: false }], usage: [{ syntax: '<link>', help: 'Plays the song from the link' }], returns: 'Void' }] },
  { name: 'pause', description: 'Pauses the playback.', overloads: [{ parameters: [], usage: [], returns: 'Void' }] },
  { name: 'volume', description: 'Sets or shows the volume.', overloads: [{ parameters: [{ name: 'volume', type: 'String', optional: true }], usage: [{ syntax: '[<0-100>]', help: 'Sets the volume' }], returns: 'String' }] },
  { name: 'list clear', description: 'Clears the playlist queue.', overloads: [{ parameters: [], usage: [], returns: 'Void' }] },
  { name: 'bot info', description: 'Shows information about the bot.', overloads: [{ parameters: [], usage: [], returns: 'JsonObject' }] },
  { name: 'bot name', description: 'Changes the nickname of the bot.', overloads: [{ parameters: [{ name: 'name', type: 'String', optional: false }], usage: [], returns: 'Void' }] },
  { name: 'help', description: 'Shows basic help.', overloads: [{ parameters: [], usage: [], returns: 'String' }] },
]

function send(res, code, body) {
  res.writeHead(code, { 'Content-Type': 'application/json' })
  res.end(JSON.stringify(body))
}

function readBody(req) {
  return new Promise(r => { let s = ''; req.on('data', c => (s += c)); req.on('end', () => { try { r(JSON.parse(s || '{}')) } catch { r({}) } }) })
}

setInterval(() => { if (state.playing && !state.paused) state.position = (state.position + 1) % state.length }, 1000)

http.createServer(async (req, res) => {
  const url = new URL(req.url, 'http://x')
  const p = url.pathname.replace(/^\/api\/v2/, '')
  const body = req.method === 'GET' ? {} : await readBody(req)

  if (p === '/auth/login') return body.key === 'test' ? send(res, 200, { token: 'mock-token' }) : send(res, 401, { error: 'bad key' })
  if (p === '/auth/state') return send(res, 200, { loggedIn: true })
  if (req.headers.authorization !== 'Bearer mock-token') return send(res, 401, { error: 'auth' })
  if (p === '/auth/logout') return send(res, 200, {})

  if (p === '/events') {
    res.writeHead(200, { 'Content-Type': 'text/event-stream', 'Cache-Control': 'no-cache' })
    const t = setInterval(() => res.write('data: ' + JSON.stringify({ bots: [{ id: 0, state }] }) + '\n\n'), 1000)
    req.on('close', () => clearInterval(t))
    return
  }
  if (p === '/status') return send(res, 200, { version: '0.0.0-mock', bots: [{ Id: 0, Name: 'music', Server: 'ts.example.com:9987', status: 'Connected', ...state }] })
  if (p === '/bots') return send(res, 200, { bots: [
    { name: 'music', tsName: 'Music bot', server: 'ts.example.com:9987', defaultChannel: 'Lobby', autoRun: true, running: true, channelName: 'Lobby' },
    { name: 'music2', tsName: 'Second bot', server: 'ts.example.com:9987', defaultChannel: '', autoRun: false, running: false },
  ] })
  if (p === '/bots/create') return send(res, 200, { created: true, name: body.name })
  if (p === '/commands') return send(res, 200, { commands })

  const m = p.match(/^\/bot\/([^/]+)(\/.*)?$/)
  if (m) {
    const sub = m[2] || ''
    if (sub === '/player') return send(res, 200, state)
    if (sub === '/pause') { state.paused = true; return send(res, 200, {}) }
    if (sub === '/play') { state.paused = false; state.playing = true; return send(res, 200, {}) }
    if (sub === '/stop') { state.playing = false; state.paused = true; return send(res, 200, {}) }
    if (sub === '/volume') { state.volume = body.value; return send(res, 200, {}) }
    if (sub === '/seek') { state.position = body.value; return send(res, 200, {}) }
    if (sub === '/queue' && req.method === 'GET') return send(res, 200, { title: 'Now Playing', items: queue })
    if (sub === '/queue/clear') { queue = []; return send(res, 200, { ok: true }) }
    if (sub === '/playlists') return send(res, 200, { playlists })
    if (/^\/playlists\/[^/]+$/.test(sub) && req.method === 'GET') return send(res, 200, { title: 'Favorites', count: 2, items: [{ title: 'Track A', artist: 'Artist', duration: 200 }, { title: 'Track B', artist: 'Artist', duration: 180 }] })
    if (sub.endsWith('/play')) return send(res, 200, { count: 3 })
    if (sub === '/tree') return send(res, 200, tree)
    if (sub === '/tree/move') { tree.selfChannel = body.channelId; tree.clients[0].channel = body.channelId; return send(res, 200, { ok: true }) }
    if (sub === '/serverinfo') return send(res, 200, { name: 'Mock Server', platform: 'Linux', version: '3.13.7', protocol: 7, created: '2024-01-01T00:00:00Z', maxClients: 32, virtualServerId: 1, welcome: 'Welcome!', ips: ['203.0.113.7'], clientsOnline: 3, channels: 4, botName: 'Music bot', botChannel: 1 })
    if (sub === '/cmd') return send(res, 200, { ok: !String(body.line).includes('bad'), result: 'Mock result for: ' + body.line, error: 'mock error' })
    return send(res, 200, { ok: true })
  }
  send(res, 404, { error: 'not found' })
}).listen(PORT, '127.0.0.1', () => console.log('mock bot on http://127.0.0.1:' + PORT + ', key: test'))
