<script setup>
import { computed, onMounted, onUnmounted, ref, watch } from 'vue'
import { store, activeBotId, showToast } from '../store.js'
import { api } from '../api.js'
import { t } from '../i18n.js'
import Icon from './Icon.vue'
import Panel from './Panel.vue'

const data = ref(null)
const err = ref('')
const dragging = ref(false)
const over = ref(null)
const closed = ref({})
let timer = null

async function load() {
  const id = activeBotId()
  if (id < 0) { data.value = null; err.value = t('channels.offline'); return }
  try {
    data.value = await api.tree(id)
    err.value = ''
  } catch (e) { err.value = e.message }
}

// ordered list of child channels: order holds the id of the previous sibling (0 = first)
function children(parent) {
  const list = (data.value?.channels || []).filter(c => c.parent === parent)
  const out = []
  let prev = 0
  while (out.length < list.length) {
    const next = list.find(c => c.order === prev && !out.includes(c))
    if (!next) break
    out.push(next); prev = next.id
  }
  for (const c of list) if (!out.includes(c)) out.push(c)
  return out
}

const rows = computed(() => {
  const rows = []
  const walk = (parent, depth) => {
    for (const ch of children(parent)) {
      const clients = (data.value.clients || []).filter(c => c.channel === ch.id)
      rows.push({ ch, depth, clients, hasKids: children(ch.id).length > 0 })
      if (!closed.value[ch.id]) walk(ch.id, depth + 1)
    }
  }
  if (data.value) walk(0, 0)
  return rows
})

async function moveTo(ch) {
  if (!data.value || ch.id === data.value.selfChannel) return
  try {
    await api.treeMove(activeBotId(), ch.id)
    showToast(t('channels.moved', { name: ch.name }), 'success')
    await load()
  } catch (e) { showToast(e.message, 'error') }
}

function onDrop(ev, ch) {
  ev.preventDefault()
  over.value = null; dragging.value = false
  moveTo(ch)
}

watch(() => store.tab, tab => { if (tab === 'home') load() })
watch(activeBotId, load)
onMounted(() => { load(); timer = setInterval(() => { if (store.tab === 'home') load() }, 4000) })
onUnmounted(() => clearInterval(timer))
</script>

<template>
  <Panel id="channels" :title="$t('channels.title')">
    <template #actions>
      <button class="icon-btn" :title="$t('common.refresh')" @click="load"><Icon name="refresh" :size="16" /></button>
    </template>
    <div class="hint">{{ $t('channels.hint') }}</div>

    <div v-if="err" class="empty" style="padding: 22px 0">{{ err }}</div>

    <div v-else-if="data" class="card tree">
      <div v-for="r in rows" :key="r.ch.id" :style="{ marginLeft: r.depth * 16 + 'px' }"
        @dragover.prevent="over = r.ch.id" @dragleave="over = null" @drop="onDrop($event, r.ch)">
        <div class="ch-row" :class="{ here: r.ch.id === data.selfChannel, over: dragging && over === r.ch.id }">
          <span v-if="r.hasKids" class="tog" @click="closed[r.ch.id] = !closed[r.ch.id]"><Icon :name="closed[r.ch.id] ? 'right' : 'down'" :size="14" /></span>
          <span v-else class="tog"></span>
          <Icon name="hash" :size="13" style="color: var(--text-faint)" />
          <span class="ch-name">{{ r.ch.name }}</span>
          <button v-if="r.ch.id !== data.selfChannel" class="btn small" @click="moveTo(r.ch)">{{ $t('channels.moveHere') }}</button>
          <span v-else class="badge ok">{{ $t('channels.botHere') }}</span>
        </div>
        <div v-for="c in r.clients" :key="c.id" class="ch-cl" :draggable="c.self" :class="{ me: c.self }"
          @dragstart="c.self && (dragging = true)" @dragend="dragging = false; over = null">
          <Icon :name="c.self ? 'music' : 'user'" :size="13" />
          <span class="cl-name">{{ c.name }}</span>
          <span v-if="c.micMuted" :title="$t('channels.micOff')" class="muted">mic off</span>
          <span v-if="c.spkMuted" :title="$t('channels.soundOff')" class="muted">sound off</span>
        </div>
      </div>
    </div>
    <div v-else style="padding: 30px; text-align: center"><span class="spin"></span></div>
  </Panel>
</template>

<style scoped>
.hint { font-size: 12px; color: var(--text-faint); margin: -4px 0 8px; }
.tree { padding: 8px 6px; max-height: 420px; overflow-y: auto; }
.ch-row { display: flex; align-items: center; gap: 6px; padding: 5px 8px; border-radius: var(--radius-sm); font-size: 14px; border: 1px dashed transparent; }
.ch-row:hover { background: var(--card-hover); }
.ch-row.here { background: var(--accent-soft); }
.ch-row.over { border-color: var(--accent); background: var(--accent-soft); }
.tog { width: 16px; cursor: pointer; color: var(--text-dim); display: inline-flex; justify-content: center; flex-shrink: 0; }
.ch-name { flex: 1; min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.ch-cl { display: flex; align-items: center; gap: 7px; padding: 2px 10px 2px 38px; font-size: 13px; color: var(--text-dim); }
.ch-cl.me { color: var(--text); font-weight: 600; cursor: grab; }
.cl-name { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.muted { font-size: 10px; color: var(--text-faint); border: 1px solid var(--border); border-radius: 4px; padding: 0 4px; }
.badge.ok { background: rgba(62, 207, 142, .14); color: var(--ok); }
</style>
