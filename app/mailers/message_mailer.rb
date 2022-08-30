# frozen_string_literal: true

class MessageMailer < ApplicationMailer
  def new_message_email
    @subscriber = params[:subscriber]
    @message = params[:message]
    mail(to: @subscriber.email, subject: 'You got a new message!')
  end
end
