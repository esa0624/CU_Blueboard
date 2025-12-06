When('I visit the moderation dashboard') do
  visit moderation_posts_path
end

When('I click "Review" for the post {string}') do |title|
  post = Post.find_by!(title: title)
  # Find the row or card for this post and click Review
  # Assuming a standard table or list structure
  within("#post-#{post.id}") do
    click_link 'Review'
  end
end

When('I click "Redact Answer" for the answer {string}') do |answer_body|
  answer = Answer.find_by!(body: answer_body)
  within("#answer-#{answer.id}") do
    click_button 'Redact Answer'
  end
end

When('I click "Unredact Answer" for the answer {string}') do |answer_body|
  answer = Answer.find_by!(body: answer_body)
  within("#answer-#{answer.id}") do
    click_button 'Unredact Answer'
  end
end

When('I select {string} from the redaction state') do |state|
  select state, from: 'redaction_state'
end

When('I fill in "Redaction Reason" with {string}') do |reason|
  fill_in 'redaction_reason', with: reason
end

When('I click "Redact Content"') do
  click_button 'Redact Content'
end

When('I click "Redact Answer"') do
  click_button 'Redact Answer'
end
