import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "fileInput"]
  static values = { uploadUrl: String, channelName: String }
  static outlets = ["message-list"]

  connect() {
    this.boundRestoreDraft = this.restoreDraft.bind(this)
    document.addEventListener("turbo:morph", this.boundRestoreDraft)
    this.restoreDraft()
  }

  disconnect() {
    document.removeEventListener("turbo:morph", this.boundRestoreDraft)
  }

  saveDraft() {
    try {
      const value = this.inputTarget.value
      if (value === "") {
        localStorage.removeItem(this.draftKey)
      } else {
        localStorage.setItem(this.draftKey, value)
      }
    } catch {}
  }

  restoreDraft() {
    let draft = null
    try {
      draft = localStorage.getItem(this.draftKey)
    } catch {}
    if (!draft || this.inputTarget.value === draft) return

    this.inputTarget.value = draft
    this.inputTarget.dispatchEvent(new Event("input"))
  }

  clearInput(event) {
    this.inputTarget.value = ""
    this.saveDraft()
    if (this.hasFileInputTarget) {
      this.fileInputTarget.value = ""
    }
    if (this.hasMessageListOutlet) {
      this.messageListOutlet.sent()
    }
    this.inputTarget.dispatchEvent(new Event("input"))
  }

  preventEmptySubmit(event) {
    const hasContent = this.inputTarget.value.trim() !== ""
    const hasFile = this.hasFileInputTarget && this.fileInputTarget.files.length > 0

    if (!hasContent && !hasFile) {
      event.preventDefault()
    }
  }

  handleKeydown(event) {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      this.element.requestSubmit()
    }
  }

  submit() {
    this.element.requestSubmit()
  }

  preventFocusLoss(event) {
    event.preventDefault()
  }

  get draftKey() {
    return `message-draft:${new URL(this.element.action).pathname}`
  }
}
