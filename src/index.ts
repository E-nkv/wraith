import puppeteer from "puppeteer"
import { initWSA, startListening, stopListening } from "./browser.js"
import express, { type Express } from "express"

process.title = "Wraith-server"
const PORT = process.env.PORT || 3232

class Daemon {
    private browser: puppeteer.Browser | null = null
    private page: puppeteer.Page | null = null
    private isListening: boolean = false
    private app: Express
    private port: string | number

    constructor(port: string | number) {
        this.port = port
        this.app = express()
        this.setupRoutes()
    }

    private setupRoutes() {
        this.app.get("/start", async (req, res) => {
            if (!this.page) {
                this.log("page not ready")
                return
            }
            if (this.isListening) {
                this.log("Already listening.")
                return
            }
            this.log("Starting transcription...")
            this.isListening = true
            await this.page.evaluate(startListening)
        })

        this.app.get("/stop", async (req, res) => {
            if (!this.page) {
                this.log("page not ready")
                return
            }
            if (!this.isListening) {
                this.log("cannot call stop before start")
                return
            }
            this.log("Stopping transcription...")
            this.isListening = false
            await this.page.evaluate(stopListening)
        })
    }

    private log(message?: any, ...optionalParams: any[]) {
        console.log(`[DAEMON]`, message, ...optionalParams)
    }

    private async initBrowser() {
        this.browser = await puppeteer.launch({
            executablePath: "/usr/bin/google-chrome-stable",
            //@ts-ignore
            headless: "new",
            args: [
                "--use-fake-ui-for-media-stream",
                "--disable-background-timer-throttling",
                "--user-data-dir=/tmp/stt-chrome-profile",
                "--log-level=0",
                "--disable-dev-shm-usage",
                "--disable-gpu",
                "--disable-software-rasterizer",
                "--disable-background-networking",
                "--disable-default-apps",
                "--disable-extensions",
                "--disable-sync",
                "--disable-translate",
                "--metrics-recording-only",
                "--no-first-run",
                "--safebrowsing-disable-auto-update",
                "--disable-features=IsolateOrigins,site-per-process",
            ],
            name: "Wraith-browser",
        })

        this.page = await this.browser.newPage()
        this.page.on("console", (msg) => console.log("[BROWSER]", msg.text()))

        await this.page.goto("data:text/html,<html><body><h1>Wraith</h1></body></html>")
        await this.page.exposeFunction("onSpeechUpdate", this.handleSpeechUpdate.bind(this))
        await this.page.evaluate(initWSA)
    }

    private async handleSpeechUpdate(payload: { totalText: string; interimResults: string }) {
        console.log(`\n[DAEMON] Total: "${payload.totalText}", Interim: "${payload.interimResults}"`)
    }

    public async start() {
        await this.initBrowser()

        this.app.listen(this.port, () => {
            this.log(`SERVER STARTED ON PORT: ${this.port}`)
        })
    }
}

const daemon = new Daemon(PORT)
daemon.start().catch(console.error)
