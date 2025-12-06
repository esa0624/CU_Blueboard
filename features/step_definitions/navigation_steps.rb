When('I click the header link {string}') do |link_text|
  within('.login-header') do
    click_link link_text
  end
end