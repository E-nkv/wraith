import type { BrowserType } from "./browserLauncher"
import type { WSA_LANGUAGES } from "./constants"

export type Urgency = "low" | "normal" | "critical"

export type WSALanguage = (typeof WSA_LANGUAGES)[keyof typeof WSA_LANGUAGES]

export type SpeechEvent = { kind: "text"; text: string } | { kind: "segment-finalized" }

export interface CliFlags {
    lang: WSALanguage
    textNotifs: boolean
    stream: boolean
    soundNotifs: boolean
    browserType: BrowserType
    browserPath?: string
    timeout: number
    detached: boolean
    help: boolean
}
