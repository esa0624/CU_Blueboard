import { Controller } from "@hotwired/stimulus"

// 连接到 HTML 中的 data-controller="post-show"
export default class extends Controller {

  // 1. 定义这个 controller 需要操作的 "目标" (target)
  static targets = [ "answerForm", "blurredContent", "appealOverlay" ]

  // 2. Toggle answer form visibility
  toggleAnswerForm() {
    this.answerFormTarget.classList.toggle('visible');
  }

  // 3. Show content when user appeals (remove blur)
  showContent(event) {
    event.preventDefault()

    if (this.hasBlurredContentTarget && this.hasAppealOverlayTarget) {
      this.blurredContentTarget.classList.remove('blurred')
      this.appealOverlayTarget.style.display = 'none'
    }
  }

  // 4. Toggle comment form for specific answer
  toggleCommentForm(event) {
    event.preventDefault()
    const answerId = event.currentTarget.dataset.answerId
    const form = document.getElementById(`comment-form-${answerId}`)
    if (form) {
      form.style.display = form.style.display === 'none' ? 'block' : 'none'
    }
  }
}
