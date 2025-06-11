/// <reference types="vite/client" />

interface ImportMetaEnv {
    readonly VITE_API_URL: string
    readonly VITE_SYNC_API_URL: string
    readonly VITE_SIGNALR_URL: string
}

interface ImportMeta {
    readonly env: ImportMetaEnv
} 