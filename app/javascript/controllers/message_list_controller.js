import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["messages", "container", "newIndicator"]
  static values = { channelId: Number }

  connect() {
    this.atBottom = true
    this.scrollToBottom()
    this.observeScroll()
    this.observeNewMessages()
  }

  scrollToBottom() {
    if (this.hasMessagesTarget) {
      this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
    }
  }

  observeScroll() {
    if (this.hasMessagesTarget) {
      this.messagesTarget.addEventListener("scroll", () => {
        this.atBottom = this.isAtBottom()
        if (this.atBottom) {
          this.hideNewIndicator()
        }
      })
    }
  }

  hideNewIndicator() {
    if (this.hasNewIndicatorTarget) {
      this.newIndicatorTarget.classList.add("-hidden")
    }
  }

  isAtBottom() {
    if (!this.hasMessagesTarget) return true
    const el = this.messagesTarget
    return el.scrollHeight - el.scrollTop - el.clientHeight < 50
  }

  observeNewMessages() {
    if (!this.hasContainerTarget) return

    const observer = new MutationObserver((mutations) => {
      for (const mutation of mutations) {
        if (mutation.type === "childList" && mutation.addedNodes.length > 0) {
          this.messageAdded()
        }
      }
    })

    observer.observe(this.containerTarget, { childList: true })
  }

  messageAdded() {
    if (this.atBottom) {
      this.scrollToBottom()
    } else {
      this.showNewIndicator()
    }
  }

  showNewIndicator() {
    if (this.hasNewIndicatorTarget) {
      this.newIndicatorTarget.classList.remove("-hidden")
    }
  }

  scrollToNew() {
    this.scrollToBottom()
    this.atBottom = true
    this.hideNewIndicator()
  }

  sent() {
    this.scrollToNew()
  }
}
