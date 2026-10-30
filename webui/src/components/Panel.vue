<script setup>
import { ref } from 'vue'
import Icon from './Icon.vue'

const props = defineProps({
  title: { type: String, required: true },
  id: { type: String, required: true },     // key used to remember the collapsed state
  badge: { type: [String, Number], default: '' },
})

const key = 'ab_panel_' + props.id
const closed = ref(false)
try { closed.value = localStorage.getItem(key) === '1' } catch { /* ignore */ }

function toggle() {
  closed.value = !closed.value
  try { localStorage.setItem(key, closed.value ? '1' : '0') } catch { /* ignore */ }
}
</script>

<template>
  <section class="panel">
    <div class="panel-head" @click="toggle">
      <Icon :name="closed ? 'right' : 'down'" :size="16" class="chev" />
      <span class="panel-title">{{ title }}</span>
      <span v-if="badge !== ''" class="badge">{{ badge }}</span>
      <span class="panel-actions" @click.stop><slot name="actions" /></span>
    </div>
    <div v-show="!closed" class="panel-body"><slot /></div>
  </section>
</template>

<style scoped>
.panel { margin-top: 20px; }
.panel-head { display: flex; align-items: center; gap: 8px; cursor: pointer; user-select: none; margin-bottom: 10px; min-height: 30px; }
.chev { color: var(--text-faint); }
.panel-title { font-size: 15px; font-weight: 600; }
.panel-actions { margin-left: auto; display: flex; gap: 6px; align-items: center; }
</style>
