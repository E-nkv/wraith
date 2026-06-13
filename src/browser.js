export function initWSA(stream, lang) {
    console.log("browser connected. initializing Web Speech API...")

    const SpeechRec = window.SpeechRecognition || window.webkitSpeechRecognition
    if (!SpeechRec) {
        console.error("FATAL: Web Speech API is not supported in this browser context.")
        throw new Error("FATAL: Web Speech API is not supported in this browser context.")
    }

    const rec = new SpeechRec()
    rec.continuous = true
    if (stream) {
        rec.interimResults = true
    }
    rec.lang = lang !== undefined ? lang : "en-US"

    rec.onstart = () => {
        console.log("Listening...")
        rec.isRunning = true
    }

    let finalText = ""
    rec.onresult = (event) => {
        let interimText = ""
        let finalizedText = ""
        let segmentFinalized = false
        for (let i = event.resultIndex; i < event.results.length; i++) {
            if (!event.results[i].isFinal) {
                interimText += event.results[i][0].transcript
            } else {
                const chunk = event.results[i][0].transcript
                finalText += chunk
                finalizedText += chunk
                segmentFinalized = true
            }
        }
        if (stream) {
            if (segmentFinalized) {
                // Final results are not in interimText; emit them before finalization
                // so inline transforms (e.g. "new line") apply on the committed chunk.
                if (finalizedText) {
                    window.onSpeechEvent({ kind: "text", text: finalizedText })
                }
                window.onSpeechEvent({ kind: "segment-finalized" })
            }
            if (interimText) {
                window.onSpeechEvent({ kind: "text", text: interimText })
            }
        } else {
            if (segmentFinalized) {
                if (finalizedText) {
                    window.onSpeechEvent({ kind: "text", text: finalizedText })
                }
                window.onSpeechEvent({ kind: "segment-finalized" })
            }
        }
    }

    //onerror happens always before onend.
    rec.onerror = (event) => {
        if (event.error === "network") window.isOffline = true
        else throw new Error(`unexpected recognition error: ${event.error}`)
    }

    rec.onend = () => {
        // if recognition was stopped normally, onBrowserRecStop is a no-op since the daemon.isWSAListening is already FALSE
        window.onBrowserRecStop({ reason: window.isOffline ? "offline" : "silence" })
        //clear state
        finalText = ""
        rec.isRunning = false
        window.isOffline = undefined
    }

    window.recognition = rec
}

export function startListening() {
    if (!window.recognition) {
        const message = "rec not initialized"
        console.error(message)
        return
    }
    try {
        window.recognition.start()
    } catch (e) {
        const message = `Error starting rec: ${e.message || e}`
        console.error(message)
    }
}

export function setLangAndStart(lang) {
    if (!window.recognition) {
        console.error("rec not initialized")
        return
    }
    try {
        window.recognition.lang = lang
        window.recognition.start()
    } catch (e) {
        console.error(`Error setting lang and starting rec: ${e.message || e}`)
    }
}

export function stopRecognition() {
    if (!window.recognition) {
        const message = "rec not initialized"
        console.error(message)
        return
    }

    try {
        window.recognition.stop()
    } catch (e) {
        const message = `Error stopping rec: ${e.message || JSON.stringify(e)}`
        console.error(message)
    }
}

export function healthCheck() {
    return "ok"
}
