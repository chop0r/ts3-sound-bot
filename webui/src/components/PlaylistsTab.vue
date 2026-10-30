<script setup>
import { onMounted, ref, watch } from 'vue'
import { activeBotId, showToast, bump } from '../store.js'
import { api } from '../api.js'
import { t } from '../i18n.js'
import Icon from './Icon.vue'
import PlaylistDetail from './PlaylistDetail.vue'

const playlists = ref([])
const loading = ref(true)
const detail = ref(null)   // playlist whose editor is open

async function load() {
  const id = activeBotId()
  if (id < 0) { playlists.value = []; loading.value = false; return }
  loading.value = true
  try {
    const res = await api.playlists(id)
    playlists.value = res.playlists || []
  } catch (e) {
    showToast(e.message, 'error')
  }
  loading.value = false
}

async function quickPlay(p, shuffle) {
  try {
    const r = await api.playPlaylist(activeBotId(), p.id, { shuffle })
    showToast(t('playlists.started', { title: p.title, n: r.count }), 'success')
    bump()
  } catch (e) { showToast(e.message, 'error') }
}

async function remove(p) {
  if (!confirm(t('playlists.confirmDelete', { title: p.title }))) return
  try {
    await api.deletePlaylist(activeBotId(), p.id)
    showToast(t('playlists.deleted'), 'success')
    await load()
  } catch (e) { showToast(e.message, 'error') }
}

async function createNew() {
  const title = (prompt(t('playlists.newPrompt')) || '').trim()
  if (!title) return
  try {
    const r = await api.createPlaylist(activeBotId(), title)
    showToast(t('playlists.created'), 'success')
    await load()
    detail.value = { id: r.id, title: r.title }
  } catch (e) { showToast(e.message, 'error') }
}

function sourceHost(src) {
  if (!src) return null
  try { return new URL(src).host } catch { return t('playlists.external') }
}

watch(activeBotId, () => load())
onMounted(load)
</script>

<template>
  <div>
    <div class="head">
      <div>
        <div class="page-title">{{ $t('playlists.title') }}</div>
        <div class="page-sub">{{ $t('playlists.sub') }}</div>
      </div>
      <div class="head-actions">
        <button class="btn primary" @click="createNew"><Icon name="plus" :size="15" /> {{ $t('playlists.new') }}</button>
        <button class="btn" :title="$t('common.refresh')" @click="load"><Icon name="refresh" :size="15" /></button>
      </div>
    </div>

    <div v-if="loading" style="padding: 60px; text-align: center"><span class="spin"></span></div>

    <div v-else-if="playlists.length === 0" class="empty">
      <div class="glyph"><Icon name="list" :size="38" /></div>
      {{ $t('playlists.empty') }}
    </div>

    <div v-else class="grid">
      <div v-for="p in playlists" :key="p.id" class="pl-card" @click="detail = p">
        <img v-if="p.cover" :src="p.cover" class="pl-cover" />
        <div v-else class="pl-cover-ph"><Icon name="music" :size="34" /></div>
        <div class="pl-info">
          <div class="pl-name">{{ p.title || p.id }}</div>
          <div class="pl-sub">
            <span>{{ $t('playlists.tracks', { n: p.count }) }}</span>
            <span v-if="sourceHost(p.source)" class="badge">{{ sourceHost(p.source) }}</span>
          </div>
        </div>
        <div class="pl-actions" @click.stop>
          <button class="btn small primary" @click="quickPlay(p, false)"><Icon name="play" :size="12" /> {{ $t('playlists.play') }}</button>
          <button class="btn small" :title="$t('playlists.shuffle')" @click="quickPlay(p, true)"><Icon name="shuffle" :size="13" /></button>
          <button class="btn small danger" style="margin-left: auto" :title="$t('common.delete')" @click="remove(p)"><Icon name="trash" :size="13" /></button>
        </div>
      </div>
    </div>

    <PlaylistDetail v-if="detail" :playlist="detail" @close="detail = null; load()" />
  </div>
</template>

<style scoped>
.head { display: flex; align-items: flex-start; justify-content: space-between; gap: 12px; flex-wrap: wrap; }
.head-actions { display: flex; gap: 8px; }
.pl-actions { display: flex; flex-wrap: wrap; gap: 8px; padding: 0 14px 14px; }
</style>
