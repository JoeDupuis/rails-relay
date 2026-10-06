import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container"]
  static values = { url: String }

  connect() {
    this.observer = new MutationObserver(() => this.markAsRead())
    if (this.hasContainerTarget) {
      this.observer.observe(this.containerTarget, { childList: true })
    }
    window.addEventListener("focus", this.markAsRead)
    document.addEventListener("visibilitychange", this.markAsRead)
  }

  disconnect() {
    this.observer.disconnect()
    window.removeEventListener("focus", this.markAsRead)
    document.removeEventListener("visibilitychange", this.markAsRead)
    clearTimeout(this.timer)
  }

  markAsRead = () => {
    if (!this.isWatching()) return

    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.send(), 100)
  }

  isWatching() {
    return document.visibilityState === "visible" && document.hasFocus()
  }

  send() {
    if (!this.isWatching()) return

    fetch(this.urlValue, {
      method: "POST",
      headers: { "X-CSRF-Token": this.csrfToken() },
      credentials: "same-origin"
    }).catch(() => {})
  }

  csrfToken() {
    return document.querySelector("meta[name='csrf-token']")?.content
  }
}
