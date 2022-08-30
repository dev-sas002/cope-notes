# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: 'example@test.com'
  layout 'mailer'
end
