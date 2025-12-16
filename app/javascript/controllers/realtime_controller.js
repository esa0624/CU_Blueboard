import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

// Realtime updates controller for post pages
// Handles: new answer notifications, typing indicators
export default class extends Controller {
  static targets = ["answers", "typingIndicator", "answerForm"]
  static values = { postId: Number }

  connect() {
    if (!this.hasPostIdValue) return

    this.setupPostChannel()
    this.setupTypingChannel()
    this.setupTypingDetection()
  }

  disconnect() {
    if (this.postSubscription) {
      this.postSubscription.unsubscribe()
    }
    if (this.typingSubscription) {
      this.typingSubscription.unsubscribe()
    }
    this.clearTypingTimeout()
  }

  setupPostChannel() {
    this.postSubscription = consumer.subscriptions.create(
      { channel: "PostChannel", post_id: this.postIdValue },
      {
        received: (data) => this.handlePostUpdate(data)
      }
    )
  }

  setupTypingChannel() {
    this.typingSubscription = consumer.subscriptions.create(
      { channel: "TypingChannel", post_id: this.postIdValue },
      {
        received: (data) => this.handleTypingUpdate(data)
      }
    )
  }

  setupTypingDetection() {
    if (!this.hasAnswerFormTarget) return

    const textarea = this.answerFormTarget.querySelector('textarea')
    if (!textarea) return

    this.typingTimeout = null
    this.isTyping = false

    textarea.addEventListener('input', () => {
      this.sendTypingStatus(true)
      this.clearTypingTimeout()
      this.typingTimeout = setTimeout(() => {
        this.sendTypingStatus(false)
      }, 2000)
    })

    textarea.addEventListener('blur', () => {
      this.sendTypingStatus(false)
      this.clearTypingTimeout()
    })
  }

  sendTypingStatus(typing) {
    if (this.isTyping === typing) return
    this.isTyping = typing

    if (this.typingSubscription) {
      this.typingSubscription.perform('typing', {
        post_id: this.postIdValue,
        typing: typing
      })
    }
  }

  clearTypingTimeout() {
    if (this.typingTimeout) {
      clearTimeout(this.typingTimeout)
      this.typingTimeout = null
    }
  }

  handlePostUpdate(data) {
    if (data.action === 'new_answer' && this.hasAnswersTarget) {
      // Insert new answer HTML
      this.answersTarget.insertAdjacentHTML('beforeend', data.html)
      // Flash highlight effect
      const newAnswer = this.answersTarget.lastElementChild
      if (newAnswer) {
        newAnswer.classList.add('answer-highlight')
        setTimeout(() => newAnswer.classList.remove('answer-highlight'), 3000)
      }
      // Show notification
      this.showNotification('New answer posted!')
    }
  }

  handleTypingUpdate(data) {
    if (data.action === 'typing' && this.hasTypingIndicatorTarget) {
      if (data.typing) {
        this.typingIndicatorTarget.textContent = `${data.user} is typing...`
        this.typingIndicatorTarget.style.display = 'block'
      } else {
        this.typingIndicatorTarget.style.display = 'none'
      }
    }
  }

  showNotification(message) {
    // Create a temporary notification
    const notification = document.createElement('div')
    notification.className = 'realtime-notification'
    notification.textContent = message
    document.body.appendChild(notification)

    setTimeout(() => {
      notification.classList.add('fade-out')
      setTimeout(() => notification.remove(), 500)
    }, 3000)
  }
}
