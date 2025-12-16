import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    interval: { type: Number, default: 30000 }
  }

  connect() {
    this.element.ison = this
    this.poll()
    this.startPolling()
    document.addEventListener("visibilitychange", this.handleVisibilityChange)
  }

  disconnect() {
    this.stopPolling()
    document.removeEventListener("visibilitychange", this.handleVisibilityChange)
  }

  handleVisibilityChange = () => {
    if (document.hidden) {
      this.stopPolling()
    } else {
      this.poll()
      this.startPolling()
    }
  }

  startPolling() {
    this.timer = setInterval(() => this.poll(), this.intervalValue)
  }

  stopPolling() {
    if (this.timer) {
      clearInterval(this.timer)
      this.timer = null
    }
  }

  async poll() {
    try {
      const response = await fetch("/ison", {
        headers: {
          "Accept": "text/vnd.turbo-stream.html"
        }
      })
      if (response.ok) {
        const html = await response.text()
        Turbo.renderStreamMessage(html)
      }
    } catch (error) {
      console.error("ISON poll failed:", error)
    }
  }
}
