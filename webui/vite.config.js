import vue from '@vitejs/plugin-vue'
import { defineConfig } from 'vite'

// https://vite.dev/config/
// npm run dev: panel on a local port, API requests go to the bot (set the address with BOT_URL); npm run dev:mock runs against dev/mock-server.mjs
export default defineConfig(({ mode }) => ({
  plugins: [vue()],
  base: './',
  server: {
    proxy: {
      '/api': {
        target: mode === 'mock' ? 'http://127.0.0.1:58914' : (process.env.BOT_URL || 'https://127.0.0.1:58913'),
        secure: false,
        changeOrigin: true,
      },
    },
  },
}))
