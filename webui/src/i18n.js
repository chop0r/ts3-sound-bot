import { ref } from 'vue'
import en from './locales/en.json'
import ru from './locales/ru.json'

// To add a language: put locales/<code>.json next to the others and list it here
export const messages = { en, ru }
export const languages = { en: 'English', ru: 'Русский' }

const LANG_KEY = 'ab_lang'

function initial() {
  try {
    const s = localStorage.getItem(LANG_KEY)
    if (s && messages[s]) return s
  } catch { /* without storage the default language stays */ }
  return 'en'
}

export const lang = ref(initial())

export function setLang(code) {
  if (!messages[code]) return
  lang.value = code
  try { localStorage.setItem(LANG_KEY, code) } catch { /* ignore */ }
  document.documentElement.lang = code
}

/** t('key', { n: 3 }): translation with {n} substitution; a missing key falls back to English, then to the key itself. Reads lang.value, so templates re-render when the language changes. */
export function t(key, params) {
  let s = messages[lang.value]?.[key] ?? messages.en[key] ?? key
  if (params) for (const k of Object.keys(params)) s = s.split('{' + k + '}').join(String(params[k]))
  return s
}

document.documentElement.lang = lang.value
