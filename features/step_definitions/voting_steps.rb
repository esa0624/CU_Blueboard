When('I click the upvote button on the answer {string}') do |answer_body|
  answer = Answer.find_by!(body: answer_body)
  within("#answer-#{answer.id}") do
    find('.btn-upvote').click
  end
end

When('I click the downvote button on the answer {string}') do |answer_body|
  answer = Answer.find_by!(body: answer_body)
  within("#answer-#{answer.id}") do
    find('.btn-downvote').click
  end
end

Then('I should see the answer {string} has {int} upvote') do |answer_body, count|
  answer = Answer.find_by!(body: answer_body)
  within("#answer-#{answer.id}") do
    expect(find('.vote-score-compact')).to have_content(count)
  end
end

Then('I should see the answer {string} has {int} downvote') do |answer_body, count|
  answer = Answer.find_by!(body: answer_body)
  within("#answer-#{answer.id}") do
    # Assuming net score display
    expect(find('.vote-score-compact')).to have_content("-#{count}")
  end
end

When('I click the upvote button on the comment {string}') do |comment_body|
  comment = AnswerComment.find_by!(body: comment_body)
  within("#comment-#{comment.id}") do
    find('.btn-upvote').click
  end
end

Then('I should see the comment {string} has {int} upvote') do |comment_body, count|
  comment = AnswerComment.find_by!(body: comment_body)
  within("#comment-#{comment.id}") do
    expect(find('.vote-score-micro')).to have_content(count)
  end
end
