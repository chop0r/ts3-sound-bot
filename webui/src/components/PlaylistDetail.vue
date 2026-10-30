<script setup>
import { onMounted, ref } from 'vue'
import { activeBotId, fmtTime, isLink, showToast, bump } from '../store.js'
import { api } from '../api.js'
import { t } from '../i18n.js'
import Icon from './Icon.vue'

const props = defineProps({ playlist: { type: Object, required: true } })
const emit = defineEmits(['close'])

const meta = ref(null)
const items = ref([])
const loading = ref(true)
const newUrl = ref('')
const found = ref(null)   // search results
const searching = ref(false)
const busy = ref(false)

async function load() {
  try {
    const res = await api.playlist(activeBotId(), props.playlist.id)
    meta.value = res
    items.value = res.items || []
  } catch (e) {
    showToast(e.message, 'error')
  }
  loading.value = false
}

async function playFrom(index, shuffle = false) {
  try {
    await api.playPlaylist(activeBotId(), props.playlist.id, shuffle ? { shuffle: true } : { index })
    showToast(t('playlists.playbackStarted'), 'success')
    bump()
  } catch (e) { showToast(e.message, 'error') }
}

async function playItem(it) {
  const link = it.link || it.resId
  try {
    await api.playNext(activeBotId(), link)
    showToast(t('toast.addedNext'), 'success')
    bump()
  } catch (e) { showToast(e.message, 'error') }
}

async function mutate(fn, okMsg) {
  busy.value = true
  try {
    await fn()
    if (okMsg) showToast(okMsg, 'success')
    await load()
  } catch (e) { showToast(e.message, 'error') }
  busy.value = false
}

function rename() {
  const cur = meta.value?.title || props.playlist.title || props.playlist.id
  const title = (prompt(t('playlists.renamePrompt'), cur) || '').trim()
  if (title && title !== cur) mutate(() => api.renamePlaylist(activeBotId(), props.playlist.id, title), t('playlists.renamed'))
}

async function addLink(url, title) {
  await mutate(async () => {
    const r = await api.addPlaylistItem(activeBotId(), props.playlist.id, url)
    showToast(t('playlists.added', { title: r.title || title || url }), 'success')
  })
}

// a link is added at once; text is searched and the results are shown (Enter again or the button adds the first one)
async function addItem() {
  const v = newUrl.value.trim()
  if (!v) return
  if (isLink(v)) {
    newUrl.value = ''
    found.value = null
    await addLink(v)
    return
  }
  if (found.value?.query === v && found.value.results.length) {
    await pick(found.value.results[0])
    return
  }
  searching.value = true
  try {
    const r = await api.search(activeBotId(), v)
    found.value = { query: v, results: r.results || [] }
  } catch (e) { showToast(e.message, 'error'); found.value = null }
  searching.value = false
}

async function pick(r) {
  newUrl.value = ''
  found.value = null
  await addLink(r.link, r.title)
}

function removeItem(i) {
  if (!confirm(t('playlists.confirmRemove', { title: items.value[i].title || items.value[i].resId }))) return
  mutate(() => api.removePlaylistItem(activeBotId(), props.playlist.id, i))
}

function moveItem(i, to) {
  if (to < 0 || to >= items.value.length) return
  mutate(() => api.movePlaylistItem(activeBotId(), props.playlist.id, i, to))
}

onMounted(load)
</script>

<template>
  <div class="modal-mask" @click.self="emit('close')">
    <div class="modal">
      <div class="modal-head">
        <img v-if="meta?.cover" :src="meta.cover" />
        <div v-else class="pl-cover-ph mh-ph"><Icon name="music" :size="22" /></div>
        <div style="flex: 1; min-width: 0">
          <div class="mh-title">{{ meta?.title || playlist.title || playlist.id }}
            <button class="icon-btn" :title="$t('playlists.rename')" :disabled="busy" @click="rename"><Icon name="edit" :size="15" /></button>
          </div>
          <div class="mh-sub">{{ $t('playlists.tracks', { n: meta?.count ?? '…' }) }}<span v-if="meta?.creator"> · {{ meta.creator }}</span></div>
        </div>
        <div class="mh-actions">
          <button class="btn primary" @click="playFrom(0)"><Icon name="play" :size="13" /> <span class="lbl">{{ $t('playlists.playAll') }}</span></button>
          <button class="btn" :title="$t('playlists.shuffle')" @click="playFrom(0, true)"><Icon name="shuffle" :size="14" /></button>
          <button class="icon-btn" @click="emit('close')"><Icon name="x" :size="18" /></button>
        </div>
      </div>
      <div class="modal-body">
        <div v-if="loading" style="padding: 50px; text-align: center"><span class="spin"></span></div>
        <div v-else>
          <div class="add-row">
            <input v-model="newUrl" style="flex: 1; min-width: 0" :placeholder="$t('playlists.addPlaceholder')" @keydown.enter="addItem" />
            <button class="btn primary" :disabled="busy || searching || !newUrl.trim()" @click="addItem"><Icon name="plus" :size="15" /> <span class="lbl">{{ $t('playlists.add') }}</span></button>
          </div>
          <div v-if="searching" style="padding: 0 14px 10px"><span class="spin"></span></div>
          <div v-else-if="found" style="padding: 0 14px 10px">
            <div class="found-head">{{ $t('playlists.foundHint', { q: found.query }) }}
              <button class="icon-btn" :title="$t('common.close')" @click="found = null"><Icon name="x" :size="15" /></button></div>
            <div v-if="found.results.length === 0" style="color: var(--text-dim)">{{ $t('player.nothingFound') }}</div>
            <div v-for="r in found.results.slice(0, 8)" :key="r.id" class="list-row">
              <div class="row-main"><div class="row-title">{{ r.title || r.id }}</div></div>
              <div class="row-actions show"><button class="icon-btn" :title="$t('playlists.addToList')" :disabled="busy" @click="pick(r)"><Icon name="plus" :size="16" /></button></div>
            </div>
          </div>
          <div v-if="items.length === 0" class="empty" style="padding: 30px">{{ $t('playlists.listEmpty') }}</div>
          <div v-for="(it, i) in items" :key="i" class="list-row">
            <div class="idx">{{ i + 1 }}</div>
            <img v-if="it.cover" :src="it.cover" class="row-cover" />
            <div v-else class="row-cover"></div>
            <div class="row-main">
              <div class="row-title">{{ it.title || it.resId }}</div>
              <div class="row-sub">{{ [it.artist, it.album, it.duration ? fmtTime(+it.duration) : ''].filter(Boolean).join(' · ') }}</div>
            </div>
            <div class="row-actions">
              <button class="icon-btn" :title="$t('playlists.moveUp')" :disabled="busy || i === 0" @click="moveItem(i, i - 1)"><Icon name="up" :size="15" /></button>
              <button class="icon-btn" :title="$t('playlists.moveDown')" :disabled="busy || i === items.length - 1" @click="moveItem(i, i + 1)"><Icon name="down" :size="15" /></button>
              <button class="icon-btn" :title="$t('playlists.removeTrack')" :disabled="busy" @click="removeItem(i)"><Icon name="trash" :size="15" /></button>
              <button class="icon-btn" :title="$t('player.playNext')" @click="playItem(it)"><Icon name="queue" :size="16" /></button>
              <button class="icon-btn" :title="$t('playlists.playFromHere')" @click="playFrom(i)"><Icon name="play" :size="15" /></button>
              <a v-if="it.link" class="icon-btn" :href="it.link" target="_blank" rel="noopener" :title="$t('playlists.open')"><Icon name="link" :size="15" /></a>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.mh-ph { width: 54px; height: 54px; border-radius: 10px; aspect-ratio: auto; flex-shrink: 0; }
.mh-actions { display: flex; align-items: center; gap: 8px; }
.add-row { display: flex; gap: 8px; padding: 10px 14px; }
.found-head { font-size: 13px; color: var(--text-dim); margin-bottom: 4px; display: flex; align-items: center; justify-content: space-between; gap: 8px; }
@media (max-width: 720px) {
  .mh-actions .lbl, .add-row .lbl { display: none; }
}
</style>
