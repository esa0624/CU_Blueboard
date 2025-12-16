import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="advanced-search"
export default class extends Controller {
  static targets = ["panel", "toggleButton", "chevron"]

  connect() {
    // Check if any filters are active and open panel automatically
    this.checkActiveFilters()
  }

  toggle(event) {
    event.preventDefault()

    const isHidden = this.panelTarget.style.display === 'none' || !this.panelTarget.style.display

    if (isHidden) {
      this.open()
    } else {
      this.close()
    }
  }

  open() {
    this.panelTarget.style.display = 'block'
    this.toggleButtonTarget.classList.add('active')
    if (this.hasChevronTarget) {
      this.chevronTarget.style.transform = 'rotate(180deg)'
    }
  }

  close() {
    this.panelTarget.style.display = 'none'
    this.toggleButtonTarget.classList.remove('active')
    if (this.hasChevronTarget) {
      this.chevronTarget.style.transform = 'rotate(0deg)'
    }
  }

  checkActiveFilters() {
    // Check URL parameters for active filters (excluding search query 'q')
    const params = new URLSearchParams(window.location.search)
    const filterKeys = ['filters[topic_id]', 'filters[status]', 'filters[school]',
                       'filters[course_code]', 'filters[timeframe]', 'filters[tag_ids][]']

    const hasFilters = filterKeys.some(key => {
      const value = params.get(key)
      return value && value.trim() !== ''
    })

    // Auto-open panel if filters are active
    if (hasFilters) {
      this.open()
    }
  }
}
