# frozen_string_literal: true

# The one thing a subscriber ever sees. The subject is deliberately quiet: this
# arrives unprompted in the inbox of someone who may be having a hard day, and
# an exclamation mark is the wrong tone for that.
class MessageMailer < ApplicationMailer
  SUBJECT = 'A note for you'

  def new_message_email
    @subscriber = params[:subscriber]
    @message = params[:message]
    mail(to: @subscriber.email, subject: SUBJECT)
  end
end
