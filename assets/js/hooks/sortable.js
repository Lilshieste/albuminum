/**
 * Sortable Hook - Native HTML5 Drag and Drop for LiveView
 * Works with grid layouts by considering both X and Y position
 */
const Sortable = {
  mounted() {
    this.draggedEl = null

    // Make all children with data-sortable-id draggable
    this.el.querySelectorAll("[data-sortable-id]").forEach(item => {
      this.setupDraggable(item)
    })

    this.el.addEventListener("dragover", e => {
      e.preventDefault()
      e.dataTransfer.dropEffect = "move"

      const target = this.getDropTarget(e.clientX, e.clientY)
      if (target && target !== this.draggedEl) {
        const rect = target.getBoundingClientRect()
        const midX = rect.left + rect.width / 2

        // Insert before or after based on horizontal position
        if (e.clientX < midX) {
          target.parentNode.insertBefore(this.draggedEl, target)
        } else {
          target.parentNode.insertBefore(this.draggedEl, target.nextSibling)
        }
      }
    })

    this.el.addEventListener("drop", e => {
      e.preventDefault()
      this.pushNewOrder()
    })
  },

  updated() {
    this.el.querySelectorAll("[data-sortable-id]").forEach(item => {
      if (!item.draggable) {
        this.setupDraggable(item)
      }
    })
  },

  setupDraggable(item) {
    item.draggable = true
    item.style.cursor = "grab"

    item.addEventListener("dragstart", e => {
      this.draggedEl = item
      item.classList.add("dragging")
      item.style.opacity = "0.4"
      e.dataTransfer.effectAllowed = "move"
      e.dataTransfer.setData("text/plain", item.dataset.sortableId)
    })

    item.addEventListener("dragend", e => {
      item.classList.remove("dragging")
      item.style.opacity = "1"
      this.draggedEl = null
    })
  },

  // Find which sortable item the cursor is over
  getDropTarget(x, y) {
    const items = [...this.el.querySelectorAll("[data-sortable-id]:not(.dragging)")]

    for (const item of items) {
      const rect = item.getBoundingClientRect()
      if (x >= rect.left && x <= rect.right && y >= rect.top && y <= rect.bottom) {
        return item
      }
    }
    return null
  },

  pushNewOrder() {
    const ids = [...this.el.querySelectorAll("[data-sortable-id]")]
      .map(item => parseInt(item.dataset.sortableId))

    this.pushEvent("reorder", { ids: ids })
  }
}

export default Sortable
