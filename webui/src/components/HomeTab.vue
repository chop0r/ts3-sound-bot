<script setup>
import NowPlaying from './NowPlaying.vue'
import QueuePanel from './QueuePanel.vue'
import ChannelsPanel from './ChannelsPanel.vue'
import PlaylistShelf from './PlaylistShelf.vue'
</script>

<template>
  <div class="home">
    <div class="home-main">
      <NowPlaying />
      <QueuePanel />
    </div>
    <div class="home-side">
      <PlaylistShelf />
      <ChannelsPanel />
    </div>
  </div>
</template>

<style scoped>
.home { display: grid; grid-template-columns: minmax(0, 1.55fr) minmax(300px, 1fr); gap: 28px; align-items: start; }
.home-side > :first-child, .home-main > :nth-child(2) { margin-top: 20px; }
.home-side > :first-child { margin-top: 0; }
@media (max-width: 1000px) {
  .home { grid-template-columns: minmax(0, 1fr); gap: 0; }
  .home-side > :first-child { margin-top: 20px; }
}
</style>
