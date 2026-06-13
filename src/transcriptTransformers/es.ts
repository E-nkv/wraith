import { createNoopTransformerSession } from "./noop.js"
import type { TranscriptTransformerSession } from "./types.js"

// Spanish spoken-punctuation transformer — stub for a future PR.
// Not wired into createTranscriptTransformerSession() yet.
//
// Planned spoken forms:
//   coma              -> ,
//   punto             -> .
//   signo de interrogacion / interrogacion -> ?
//   signo de exclamacion / exclamacion     -> !
//   punto y coma      -> ;
//   dos puntos        -> :
//

export function createSpanishTransformerSession(): TranscriptTransformerSession {
    return createNoopTransformerSession()
}
