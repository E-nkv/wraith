export function initWSA() {
    console.log("initWSA script is running inside the browser!")

    const SpeechRec = window.SpeechRecognition || window.webkitSpeechRecognition

    if (!SpeechRec) {
        console.error("FATAL: Web Speech API is not supported in this browser context.")
        return
    }

    const rec = new SpeechRec()
    rec.continuous = true
    rec.interimResults = true
    rec.lang = "en-US"

    window.transcript = ""
    window.isIntentionalStop = true // Start in a paused state

    rec.onstart = () => console.log("Listening for audio...")

    rec.onresult = (event) => {
        let currentInterim = ""
        let currentFinal = ""

        for (let i = event.resultIndex; i < event.results.length; i++) {
            if (event.results[i].isFinal) {
                currentFinal += event.results[i][0].transcript
            } else {
                currentInterim += event.results[i][0].transcript
            }
        }

        if (currentFinal) {
            window.transcript += currentFinal
        }

        if (window.onSpeechUpdate) {
            window.onSpeechUpdate({
                totalText: window.transcript,
                interimResults: currentInterim,
            })
        }
    }

    rec.onerror = (event) => {
        console.error("Speech recognition error:", event.error)
    }

    rec.onend = () => {
        // If WSA dropped the mic due to silence, but the user didn't hit /stop, restart it!
        if (!window.isIntentionalStop) {
            console.log("Recognition ended unexpectedly (silence timeout). Restarting...")
            try {
                rec.start()
            } catch (e) {
                console.error("Failed to restart:", e)
            }
        } else {
            console.log("Recognition stopped intentionally.")
        }
    }

    // Attach to window so startListening/stopListening can access it
    window.recognition = rec
}

// These functions will be evaluated by Puppeteer when the Express routes are hit
export function startListening() {
    window.isIntentionalStop = false
    try {
        window.recognition.start()
    } catch (e) {
        console.log("err starting WSA: ", err)
    }
}

export function stopListening() {
    window.isIntentionalStop = true
    try {
        window.recognition.stop()
        window.transcript = ""
    } catch (e) {
        console.log("err closing WSA: ", err)
    }
}
