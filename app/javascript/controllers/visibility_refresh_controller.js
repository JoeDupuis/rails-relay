import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    if (document.visibilityState === "visible") {
      Turbo.visit(window.location.href, { action: "replace" })
    }
  }
}
