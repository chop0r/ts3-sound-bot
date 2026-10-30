<script setup>
import { lang, languages, setLang } from '../i18n.js'
</script>

<template>
  <div class="lang-switch">
    <button v-for="(name, code) in languages" :key="code" class="chip" :class="{ active: lang === code }" @click="setLang(code)">{{ name }}</button>
  </div>
</template>

<style scoped>
.lang-switch { display: inline-flex; gap: 6px; flex-wrap: wrap; }
</style>
