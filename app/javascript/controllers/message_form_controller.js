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
    if (this.hasFileInputTarget && this.fileInputTarget.files.length > 0) {
      this.fileInputTarget.value = ""
      if (this.hasMessageListOutlet) {
        this.messageListOutlet.sent()
      }
      return
    }

    this.inputTarget.value = ""
    this.saveDraft()
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

  paste(event) {
    if (!this.hasFileInputTarget) return

    const data = event.clipboardData
    if (!data || data.files.length === 0 || data.types.includes("text/plain")) return

    event.preventDefault()
    this.#uploadFile(data.files[0])
  }

  dragEnter(event) {
    if (!this.#draggingFiles(event)) return

    event.preventDefault()
    this.dragDepth = (this.dragDepth || 0) + 1
    this.element.classList.add("-dropping")
  }

  dragOver(event) {
    if (!this.#draggingFiles(event)) return

    event.preventDefault()
    event.dataTransfer.dropEffect = "copy"
  }

  dragLeave(event) {
    if (!this.#draggingFiles(event)) return

    this.dragDepth = Math.max((this.dragDepth || 0) - 1, 0)
    if (this.dragDepth === 0) this.element.classList.remove("-dropping")
  }

  drop(event) {
    if (!this.#draggingFiles(event)) return

    event.preventDefault()
    this.dragDepth = 0
    this.element.classList.remove("-dropping")

    const file = event.dataTransfer.files[0]
    if (file) this.#uploadFile(file)
  }

  #uploadFile(file) {
    const transfer = new DataTransfer()
    transfer.items.add(file)
    this.fileInputTarget.files = transfer.files
    this.submit()
  }

  #draggingFiles(event) {
    return this.hasFileInputTarget && event.dataTransfer && Array.from(event.dataTransfer.types).includes("Files")
  }

  preventFocusLoss(event) {
    event.preventDefault()
  }

  get draftKey() {
    return `message-draft:${new URL(this.element.action).pathname}`
  }
}
