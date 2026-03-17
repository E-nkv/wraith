// @ts-nocheck
export function initWSA() {
  console.log("initWSA script is running inside the browser!");

  const SpeechRec = window.SpeechRecognition || window.webkitSpeechRecognition;

  if (!SpeechRec) {
    console.error(
      "FATAL: Web Speech API is not supported in this browser context.",
    );
    return;
  }

  window.recognition = new SpeechRec();
  window.recognition.continuous = true;
  window.recognition.interimResults = true;
  window.recognition.lang = "en-US";

  window.transcript = ""; // Initialize the variable

  // Add lifecycle logs so we can see exactly what the mic is doing
  window.recognition.onstart = () =>
    console.log("Microphone is HOT! Waiting for audio...");
  window.recognition.onaudiostart = () =>
    console.log("Audio pipeline connected.");
  window.recognition.onspeechstart = () =>
    console.log("Human speech detected!");

  window.recognition.onresult = (event) => {
    let currentInterim = "";
    let currentFinal = "";

    for (let i = event.resultIndex; i < event.results.length; i++) {
      if (event.results[i].isFinal) {
        currentFinal += event.results[i][0].transcript;
      } else {
        currentInterim += event.results[i][0].transcript;
      }
    }

    // Append finalized text to our global buffer
    if (currentFinal) {
      window.transcript += currentFinal;
    }

    console.log(
      `[STT] Interim: "${currentInterim}" | Final Buffer: "${window.transcript}"`,
    );
  };

  window.recognition.onerror = (event) => {
    console.error("Speech recognition error:", event.error);
  };

  window.recognition.onend = () => {
    console.log("Recognition ended. Restarting...");
    try {
      window.recognition.start();
    } catch (e) {
      console.error("Failed to restart:", e);
    }
  };

  // Start recognition
  window.recognition.start();
}
