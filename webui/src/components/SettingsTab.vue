<script setup>
import { computed, ref, watch, onMounted } from 'vue'
import { store, activeBotId, showToast, bump } from '../store.js'
import { api } from '../api.js'
import { t, lang, messages } from '../i18n.js'
import Icon from './Icon.vue'
import LangSwitch from './LangSwitch.vue'
import { theme, themes, setTheme } from '../theme.js'

const sections = [
  { id: 'general', icon: 'globe', label: 'settings.general' },
  { id: 'server', icon: 'server', label: 'settings.server' },
  { id: 'commands', icon: 'terminal', label: 'settings.commands' },
]
const section = ref((() => { try { return localStorage.getItem('ab_settings_section') || 'general' } catch { return 'general' } })())
function pick(id) {
  section.value = id
  try { localStorage.setItem('ab_settings_section', id) } catch { /* ignore */ }
}

// ---------- server ----------
const info = ref(null)
const infoErr = ref('')
const infoBusy = ref(false)

async function loadInfo() {
  const id = activeBotId()
  info.value = null
  if (id < 0) { infoErr.value = t('settings.botOffline'); return }
  infoBusy.value = true
  try { info.value = await api.serverInfo(id); infoErr.value = '' } catch (e) { infoErr.value = e.message }
  infoBusy.value = false
}

const activeCfg = computed(() => store.bots.find(b => b.name === store.activeBot))

function fmtDate(v) {
  if (!v) return '—'
  const d = new Date(v)
  return isNaN(d) ? String(v) : d.toLocaleString(lang.value)
}

const serverRows = computed(() => {
  const i = info.value || {}
  return [
    ['settings.srvName', i.name],
    ['settings.srvAddress', activeCfg.value?.server],
    ['settings.srvIps', (i.ips || []).join(', ')],
    ['settings.srvPlatform', i.platform],
    ['settings.srvVersion', i.version],
    ['settings.srvProtocol', i.protocol],
    ['settings.srvId', i.virtualServerId],
    ['settings.srvCreated', fmtDate(i.created)],
    ['settings.srvClients', i.maxClients != null ? `${i.clientsOnline} / ${i.maxClients}` : i.clientsOnline],
    ['settings.srvChannels', i.channels],
    ['settings.botNick', i.botName],
    ['settings.srvWelcome', i.welcome],
  ].filter(r => r[1] !== undefined && r[1] !== null && r[1] !== '')
})

// ---------- commands ----------
const commands = ref([])
const cmdLoading = ref(false)
const filter = ref('')
const open = ref({})          // name -> true for expanded cards
const args = ref({})          // name -> { overload, values[] }
const results = ref({})       // name -> { ok, text }
const free = ref('')
const freeOut = ref(null)

async function loadCommands() {
  if (commands.value.length || cmdLoading.value) return
  cmdLoading.value = true
  try { commands.value = (await api.commands()).commands || [] } catch (e) { showToast(e.message, 'error') }
  cmdLoading.value = false
}

function descr(c) {
  const key = 'cmd.' + c.name
  return messages[lang.value]?.[key] || c.description || messages.en[key] || ''
}

const groups = computed(() => {
  const q = filter.value.trim().toLowerCase()
  const map = new Map()
  for (const c of commands.value) {
    if (q && !(c.name.toLowerCase().includes(q) || descr(c).toLowerCase().includes(q))) continue
    const g = c.name.split(' ')[0]
    if (!map.has(g)) map.set(g, [])
    map.get(g).push(c)
  }
  return [...map.entries()]
})

function argState(c) {
  if (!args.value[c.name]) args.value[c.name] = { overload: 0, values: [] }
  return args.value[c.name]
}

function quote(v) {
  if (v === '' || /[\s"\\]/.test(v)) return '"' + v.replace(/\\/g, '\\\\').replace(/"/g, '\\"') + '"'
  return v
}

function buildLine(c) {
  const st = argState(c)
  const ov = c.overloads[st.overload] || c.overloads[0]
  const parts = [PREFIX + c.name]
  ;(ov?.parameters || []).forEach((p, i) => {
    const v = (st.values[i] ?? '').trim()
    if (v !== '') parts.push(quote(v))
  })
  return parts.join(' ')
}

// command prefix of this bot build (patch.sh sets DefaultCommandChar to /)
const PREFIX = '/'
const DANGEROUS = /(quit|stop|remove|delete|clear|reset|kill|disconnect|shutdown)/

async function run(line, name, out) {
  const id = activeBotId()
  if (id < 0) { showToast(t('settings.botOffline'), 'error'); return }
  if (DANGEROUS.test(line.split(' ')[0] + ' ' + (name || '')) && !confirm(t('settings.confirmRun', { line }))) return
  try {
    const r = await api.runCommand(id, line)
    out({ ok: r.ok, text: r.ok ? (r.result || t('settings.done')) : r.error })
    bump()
  } catch (e) { out({ ok: false, text: e.message }) }
}

async function uninstallBot() {
  if (!confirm(t('settings.uninstallConfirm'))) return
  if (prompt(t('settings.uninstallType')) !== 'DELETE') return
  run('/uninstall DELETE', '', o => { uninstallOut.value = o })
}
const uninstallOut = ref(null)

function runCmd(c) { run(buildLine(c), c.name, o => { results.value[c.name] = o }) }
function runFree() {
  const v = free.value.trim()
  if (v) run(v, '', o => { freeOut.value = o })
}

watch(section, s => { if (s === 'server') loadInfo(); if (s === 'commands') loadCommands() })
watch(activeBotId, () => { if (section.value === 'server') loadInfo() })
watch(() => store.tab, tab => { if (tab === 'settings') { if (section.value === 'server') loadInfo(); if (section.value === 'commands') loadCommands() } })
onMounted(() => { if (store.tab === 'settings') { if (section.value === 'server') loadInfo(); if (section.value === 'commands') loadCommands() } })
</script>

<template>
  <div>
    <div class="page-title">{{ $t('settings.title') }}</div>
    <div class="page-sub">{{ $t('settings.sub') }}</div>

    <div class="sections">
      <button v-for="s in sections" :key="s.id" class="chip big" :class="{ active: section === s.id }" @click="pick(s.id)">
        <Icon :name="s.icon" :size="15" /> {{ $t(s.label) }}
      </button>
    </div>

    <!-- general -->
    <div v-if="section === 'general'" class="stack">
      <div class="card block">
        <div class="block-title">{{ $t('settings.language') }}</div>
        <div class="block-sub">{{ $t('settings.languageHint') }}</div>
        <LangSwitch />
      </div>
      <div class="card block">
        <div class="block-title">{{ $t('settings.theme') }}</div>
        <div class="block-sub">{{ $t('settings.themeHint') }}</div>
        <div class="theme-switch">
          <button v-for="th in themes" :key="th" class="chip" :class="{ active: theme === th }" @click="setTheme(th)">{{ $t('settings.theme_' + th) }}</button>
        </div>
      </div>
      <div class="card block">
        <div class="block-title">{{ $t('settings.shortcuts') }}</div>
        <table class="kv">
          <tr><td><kbd>Space</kbd></td><td>{{ $t('settings.kPause') }}</td></tr>
          <tr><td><kbd>←</kbd> <kbd>→</kbd></td><td>{{ $t('settings.kSeek') }}</td></tr>
          <tr><td><kbd>↑</kbd> <kbd>↓</kbd></td><td>{{ $t('settings.kVolume') }}</td></tr>
          <tr><td><kbd>N</kbd> <kbd>P</kbd></td><td>{{ $t('settings.kSkip') }}</td></tr>
        </table>
      </div>
      <div class="card block">
        <div class="block-title">{{ $t('settings.about') }}</div>
        <table class="kv">
          <tr><td>{{ $t('settings.botVersion') }}</td><td>{{ store.version || '—' }}</td></tr>
          <tr><td>{{ $t('settings.instances') }}</td><td>{{ store.bots.length }}</td></tr>
        </table>
      </div>
      <div class="card block danger">
        <div class="block-title">{{ $t('settings.uninstall') }}</div>
        <div class="block-sub">{{ $t('settings.uninstallHint') }}</div>
        <button class="btn danger" @click="uninstallBot"><Icon name="trash" :size="14" /> {{ $t('settings.uninstallBtn') }}</button>
        <div v-if="uninstallOut" class="block-sub" :class="{ err: !uninstallOut.ok }" style="margin-top: 8px">{{ uninstallOut.text }}</div>
      </div>
    </div>

    <!-- server -->
    <div v-else-if="section === 'server'" class="stack">
      <div class="card block">
        <div class="block-title row">
          {{ $t('settings.server') }}
          <button class="icon-btn" :title="$t('common.refresh')" @click="loadInfo"><Icon name="refresh" :size="16" /></button>
        </div>
        <div v-if="infoBusy" style="padding: 20px; text-align: center"><span class="spin"></span></div>
        <div v-else-if="infoErr" class="empty" style="padding: 24px 0">{{ infoErr }}</div>
        <table v-else class="kv">
          <tr v-for="r in serverRows" :key="r[0]"><td>{{ $t(r[0]) }}</td><td class="wrap">{{ r[1] }}</td></tr>
        </table>
      </div>
    </div>

    <!-- commands -->
    <div v-else class="stack">
      <div class="card block">
        <div class="block-title">{{ $t('settings.console') }}</div>
        <div class="block-sub">{{ $t('settings.consoleHint') }}</div>
        <form class="console" @submit.prevent="runFree">
          <span class="prompt">/</span>
          <input v-model="free" placeholder="help  |  bot info  |  list list" autocapitalize="off" autocomplete="off" spellcheck="false" />
          <button class="btn primary" :disabled="!free.trim()">{{ $t('settings.run') }}</button>
        </form>
        <pre v-if="freeOut" class="out" :class="{ bad: !freeOut.ok }">{{ freeOut.text }}</pre>
      </div>

      <div class="card block">
        <div class="block-title row">
          {{ $t('settings.commandList') }}
          <span class="badge">{{ commands.length }}</span>
        </div>
        <input v-model="filter" class="filter" :placeholder="$t('settings.filter')" />
        <div v-if="cmdLoading" style="padding: 24px; text-align: center"><span class="spin"></span></div>
        <div v-for="[g, list] in groups" :key="g" class="cmd-group">
          <div class="cmd-group-title">{{ g }}</div>
          <div v-for="c in list" :key="c.name" class="cmd">
            <div class="cmd-head" @click="open[c.name] = !open[c.name]">
              <Icon :name="open[c.name] ? 'down' : 'right'" :size="14" class="chev" />
              <code class="cmd-name">/{{ c.name }}</code>
              <span class="cmd-desc">{{ descr(c) }}</span>
            </div>
            <div v-if="open[c.name]" class="cmd-body">
              <div v-if="descr(c)" class="cmd-full">{{ descr(c) }}</div>
              <div v-if="c.overloads.length > 1" class="ov-pick">
                <button v-for="(o, i) in c.overloads" :key="i" class="chip" :class="{ active: argState(c).overload === i }"
                  @click="argState(c).overload = i; argState(c).values = []">
                  {{ o.parameters.length ? o.parameters.map(p => p.name).join(' ') : '—' }}
                </button>
              </div>
              <div v-for="u in (c.overloads[argState(c).overload] || c.overloads[0]).usage" :key="u.syntax" class="usage">
                <code>/{{ c.name }} {{ u.syntax }}</code> <span>{{ u.help }}</span>
              </div>
              <div class="params">
                <label v-for="(p, i) in (c.overloads[argState(c).overload] || c.overloads[0]).parameters" :key="p.name + i">
                  <span>{{ p.name }} <em>{{ p.type }}{{ p.optional ? ', ' + $t('settings.optional') : '' }}</em></span>
                  <input v-model="argState(c).values[i]" autocapitalize="off" autocomplete="off" spellcheck="false" @keydown.enter="runCmd(c)" />
                </label>
              </div>
              <div class="run-row">
                <code class="line">{{ buildLine(c) }}</code>
                <button class="btn small primary" @click="runCmd(c)"><Icon name="play" :size="12" /> {{ $t('settings.run') }}</button>
              </div>
              <pre v-if="results[c.name]" class="out" :class="{ bad: !results[c.name].ok }">{{ results[c.name].text }}</pre>
            </div>
          </div>
        </div>
        <div v-if="!cmdLoading && groups.length === 0" class="empty" style="padding: 20px 0">{{ $t('player.nothingFound') }}</div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.theme-switch { display: flex; gap: 6px; flex-wrap: wrap; }
.sections { display: flex; gap: 8px; flex-wrap: wrap; margin-bottom: 18px; }
.stack { display: flex; flex-direction: column; gap: 16px; max-width: 900px; }
.block { padding: 18px 20px; }
.block-title { font-weight: 700; font-size: 15px; margin-bottom: 10px; }
.block-title.row { display: flex; align-items: center; justify-content: space-between; }
.block-sub { color: var(--text-dim); font-size: 13px; margin: -4px 0 12px; }
.kv { width: 100%; border-collapse: collapse; font-size: 14px; }
.kv td { padding: 7px 0; border-bottom: 1px solid var(--border); vertical-align: top; }
.kv tr:last-child td { border-bottom: none; }
.kv td:first-child { color: var(--text-dim); width: 42%; padding-right: 12px; }
.kv td.wrap { overflow-wrap: anywhere; }
kbd { background: var(--bg-soft); border: 1px solid var(--border); border-bottom-width: 2px; border-radius: 5px; padding: 1px 7px; font-size: 12px; font-family: inherit; }
.console { display: flex; gap: 8px; align-items: center; }
.console input { flex: 1; min-width: 0; font-family: ui-monospace, Consolas, monospace; }
.prompt { font-family: ui-monospace, Consolas, monospace; color: var(--accent); font-weight: 700; }
.out { margin-top: 10px; padding: 10px 12px; background: var(--bg-soft); border: 1px solid var(--border); border-radius: var(--radius-sm); font-size: 12.5px; white-space: pre-wrap; overflow-wrap: anywhere; max-height: 260px; overflow-y: auto; font-family: ui-monospace, Consolas, monospace; }
.out.bad { border-color: var(--accent); color: var(--accent2); }
.filter { width: 100%; margin-bottom: 12px; }
.cmd-group { margin-top: 12px; }
.cmd-group-title { font-size: 12px; text-transform: uppercase; letter-spacing: .06em; color: var(--text-faint); margin-bottom: 4px; }
.cmd { border-bottom: 1px solid var(--border); }
.cmd:last-child { border-bottom: none; }
.cmd-head { display: flex; align-items: center; gap: 8px; padding: 8px 4px; cursor: pointer; min-width: 0; }
.cmd-head:hover { background: var(--card-hover); border-radius: 6px; }
.chev { color: var(--text-faint); }
.cmd-name { font-family: ui-monospace, Consolas, monospace; font-size: 13px; color: var(--accent2); white-space: nowrap; }
.cmd-desc { color: var(--text-dim); font-size: 13px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; min-width: 0; }
.cmd-body { padding: 4px 8px 14px 26px; }
.cmd-full { font-size: 13px; margin-bottom: 8px; }
.ov-pick { display: flex; gap: 6px; flex-wrap: wrap; margin-bottom: 8px; }
.usage { font-size: 12px; color: var(--text-dim); margin-bottom: 4px; overflow-wrap: anywhere; }
.usage code { color: var(--text); }
.params { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 10px; margin: 10px 0; }
.params label { display: flex; flex-direction: column; gap: 4px; font-size: 12px; color: var(--text-dim); }
.params em { color: var(--text-faint); font-style: normal; }
.run-row { display: flex; align-items: center; gap: 10px; justify-content: space-between; }
.run-row .line { font-family: ui-monospace, Consolas, monospace; font-size: 12px; color: var(--text-dim); overflow: hidden; text-overflow: ellipsis; white-space: nowrap; min-width: 0; }
</style>
