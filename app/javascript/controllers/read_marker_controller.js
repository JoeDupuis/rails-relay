import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "dividerTemplate"]
  static values = { url: String }

  connect() {
    this.observer = new MutationObserver((mutations) => this.messagesAdded(mutations))
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

  messagesAdded(mutations) {
    if (this.isWatching()) {
      this.markAsRead()
      return
    }

    const message = mutations
      .flatMap(mutation => Array.from(mutation.addedNodes))
      .find(node => node.classList?.contains("message-item"))
    if (message && !this.dividerPlaced) this.placeDivider(message)
  }

  placeDivider(message) {
    if (!this.hasDividerTemplateTarget) return

    this.containerTarget.querySelectorAll(".unread-divider").forEach(divider => divider.remove())
    message.before(this.dividerTemplateTarget.content.cloneNode(true))
    this.dividerPlaced = true
  }

  markAsRead = () => {
    if (!this.isWatching()) return

    this.dividerPlaced = false

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
