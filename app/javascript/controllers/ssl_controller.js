import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["verifyField"]

  connect() {
    this.toggle()
  }

  toggle() {
    const checkbox = this.element.querySelector("input[type='checkbox'][name*='ssl]']")
    const showVerify = checkbox?.checked
    this.verifyFieldTarget.style.display = showVerify ? "block" : "none"
  }
}
