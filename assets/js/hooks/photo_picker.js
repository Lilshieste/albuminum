/**
 * PhotoPicker Hook - Opens Google Photos Picker in popup window
 */
const PhotoPicker = {
  mounted() {
    this.handleEvent("open_picker", ({ url }) => {
      const width = 600
      const height = 800
      const left = window.screenX + (window.outerWidth - width) / 2
      const top = window.screenY + (window.outerHeight - height) / 2

      const features = `width=${width},height=${height},left=${left},top=${top},status=no,menubar=no,toolbar=no`

      const pickerWindow = window.open(url, "GooglePhotosPicker", features)

      if (pickerWindow) {
        pickerWindow.focus()
      } else {
        alert("Please enable popups to select photos from Google Photos.")
      }
    })
  }
}

export default PhotoPicker
