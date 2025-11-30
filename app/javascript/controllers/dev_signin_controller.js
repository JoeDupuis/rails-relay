import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { email: String, password: String }

  signIn(event) {
    event.preventDefault()

    const form = this.element.closest("form").cloneNode(true)
    form.querySelector('input[name="email_address"]').value = this.emailValue
    form.querySelector('input[name="password"]').value = this.passwordValue
    document.body.appendChild(form)
    form.submit()
  }
}
