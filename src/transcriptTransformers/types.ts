export type DotoolKeyChord = "ctrl+enter"

export type TranscriptCommand = { kind: "key"; chord: DotoolKeyChord }

export type TransformResult = {
    text: string
    commands: TranscriptCommand[]
}

export interface TranscriptTransformerSession {
    transform(rawText: string): TransformResult
    onSegmentFinalized(): TranscriptCommand[]
    reset(): void
}
