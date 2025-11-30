import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar"]

  toggle() {
    this.sidebarTarget.classList.toggle("-open")
  }

  close() {
    this.sidebarTarget.classList.remove("-open")
  }
}
