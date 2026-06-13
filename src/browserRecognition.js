// Pure WSA result → speech-event mapping. Tested via browserRecognition.test.ts.
// Inlined inside initWSA in browser.js for Chrome injection (page.evaluate cannot bundle imports).
// SYNC: must match the inner recognitionResultsToEvents in browser.js — see tests/browserRecognition.sync.test.ts.

/**
 * @param {boolean} stream
 * @param {number} resultIndex
 * @param {Array<{ isFinal: boolean; 0: { transcript: string } }>} results
 */
export function recognitionResultsToEvents(stream, resultIndex, results) {
    let interimText = ""
    let finalizedText = ""
    let segmentFinalized = false

    for (let i = resultIndex; i < results.length; i++) {
        if (!results[i].isFinal) {
            interimText += results[i][0].transcript
        } else {
            finalizedText += results[i][0].transcript
            segmentFinalized = true
        }
    }

    const events = []

    if (stream) {
        if (segmentFinalized) {
            if (finalizedText) {
                events.push({ kind: "text", text: finalizedText })
            }
            events.push({ kind: "segment-finalized" })
        }
        if (interimText) {
            events.push({ kind: "text", text: interimText })
        }
    } else if (segmentFinalized) {
        if (finalizedText) {
            events.push({ kind: "text", text: finalizedText })
        }
        events.push({ kind: "segment-finalized" })
    }

    return events
}
