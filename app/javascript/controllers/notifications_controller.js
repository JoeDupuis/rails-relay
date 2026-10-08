import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

let pushSubscriptionSaved = false

export default class extends Controller {
  static values = { userId: Number, vapidPublicKey: String }
  static targets = ["badge"]

  connect() {
    this.setAppBadge(this.currentCount())
    this.requestPermission()
    this.subscribeToChannel()
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
  }

  async requestPermission() {
    if (!("Notification" in window)) return

    if (Notification.permission === "default") {
      await Notification.requestPermission()
    }

    if (Notification.permission === "granted") {
      this.subscribeToPush()
    }
  }

  async subscribeToPush() {
    if (pushSubscriptionSaved || !this.vapidPublicKeyValue) return
    if (!("serviceWorker" in navigator) || !("PushManager" in window)) return

    try {
      await navigator.serviceWorker.register("/service-worker.js")
      const registration = await navigator.serviceWorker.ready
      const subscription = await registration.pushManager.getSubscription() ||
        await registration.pushManager.subscribe({
          userVisibleOnly: true,
          applicationServerKey: this.decodeKey(this.vapidPublicKeyValue)
        })

      const response = await fetch("/push_subscriptions", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']")?.content
        },
        body: JSON.stringify(subscription.toJSON())
      })
      pushSubscriptionSaved = response.ok
    } catch (error) {
      console.warn("Push subscription failed", error)
    }
  }

  subscribeToChannel() {
    if (!this.userIdValue) return

    this.consumer = createConsumer()
    this.subscription = this.consumer.subscriptions.create(
      { channel: "NotificationsChannel" },
      {
        received: (data) => this.handleMessage(data)
      }
    )
  }

  handleMessage(data) {
    this.updateBadge(data.unread_count)

    if (data.type === "notification") {
      this.showBrowserNotification(data)
    }
  }

  currentCount() {
    if (!this.hasBadgeTarget) return 0
    return parseInt(this.badgeTarget.textContent || "0")
  }

  updateBadge(count) {
    if (count === undefined) return

    if (this.hasBadgeTarget) {
      this.badgeTarget.textContent = count
      this.badgeTarget.classList.toggle("-hidden", count === 0)
    }
    this.setAppBadge(count)
  }

  setAppBadge(count) {
    if (!("setAppBadge" in navigator)) return

    if (count > 0) {
      navigator.setAppBadge(count).catch(() => {})
    } else {
      navigator.clearAppBadge().catch(() => {})
    }
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

  decodeKey(key) {
    const base64 = (key + "=".repeat((4 - key.length % 4) % 4)).replace(/-/g, "+").replace(/_/g, "/")
    return Uint8Array.from(atob(base64), (char) => char.charCodeAt(0))
  }
}
