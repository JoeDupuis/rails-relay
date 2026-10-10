self.addEventListener("install", () => self.skipWaiting())

self.addEventListener("activate", (event) => {
  event.waitUntil(self.clients.claim())
})

self.addEventListener("push", (event) => {
  const { title, options, badge } = event.data.json()

  event.waitUntil(Promise.all([
    self.registration.showNotification(title, options),
    setBadge(badge)
  ]))
})

self.addEventListener("notificationclick", (event) => {
  event.notification.close()
  const url = new URL(event.notification.data.path, self.location.origin).href
  event.waitUntil(openApp(url))
})

async function setBadge(count) {
  if (!("setAppBadge" in self.navigator)) return

  if (count > 0) {
    await self.navigator.setAppBadge(count)
  } else {
    await self.navigator.clearAppBadge()
  }
}

async function openApp(url) {
  const windows = await self.clients.matchAll({ type: "window", includeUncontrolled: true })
  const client = windows[0]

  if (!client) return self.clients.openWindow(url)

  await client.focus()
  try {
    await client.navigate(url)
  } catch {
    await self.clients.openWindow(url)
  }
}
