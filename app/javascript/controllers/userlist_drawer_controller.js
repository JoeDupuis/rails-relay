import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["drawer", "backdrop"]

  connect() {
    this.boundKeydown = this.handleKeydown.bind(this)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundKeydown)
  }

  open() {
    this.drawerTarget.classList.add("-open")
    this.backdropTarget.classList.add("-visible")
    document.body.style.overflow = "hidden"
    document.addEventListener("keydown", this.boundKeydown)
  }

  close() {
    this.drawerTarget.classList.remove("-open")
    this.backdropTarget.classList.remove("-visible")
    document.body.style.overflow = ""
    document.removeEventListener("keydown", this.boundKeydown)
  }

  backdropClick(event) {
    if (event.target === this.backdropTarget) {
      this.close()
    }
  }

  handleKeydown(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }
}
