import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

export default class extends Controller {
  static values = { userId: Number }
  static targets = ["badge"]

  connect() {
    this.requestPermission()
    this.subscribeToChannel()
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
  }

  requestPermission() {
    if ("Notification" in window && Notification.permission === "default") {
      Notification.requestPermission()
    }
  }

  subscribeToChannel() {
    if (!this.userIdValue) return

    this.consumer = createConsumer()
    this.subscription = this.consumer.subscriptions.create(
      { channel: "NotificationsChannel" },
      {
        received: (data) => this.handleNotification(data)
      }
    )
  }

  handleNotification(data) {
    this.updateBadge()
    this.showBrowserNotification(data)
  }

  updateBadge() {
    if (!this.hasBadgeTarget) return

    const badge = this.badgeTarget
    const count = parseInt(badge.textContent || "0") + 1
    badge.textContent = count
    badge.classList.remove("-hidden")
  }

  showBrowserNotification(data) {
    if (Notification.permission !== "granted") return

    const title = data.reason === "dm"
      ? `DM from ${data.sender}`
      : `${data.sender} in ${data.channel}`

    new Notification(title, {
      body: data.preview,
      tag: `notification-${data.id}`,
      requireInteraction: true
    })
  }
}
