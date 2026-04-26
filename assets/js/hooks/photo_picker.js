/**
 * PhotoPicker Hook - Opens Google Photos Picker in popup window
 *
 * Listens for postMessages from the picker origin — required for Google
 * to consider the opener window still alive while the picker is open.
 */
const PICKER_ORIGIN = "https://photos.google.com"

const PhotoPicker = {
  mounted() {
    this.messageListener = (event) => {
      if (event.origin !== PICKER_ORIGIN) return
    }
    window.addEventListener("message", this.messageListener)

    this.handleEvent("open_picker", ({ url }) => {
      const width = 600
      const height = 800
      const left = window.screenX + (window.outerWidth - width) / 2
      const top = window.screenY + (window.outerHeight - height) / 2

      const features = `width=${width},height=${height},left=${left},top=${top},status=no,menubar=no,toolbar=no`

      const pickerWindow = window.open(url, "GooglePhotosPicker", features)

      if (!pickerWindow) {
        alert("Please enable popups to select photos from Google Photos.")
        return
      }

      pickerWindow.focus()
    })
  },

  destroyed() {
    window.removeEventListener("message", this.messageListener)
  }
}

export default PhotoPicker
