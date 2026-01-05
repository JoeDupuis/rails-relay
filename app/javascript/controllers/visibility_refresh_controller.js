import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.boundRefresh = this.refresh.bind(this)
    document.addEventListener("visibilitychange", this.boundRefresh)
    this.refresh()
  }

  disconnect() {
    document.removeEventListener("visibilitychange", this.boundRefresh)
  }

  refresh() {
    if (document.visibilityState === "visible") {
      Turbo.visit(window.location.href, { action: "replace" })
    }
  }
}
