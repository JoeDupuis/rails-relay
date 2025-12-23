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
  }

  preventEmptySubmit(event) {
    if(this.inputTarget.value == "" && this.fileInputTarget.files.length === 0) {
      event.preventDefault()
    }
  }

  preventShiftSubmit(event) {
    if (event.key === 'Enter' && event.shiftKey) {
      event.preventDefault()
    }
  }

  submit() {
    this.element.requestSubmit()
  }
}
