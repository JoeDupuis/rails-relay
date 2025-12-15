import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  signIn(event) {
    event.preventDefault()

    const button = event.currentTarget
    const form = this.element.closest("form").cloneNode(true)
    form.querySelector('input[name="email_address"]').value = button.dataset.email
    form.querySelector('input[name="password"]').value = button.dataset.password
    document.body.appendChild(form)
    form.submit()
  }
}
