# frozen_string_literal: true

# The one thing a subscriber ever sees. The subject is deliberately quiet: this
# arrives unprompted in the inbox of someone who may be having a hard day, and
# an exclamation mark is the wrong tone for that.
class MessageMailer < ApplicationMailer
  SUBJECT = 'A note for you'

  def new_message_email
    @subscriber = params[:subscriber]
    @message = params[:message]
    @unsubscribe_url = unsubscribe_url(@subscriber.unsubscribe_token)

    # RFC 2369 / RFC 8058: lets the mail client offer its own "Unsubscribe"
    # button, which POSTs straight to the same endpoint the footer link opens.
    headers['List-Unsubscribe'] = "<#{@unsubscribe_url}>"
    headers['List-Unsubscribe-Post'] = 'List-Unsubscribe=One-Click'

    mail(to: @subscriber.email, subject: SUBJECT)
  end
end
