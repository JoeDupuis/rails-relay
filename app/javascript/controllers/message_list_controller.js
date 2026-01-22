import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["messages", "container", "newIndicator", "loadingIndicator"]
  static values = {
    channelId: Number,
    conversationId: Number,
    historyUrl: String,
    hasMore: Boolean,
    oldestId: Number
  }

  connect() {
    this.atBottom = true
    this.isLoading = false
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
        if (this.isNearTop() && this.hasMoreValue && !this.isLoading) {
          this.loadMoreMessages()
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

  isNearTop() {
    if (!this.hasMessagesTarget) return false
    return this.messagesTarget.scrollTop < 100
  }

  async loadMoreMessages() {
    if (!this.hasHistoryUrlValue || !this.oldestIdValue) return

    this.isLoading = true
    this.showLoadingIndicator()

    const previousScrollHeight = this.messagesTarget.scrollHeight
    const previousScrollTop = this.messagesTarget.scrollTop

    try {
      const url = `${this.historyUrlValue}?before_id=${this.oldestIdValue}`
      const response = await fetch(url, {
        headers: {
          "Accept": "text/html",
          "X-Requested-With": "XMLHttpRequest"
        }
      })

      if (!response.ok) throw new Error("Failed to load messages")

      const html = await response.text()
      const template = document.createElement("template")
      template.innerHTML = html

      const meta = template.content.querySelector("[data-history-meta]")
      if (meta) {
        this.hasMoreValue = meta.dataset.hasMore === "true"
        const newOldestId = parseInt(meta.dataset.oldestId, 10)
        if (newOldestId) {
          this.oldestIdValue = newOldestId
        }
        meta.remove()
      }

      if (this.hasContainerTarget && template.content.children.length > 0) {
        this.containerTarget.prepend(...template.content.children)

        const heightDifference = this.messagesTarget.scrollHeight - previousScrollHeight
        this.messagesTarget.scrollTop = previousScrollTop + heightDifference
      }
    } catch (error) {
      console.error("Error loading more messages:", error)
    } finally {
      this.isLoading = false
      this.hideLoadingIndicator()
    }
  }

  showLoadingIndicator() {
    if (this.hasLoadingIndicatorTarget) {
      this.loadingIndicatorTarget.classList.remove("-hidden")
    }
  }

  hideLoadingIndicator() {
    if (this.hasLoadingIndicatorTarget) {
      this.loadingIndicatorTarget.classList.add("-hidden")
    }
  }

  observeNewMessages() {
    if (!this.hasContainerTarget) return

    const observer = new MutationObserver((mutations) => {
      for (const mutation of mutations) {
        if (mutation.type === "childList" && mutation.addedNodes.length > 0) {
          const addedAtEnd = Array.from(mutation.addedNodes).some(node => {
            return node === this.containerTarget.lastElementChild
          })
          if (addedAtEnd) {
            this.messageAdded()
          }
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
