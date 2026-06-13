import { createEnglishTransformerSession } from "./en.js"
import { createNoopTransformerSession } from "./noop.js"
import type { TranscriptTransformerSession } from "./types.js"

export function createTranscriptTransformerSession(
    language: string,
    streamEnabled: boolean,
): TranscriptTransformerSession {
    if (language.startsWith("en-")) return createEnglishTransformerSession(streamEnabled)
    return createNoopTransformerSession()
}

export type { TranscriptTransformerSession } from "./types.js"
