import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "fileInput"]
  static values = { uploadUrl: String, channelName: String }
  static outlets = ["message-list"]

  clearInput(event) {
    this.inputTarget.value = ""
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
}
