import puppeteer from "puppeteer";
import { initWSA } from "./wsa.js";

async function initBrowser() {
  const browser = await puppeteer.launch({
    executablePath: "/usr/bin/google-chrome-stable",
    //@ts-ignore
    headless: "new", // CRITICAL: Use the "new" headless mode, not true/false
    args: [
      "--use-fake-ui-for-media-stream", // CRITICAL: Auto-grants microphone permission
      "--disable-background-timer-throttling",
      // "--no-sandbox", // Uncomment ONLY if Wayland throws a strict sandbox error
    ],
  });

  const page = await browser.newPage();

  // CRITICAL DEBUGGING: Pipe browser console logs to your Node terminal
  page.on("console", (msg) => console.log("[Browser]", msg.text()));

  // Web Speech API sometimes fails on 'about:blank'.
  // We navigate to a dummy local HTML string to give it a proper secure context.
  await page.goto(
    "data:text/html,<html><body><h1>STT Injector</h1></body></html>",
  );

  return { browser, page };
}

async function main() {
  const { browser, page } = await initBrowser();

  console.log("Injecting Web Speech API...");

  // FIX: Pass the function reference directly. Puppeteer will serialize and execute it.
  await page.evaluate(initWSA);

  console.log("Listening for 10 seconds... Speak into your microphone!");

  // Wait 10 seconds to give you time to speak
  await new Promise((resolve) => setTimeout(resolve, 10000));

  //@ts-ignore
  // Retrieve the transcript
  const transcript = await page.evaluate(() => window.transcript || "");

  console.log("\n--- FINAL RESULT ---");
  console.log("Transcribed text:", transcript);
  console.log("--------------------\n");

  await browser.close();
  console.log("Browser closed.");
}

main().catch(console.error);
