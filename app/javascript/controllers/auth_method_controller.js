import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["passwordField"]

  connect() {
    this.toggle()
  }

  toggle() {
    const select = this.element.querySelector("select")
    const showPassword = select.value !== "none"
    this.passwordFieldTarget.style.display = showPassword ? "block" : "none"
  }
}
