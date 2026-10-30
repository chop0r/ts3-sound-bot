<script setup>
import { onMounted, ref } from 'vue'
import { showToast, refreshStatus } from '../store.js'
import { api } from '../api.js'
import { t } from '../i18n.js'
import Icon from './Icon.vue'

const bots = ref([])
const loading = ref(true)
const showCreate = ref(false)

const form = ref({ name: '', server: '127.0.0.1:9987', tsName: '', channel: '', autoRun: true, startNow: true })
const renaming = ref(null)   // {name, value}
const channelling = ref(null) // {name, value}

async function load() {
  loading.value = true
  try {
    const r = await api.bots()
    bots.value = r.bots || []
  } catch (e) { showToast(e.message, 'error') }
  loading.value = false
}

async function createBot() {
  if (!form.value.name.trim()) { showToast(t('bots.nameRequired'), 'error'); return }
  try {
    const r = await api.createBot({ ...form.value, name: form.value.name.trim() })
    showToast(r.created ? t('bots.created', { name: r.name }) : t('bots.updated', { name: r.name }), 'success')
    showCreate.value = false
    await load()
    refreshStatus()
  } catch (e) { showToast(e.message, 'error') }
}

async function act(fn, okMsg) {
  try { await fn(); if (okMsg) showToast(okMsg, 'success'); await load(); refreshStatus() }
  catch (e) { showToast(e.message, 'error') }
}

function confirmDelete(b) {
  if (confirm(t('bots.confirmDelete', { name: b.name }))) act(() => api.deleteBot(b.name), t('bots.deleted'))
}

onMounted(load)
</script>

<template>
  <div>
    <div class="head">
      <div>
        <div class="page-title">{{ $t('bots.title') }}</div>
        <div class="page-sub">{{ $t('bots.sub') }}</div>
      </div>
      <div class="head-actions">
        <button class="btn" :title="$t('common.refresh')" @click="load"><Icon name="refresh" :size="15" /></button>
        <button class="btn primary" @click="showCreate = !showCreate"><Icon name="plus" :size="15" /> {{ $t('bots.new') }}</button>
      </div>
    </div>

    <div v-if="showCreate" class="card form-card">
      <div class="form-grid">
        <label>{{ $t('bots.fName') }}<input v-model="form.name" placeholder="music2" /></label>
        <label>{{ $t('bots.fServer') }}<input v-model="form.server" placeholder="127.0.0.1:9987" /></label>
        <label>{{ $t('bots.fNick') }}<input v-model="form.tsName" placeholder="Music bot 2" /></label>
        <label>{{ $t('bots.fChannel') }}<input v-model="form.channel" placeholder="Lobby/Music  |  /12" /></label>
      </div>
      <div class="form-foot">
        <label class="check"><input type="checkbox" v-model="form.autoRun" /> {{ $t('bots.autoRun') }}</label>
        <label class="check"><input type="checkbox" v-model="form.startNow" /> {{ $t('bots.startNow') }}</label>
        <button class="btn primary" style="margin-left: auto" @click="createBot">{{ $t('bots.create') }}</button>
      </div>
    </div>

    <div v-if="loading" style="padding: 50px; text-align: center"><span class="spin"></span></div>

    <div v-else class="bot-grid">
      <div v-for="b in bots" :key="b.name" class="card bot-card">
        <div class="bot-top">
          <div class="logo-dot ghost"><Icon name="music" :size="16" /></div>
          <div style="flex: 1; min-width: 0">
            <div class="bot-name">{{ b.tsName || b.name }}</div>
            <div class="bot-meta">{{ b.name }} · {{ b.server || $t('bots.noServer') }}</div>
          </div>
          <span class="badge" :class="{ ok: b.running }">{{ b.running ? $t('state.connected') : $t('state.offline') }}</span>
        </div>

        <div class="bot-info">
          <div v-if="b.running">{{ $t('bots.currentChannel') }}: <span style="color: var(--text)">{{ b.channelName || b.defaultChannel || $t('bots.default') }}</span></div>
          <div v-else>{{ $t('bots.defaultChannel') }}: {{ b.defaultChannel || $t('bots.notSet') }}</div>
          <div style="margin-top: 4px">
            {{ $t('bots.autoStart') }}:
            <button class="badge" style="cursor: pointer" @click="act(() => api.setAutoRun(b.name, !b.autoRun))">
              {{ b.autoRun ? $t('common.on') : $t('common.off') }}
            </button>
          </div>
        </div>

        <div class="bot-actions">
          <button v-if="!b.running" class="btn small primary" @click="act(() => api.connectBot(b.name), t('bots.connected'))"><Icon name="play" :size="12" /> {{ $t('bots.connect') }}</button>
          <button v-else class="btn small danger" @click="act(() => api.disconnectBot(b.name), t('bots.disconnected'))"><Icon name="stop" :size="12" /> {{ $t('bots.disconnect') }}</button>
          <button class="btn small" @click="renaming = { name: b.name, value: b.tsName }"><Icon name="edit" :size="13" /> {{ $t('bots.rename') }}</button>
          <button class="btn small" @click="channelling = { name: b.name, value: b.defaultChannel }"><Icon name="hash" :size="13" /> {{ $t('bots.channel') }}</button>
          <button class="btn small danger" style="margin-left: auto" :title="$t('common.delete')" @click="confirmDelete(b)"><Icon name="trash" :size="13" /></button>
        </div>

        <div v-if="renaming?.name === b.name" class="inline-edit">
          <input v-model="renaming.value" :placeholder="$t('bots.newNick')" style="flex: 1; min-width: 0" />
          <button class="btn small primary" @click="act(() => api.setTsName(renaming.name, renaming.value), t('bots.renamed')); renaming = null">{{ $t('common.save') }}</button>
          <button class="btn small" @click="renaming = null">{{ $t('common.cancel') }}</button>
        </div>
        <div v-if="channelling?.name === b.name" class="inline-edit">
          <input v-model="channelling.value" :placeholder="$t('bots.channelPlaceholder')" style="flex: 1; min-width: 0" />
          <button class="btn small primary" @click="act(() => api.setChannel(channelling.name, channelling.value), t('bots.channelSet')); channelling = null">{{ $t('bots.enter') }}</button>
          <button class="btn small" @click="channelling = null">{{ $t('common.cancel') }}</button>
        </div>
      </div>
    </div>

    <div v-if="!loading && bots.length === 0" class="empty">
      <div class="glyph"><Icon name="server" :size="38" /></div>
      {{ $t('bots.empty') }}
    </div>
  </div>
</template>

<style scoped>
.head { display: flex; align-items: flex-start; justify-content: space-between; gap: 12px; flex-wrap: wrap; }
.head-actions { display: flex; gap: 10px; }
.form-card { padding: 20px; margin: 14px 0; }
.form-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 12px; }
.form-grid label { display: flex; flex-direction: column; gap: 5px; font-size: 12px; color: var(--text-dim); }
.form-foot { display: flex; align-items: center; gap: 18px; margin-top: 14px; flex-wrap: wrap; }
.check { display: flex; align-items: center; gap: 7px; font-size: 13px; }
.check input { width: auto; }
.bot-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(min(330px, 100%), 1fr)); gap: 16px; margin-top: 16px; }
.bot-card { padding: 18px; }
.bot-top { display: flex; align-items: center; gap: 12px; margin-bottom: 12px; }
.bot-name { font-weight: 700; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.bot-meta { font-size: 12px; color: var(--text-dim); overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.bot-info { font-size: 12px; color: var(--text-dim); margin-bottom: 12px; }
.bot-actions { display: flex; flex-wrap: wrap; gap: 8px; }
.inline-edit { display: flex; gap: 8px; margin-top: 12px; }
.logo-dot.ghost { background: var(--card-hover); color: var(--text); }
.badge.ok { background: rgba(62, 207, 142, .14); color: var(--ok); }
</style>
