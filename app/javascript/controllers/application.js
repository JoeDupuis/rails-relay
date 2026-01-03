import { Application } from "@hotwired/stimulus"

const application = Application.start()

application.debug = false
window.Stimulus   = application

const setAppHeight = () => {
  const height = window.visualViewport?.height || window.innerHeight
  document.documentElement.style.setProperty('--app-height', `${height}px`)
}

setAppHeight()
window.addEventListener('load', setAppHeight)
window.visualViewport?.addEventListener('resize', setAppHeight)

export { application }
