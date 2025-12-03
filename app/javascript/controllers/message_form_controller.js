import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "fileInput"]
  static values = { uploadUrl: String, channelName: String }
  static outlets = ["message-list"]

  submit(event) {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      this.element.requestSubmit()
      this.notifyMessageList()
    }
  }

  formSubmit() {
    this.notifyMessageList()
  }

  notifyMessageList() {
    if (this.hasMessageListOutlet) {
      this.messageListOutlet.sent()
    }
  }

  upload(event) {
    const file = event.target.files[0]
    if (!file) return

    const formData = new FormData()
    formData.append("file", file)

    this.inputTarget.placeholder = "Uploading..."
    this.inputTarget.disabled = true

    fetch(this.uploadUrlValue, {
      method: "POST",
      body: formData,
      headers: {
        "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
      }
    })
    .then(response => {
      if (!response.ok) {
        return response.json().then(data => { throw new Error(data.error || "Upload failed") })
      }
      return response.json()
    })
    .then(() => {
      this.inputTarget.placeholder = `Message ${this.channelNameValue}`
      this.inputTarget.disabled = false
    })
    .catch(error => {
      alert(error.message)
      this.inputTarget.placeholder = `Message ${this.channelNameValue}`
      this.inputTarget.disabled = false
    })

    event.target.value = ""
  }
}
