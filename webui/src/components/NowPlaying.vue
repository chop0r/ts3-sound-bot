<script setup>
import { onMounted, onUnmounted, ref, watch } from 'vue'
import { activeBotId, fmtTime, isLink, showToast, bump, store } from '../store.js'
import { api } from '../api.js'
import { t } from '../i18n.js'
import Icon from './Icon.vue'
import VolumeSlider from './VolumeSlider.vue'

const state = ref(null)
const results = ref(null)   // null = no search yet; array = search results
const searching = ref(false)
const lastQuery = ref('')
const query = ref('')
let timer = null

async function load() {
  const id = activeBotId()
  if (id < 0) { state.value = null; return }
  try {
    state.value = await api.player(id)
  } catch { state.value = null }
}

watch(activeBotId, () => load())
watch(() => store.tick, () => load())

async function act(fn, okMsg) {
  try {
    await fn(activeBotId())
    if (okMsg) showToast(okMsg, 'success')
    await load()
    bump()
  } catch (e) {
    showToast(e.message, 'error')
  }
}

// a link is added as next, text is a search by title or artist
async function submit() {
  const v = query.value.trim()
  if (!v) return
  if (isLink(v)) {
    act(b => api.playNext(b, v), t('toast.addedNext'))
    query.value = ''
    results.value = null
    return
  }
  searching.value = true
  lastQuery.value = v
  try {
    const r = await api.search(activeBotId(), v)
    results.value = r.results || []
  } catch (err) { showToast(err.message, 'error'); results.value = null }
  searching.value = false
}

// play now: if something is already playing, insert it as next and skip to it
async function playNow(r) {
  try {
    const bot = activeBotId()
    if (state.value?.playing && !state.value?.paused) {
      await api.playNext(bot, r.link)
      await api.next(bot)
    } else {
      await api.play(bot, r.link)
    }
    showToast(t('toast.playing', { title: r.title }), 'success')
    results.value = null
    await load()
    bump()
  } catch (err) { showToast(err.message, 'error') }
}

async function queueResult(r, next) {
  try {
    const bot = activeBotId()
    if (next) await api.playNext(bot, r.link)
    else await api.enqueue(bot, { url: r.link })
    showToast(next ? t('toast.addedNext') : t('toast.addedQueue'), 'success')
    await load()
    bump()
  } catch (err) { showToast(err.message, 'error') }
}

function seekByClick(e) {
  const r = e.currentTarget.getBoundingClientRect()
  const ratio = (e.clientX - r.left) / r.width
  const len = state.value?.length || 0
  if (len) act(b => api.seek(b, Math.floor(ratio * len)))
}

onMounted(() => { load(); timer = setInterval(load, 4000) })
onUnmounted(() => clearInterval(timer))
</script>

<template>
  <div v-if="state" class="card np">
    <div class="np-top">
      <img v-if="state.current?.cover" :src="state.current.cover" class="np-cover" />
      <div v-else class="np-cover ph"><Icon name="music" :size="44" /></div>
      <div class="np-info">
        <div class="np-title">{{ state.current?.title || $t('player.nothing') }}</div>
        <div class="np-artist">
          {{ state.current?.artist || (state.playing ? '' : $t('player.hint')) }}
        </div>
        <div class="np-controls">
          <button class="btn primary" @click="act(b => api.previous(b))"><Icon name="prev" :size="15" /><span class="lbl">{{ $t('player.previous') }}</span></button>
          <button v-if="state.paused || !state.playing" class="btn primary" @click="act(b => api.play(b))"><Icon name="play" :size="15" /><span class="lbl">{{ $t('player.play') }}</span></button>
          <button v-else class="btn primary" @click="act(b => api.pause(b, 1))"><Icon name="pause" :size="15" /><span class="lbl">{{ $t('player.pause') }}</span></button>
          <button class="btn primary" @click="act(b => api.next(b))"><span class="lbl">{{ $t('player.next') }}</span><Icon name="next" :size="15" /></button>
          <button class="btn danger" @click="act(b => api.stop(b))"><Icon name="stop" :size="14" /><span class="lbl">{{ $t('player.stop') }}</span></button>
        </div>
      </div>
    </div>

    <div class="np-progress">
      <span>{{ fmtTime(state.position) }}</span>
      <div class="progress-track" @click="seekByClick">
        <div class="progress-fill" :style="{ width: ((state.position / state.length) * 100 || 0) + '%', transition: 'none' }"></div>
      </div>
      <span>{{ fmtTime(state.length) }}</span>
    </div>

    <div class="np-volume"><VolumeSlider /></div>

    <form class="np-search" @submit.prevent="submit">
      <Icon name="search" :size="16" />
      <input v-model="query" :placeholder="$t('player.searchPlaceholder')" enterkeyhint="search" />
    </form>

    <div v-if="searching" class="np-results"><span class="spin"></span></div>
    <div v-else-if="results" class="np-results">
      <div class="res-head">
        <span>{{ $t('player.results', { q: lastQuery }) }}</span>
        <span>
          <button v-if="results.length" class="btn small primary" @click="playNow(results[0])"><Icon name="play" :size="12" /> {{ $t('player.playFirst') }}</button>
          <button class="icon-btn" :title="$t('common.close')" @click="results = null"><Icon name="x" :size="16" /></button>
        </span>
      </div>
      <div v-if="results.length === 0" class="empty" style="padding: 18px">{{ $t('player.nothingFound') }}</div>
      <div v-for="r in results" :key="r.id" class="list-row">
        <div class="row-main"><div class="row-title">{{ r.title || r.id }}</div></div>
        <div class="row-actions show">
          <button class="icon-btn" :title="$t('player.playNow')" @click="playNow(r)"><Icon name="play" :size="15" /></button>
          <button class="icon-btn" :title="$t('player.playNext')" @click="queueResult(r, true)"><Icon name="next" :size="15" /></button>
          <button class="icon-btn" :title="$t('player.addQueue')" @click="queueResult(r, false)"><Icon name="plus" :size="16" /></button>
        </div>
      </div>
    </div>
  </div>
  <div v-else class="card empty">
    <div class="glyph"><Icon name="power" :size="38" /></div>
    {{ $t('player.noBot') }}
  </div>
</template>

<style scoped>
.np { padding: 20px; }
.np-top { display: flex; align-items: flex-start; gap: 22px; }
.np-cover { width: 150px; height: 150px; border-radius: 16px; object-fit: cover; background: var(--bg-soft); flex-shrink: 0; }
.np-cover.ph { display: flex; align-items: center; justify-content: center; color: var(--text-faint); background: linear-gradient(135deg, #2a2e3c, #1b1e28); }
.np-info { flex: 1; min-width: 0; }
.np-title { font-size: 22px; font-weight: 700; line-height: 1.25; overflow-wrap: anywhere; }
.np-artist { color: var(--text-dim); font-size: 14px; margin: 4px 0 16px; min-height: 20px; }
.np-controls { display: flex; gap: 8px; flex-wrap: wrap; }
.np-progress { display: flex; align-items: center; gap: 10px; font-size: 12px; color: var(--text-dim); margin-top: 18px; }
.np-progress .progress-track { height: 6px; }
.np-volume { display: none; margin-top: 12px; }
.np-search { display: flex; align-items: center; gap: 8px; margin-top: 18px; padding: 0 12px; background: var(--bg-soft); border: 1px solid var(--border); border-radius: var(--radius-sm); color: var(--text-faint); }
.np-search:focus-within { border-color: var(--accent); }
.np-search input { flex: 1; border: none; background: transparent; padding: 10px 0; min-width: 0; }
.np-results { margin-top: 12px; }
.res-head { display: flex; align-items: center; justify-content: space-between; gap: 8px; margin-bottom: 4px; font-size: 13px; color: var(--text-dim); }

@media (max-width: 720px) {
  .np { padding: 16px; }
  .np-top { gap: 14px; }
  .np-cover { width: 96px; height: 96px; border-radius: 12px; }
  .np-title { font-size: 18px; }
  .np-artist { margin-bottom: 10px; }
  .np-controls .lbl { display: none; }
  .np-controls .btn { padding: 9px 13px; }
  .np-volume { display: block; }
}
</style>
