# frozen_string_literal: true

# The page behind the link at the foot of every note, and the target of the
# RFC 8058 one-click `List-Unsubscribe-Post` that mail providers send.
#
# GET only shows a confirmation, because link scanners and mail previewers
# fetch URLs on their own and must not unsubscribe anybody. POST does the work.
# The token in the URL is the credential, so the POST carries no CSRF token: a
# mail provider's one-click request could not supply one.
class UnsubscribesController < ApplicationController
  skip_forgery_protection only: :create

  before_action :set_subscriber

  def show; end

  def create
    @subscriber.update!(is_active: false) if @subscriber.is_active
    render :done
  end

  private

  def set_subscriber
    @subscriber = Subscriber.find_by(unsubscribe_token: params[:token].to_s)
    render :invalid, status: :not_found if @subscriber.nil?
  end
end
