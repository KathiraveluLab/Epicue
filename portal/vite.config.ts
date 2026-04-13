import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import wasm from 'vite-plugin-wasm';
import topLevelAwait from 'vite-plugin-top-level-await';

export default defineConfig({
  plugins: [
    react(),
    wasm(),
    topLevelAwait()
  ],
  define: {
    global: 'globalThis',
  },
  build: {
    target: 'esnext'
  },
  server: {
    port: 3001,
    strictPort: true
  }
});
