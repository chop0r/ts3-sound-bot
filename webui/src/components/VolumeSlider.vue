<script setup>
import { computed, ref } from 'vue'
import { activeBotId, activeBotState, showToast } from '../store.js'
import { api } from '../api.js'
import Icon from './Icon.vue'

const state = computed(() => activeBotState())
const drag = ref(null)          // value while the slider is dragged or the command has not reached the bot yet
const shown = computed(() => drag.value ?? state.value?.volume ?? 0)
let timer = null
let before = 50                 // volume before muting

async function commit(v) {
  try { await api.volume(activeBotId(), v) } catch (e) { showToast(e.message, 'error') }
  setTimeout(() => { if (drag.value === v) drag.value = null }, 1200)
}

function set(v) {
  drag.value = v
  clearTimeout(timer)
  timer = setTimeout(() => commit(v), 120)
}

function toggleMute() {
  if (shown.value > 0) { before = shown.value; set(0) } else set(before || 50)
}
</script>

<template>
  <div class="vol">
    <button class="icon-btn" @click="toggleMute"><Icon :name="shown > 0 ? 'volume' : 'mute'" :size="18" /></button>
    <input class="slider" type="range" min="0" max="100" :value="shown" :style="{ '--p': shown + '%' }" @input="set(+$event.target.value)" />
    <span class="vol-num">{{ shown }}</span>
  </div>
</template>

<style scoped>
.vol { display: flex; align-items: center; gap: 6px; min-width: 0; }
.vol input[type='range'] { flex: 1; min-width: 60px; }
.vol-num { width: 26px; text-align: right; font-size: 12px; color: var(--text-dim); flex-shrink: 0; }
</style>
