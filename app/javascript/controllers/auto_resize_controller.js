import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.needsJsResize = !CSS.supports("field-sizing", "content")
  }

  resize() {
    if (!this.needsJsResize) return

    this.element.style.height = "auto"
    this.element.style.height = this.element.scrollHeight + "px"
  }
}
