<script setup>
import { onMounted, ref, watch } from 'vue'
import { activeBotId, showToast, store, switchTab, bump } from '../store.js'
import { api } from '../api.js'
import { t } from '../i18n.js'
import Icon from './Icon.vue'
import Panel from './Panel.vue'

const playlists = ref([])
const loading = ref(true)

async function load() {
  const id = activeBotId()
  if (id < 0) { playlists.value = []; loading.value = false; return }
  try {
    playlists.value = (await api.playlists(id)).playlists || []
  } catch (e) { showToast(e.message, 'error') }
  loading.value = false
}

async function play(p, shuffle) {
  try {
    const r = await api.playPlaylist(activeBotId(), p.id, { shuffle })
    showToast(t('playlists.started', { title: p.title, n: r.count }), 'success')
    bump()
  } catch (e) { showToast(e.message, 'error') }
}

watch(activeBotId, load)
// the list may have changed on the playlists tab
watch(() => store.tab, tab => { if (tab === 'home') load() })
onMounted(load)
</script>

<template>
  <Panel id="shelf" :title="$t('home.playlists')" :badge="playlists.length">
    <template #actions>
      <button class="btn small" @click="switchTab('playlists')">{{ $t('home.manage') }} <Icon name="right" :size="13" /></button>
    </template>
    <div v-if="loading" style="padding: 24px; text-align: center"><span class="spin"></span></div>
    <div v-else-if="playlists.length === 0" class="empty" style="padding: 24px 0">{{ $t('home.noPlaylists') }}</div>
    <div v-else class="card" style="padding: 6px">
      <div v-for="p in playlists" :key="p.id" class="list-row">
        <img v-if="p.cover" :src="p.cover" class="row-cover" />
        <div v-else class="row-cover ph"><Icon name="list" :size="16" /></div>
        <div class="row-main">
          <div class="row-title">{{ p.title || p.id }}</div>
          <div class="row-sub">{{ $t('playlists.tracks', { n: p.count }) }}</div>
        </div>
        <div class="row-actions show">
          <button class="icon-btn accent-soft" :title="$t('playlists.play')" @click="play(p, false)"><Icon name="play" :size="15" /></button>
          <button class="icon-btn" :title="$t('playlists.shuffle')" @click="play(p, true)"><Icon name="shuffle" :size="15" /></button>
        </div>
      </div>
    </div>
  </Panel>
</template>
