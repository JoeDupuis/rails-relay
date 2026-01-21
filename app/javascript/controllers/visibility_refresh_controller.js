import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.boundRefresh = this.refresh.bind(this)
    document.addEventListener("visibilitychange", this.boundRefresh)
  }

  disconnect() {
    document.removeEventListener("visibilitychange", this.boundRefresh)
  }

  refresh() {
    if (document.visibilityState === "visible") {
      Turbo.session.refresh(window.location.href)
    }
  }
}
