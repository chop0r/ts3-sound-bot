import { createApp } from 'vue'
import App from './App.vue'
import { t } from './i18n.js'
import './style.css'
import './theme.js'
import { APP_NAME } from './brand.js'

const app = createApp(App)
app.config.globalProperties.$t = t
document.title = APP_NAME
app.mount('#app')
