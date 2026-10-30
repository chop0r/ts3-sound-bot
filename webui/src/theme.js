import { ref } from 'vue'

// dark (default), light, hacker (green on black), auto (light or dark as in the system)
export const themes = ['dark', 'light', 'hacker', 'auto']
const KEY = 'ab_theme'

function stored() {
  try {
    const s = localStorage.getItem(KEY)
    if (themes.includes(s)) return s
  } catch { /* without storage the default theme stays */ }
  return 'dark'
}

export const theme = ref(stored())

const media = window.matchMedia ? window.matchMedia('(prefers-color-scheme: light)') : null

function apply() {
  const light = theme.value === 'light' || (theme.value === 'auto' && media?.matches)
  document.documentElement.dataset.theme = theme.value === 'hacker' ? 'hacker' : light ? 'light' : 'dark'
}

export function setTheme(name) {
  if (!themes.includes(name)) return
  theme.value = name
  try { localStorage.setItem(KEY, name) } catch { /* ignore */ }
  apply()
}

media?.addEventListener?.('change', apply)
apply()
