import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["audio", "toggle"]

  connect() {
    // Check if the user previously enabled sound in this browser
    this.soundEnabled = localStorage.getItem("audio_alerts_enabled") === "true"
    this.updateToggleUI()
  }

  // Triggered when user clicks the "Enable Sound" button/checkbox
  toggleSound(event) {
    this.soundEnabled = event.target.checked
    localStorage.setItem("audio_alerts_enabled", this.soundEnabled)

    if (this.soundEnabled) {
      this.unlockAudio()
    }
  }

  // Pre-unlocks the audio asset via user interaction
  unlockAudio() {
    this.audioTarget.play()
      .then(() => {
        // Pause and reset immediately; it was just to satisfy the browser policy
        this.audioTarget.pause()
        this.audioTarget.currentTime = 0
        console.log("Audio engine successfully unlocked for this session.")
      })
      .catch(error => {
        console.warn("Audio unlock failed:", error)
      })
  }

  // This method is called whenever your AJAX/Turbo refresh adds a new alert
  playAlert(event) {
    if (!this.soundEnabled) return

    // Rewind to start if it's already playing, then play
    this.audioTarget.currentTime = 0
    
    this.audioTarget.play().catch(error => {
      // Catching prevents unhandled promise rejection errors in console
      console.error("Playback prevented by browser autoplay policy:", error)
      // Optional: Fallback to a visual toast notification if audio fails
    })
  }

  updateToggleUI() {
    if (this.toggleTarget) {
      this.toggleTarget.checked = this.soundEnabled
    }
  }
}
