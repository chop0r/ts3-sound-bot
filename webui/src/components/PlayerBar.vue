<script setup>
import { computed } from 'vue'
import { activeBotId, activeBotState, fmtTime, showToast, bump } from '../store.js'
import { api } from '../api.js'
import Icon from './Icon.vue'
import VolumeSlider from './VolumeSlider.vue'

const state = computed(() => activeBotState())
const pct = computed(() => ((state.value?.position / state.value?.length) * 100) || 0)

async function act(fn) {
  try { await fn(activeBotId()); bump() } catch (e) { showToast(e.message, 'error') }
}

function seek(e) {
  const r = e.currentTarget.getBoundingClientRect()
  const len = state.value?.length || 0
  if (len) act(b => api.seek(b, Math.floor(((e.clientX - r.left) / r.width) * len)))
}
</script>

<template>
  <div v-if="state" class="playerbar">
    <div class="pb-left">
      <img v-if="state.current?.cover" :src="state.current.cover" class="pb-cover" />
      <div v-else class="pb-cover ph"><Icon name="music" :size="20" /></div>
      <div class="pb-meta">
        <div class="pb-title">{{ state.current?.title || $t('player.nothing') }}</div>
        <div class="pb-artist">{{ state.current?.artist || (state.paused ? $t('player.paused') : ' ') }}</div>
      </div>
    </div>

    <div class="pb-center">
      <div class="pb-controls">
        <button class="icon-btn" :title="$t('player.previous')" @click="act(b => api.previous(b))"><Icon name="prev" :size="18" /></button>
        <button v-if="!state.paused && state.playing" class="icon-btn big accent" :title="$t('player.pause')" @click="act(b => api.pause(b, 1))"><Icon name="pause" :size="20" /></button>
        <button v-else class="icon-btn big accent" :title="$t('player.play')" @click="act(b => api.play(b))"><Icon name="play" :size="20" /></button>
        <button class="icon-btn" :title="$t('player.next')" @click="act(b => api.next(b))"><Icon name="next" :size="18" /></button>
      </div>
      <div class="pb-progress">
        <span class="pb-time">{{ fmtTime(state.position) }}</span>
        <div class="progress-track" @click="seek">
          <div class="progress-fill" :style="{ width: pct + '%' }"></div>
        </div>
        <span class="pb-time right">{{ fmtTime(state.length) }}</span>
      </div>
    </div>

    <div class="pb-right"><VolumeSlider /></div>
  </div>
</template>
