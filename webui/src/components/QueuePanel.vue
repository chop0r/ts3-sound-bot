<script setup>
import { onMounted, onUnmounted, ref, watch } from 'vue'
import { activeBotId, fmtTime, showToast, store, bump } from '../store.js'
import { api } from '../api.js'
import { t } from '../i18n.js'
import Icon from './Icon.vue'
import Panel from './Panel.vue'

const items = ref([])
let timer = null

async function load() {
  const id = activeBotId()
  if (id < 0) { items.value = []; return }
  try {
    const q = await api.queue(id)
    items.value = q.items || []
  } catch { /* bot offline */ }
}

watch(() => store.tick, load)
watch(activeBotId, load)

async function playItem(it) {
  try {
    // keep the queue intact and start playing from this song onwards
    await api.playQueueIndex(activeBotId(), it.index)
    showToast(t('toast.playingFrom', { title: it.title }), 'success')
    bump()
  } catch (e) { showToast(e.message, 'error') }
}

async function removeItem(i) {
  try {
    await api.removeQueue(activeBotId(), i)
    await load()
  } catch (e) { showToast(e.message, 'error') }
}

async function clear() {
  if (!items.value.length || !confirm(t('queue.confirmClear', { n: items.value.length }))) return
  try {
    await api.clearQueue(activeBotId())
    showToast(t('queue.cleared'), 'success')
    await load()
  } catch (e) { showToast(e.message, 'error') }
}

onMounted(() => { load(); timer = setInterval(load, 5000) })
onUnmounted(() => clearInterval(timer))
</script>

<template>
  <Panel id="queue" :title="$t('queue.title')" :badge="items.length">
    <template #actions>
      <button class="btn small danger" :disabled="!items.length" @click="clear"><Icon name="trash" :size="14" /> {{ $t('queue.clear') }}</button>
    </template>
    <div v-if="items.length === 0" class="empty" style="padding: 24px 0">{{ $t('queue.empty') }}</div>
    <div v-else class="card" style="padding: 6px">
      <div v-for="(it, i) in items" :key="i" class="list-row">
        <div class="idx">{{ i + 1 }}</div>
        <img v-if="it.cover" :src="it.cover" class="row-cover" />
        <div v-else class="row-cover"></div>
        <div class="row-main">
          <div class="row-title">{{ it.title || it.resId }}</div>
          <div class="row-sub">{{ [it.artist, it.duration ? fmtTime(+it.duration) : ''].filter(Boolean).join(' · ') }}</div>
        </div>
        <div class="row-actions">
          <button class="icon-btn" :title="$t('queue.playNow')" @click="playItem(it)"><Icon name="play" :size="15" /></button>
          <button class="icon-btn" :title="$t('queue.remove')" @click="removeItem(i)"><Icon name="x" :size="16" /></button>
        </div>
      </div>
    </div>
  </Panel>
</template>
