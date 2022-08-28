# frozen_string_literal: true

module ApplicationHelper
  # "robin@example.com" -> "r****@example.com". Enough for someone to recognise
  # their own address on a page that anyone holding the link can open, without
  # spelling it out in full. The mask is a fixed width so it does not leak the
  # length of the address either.
  def masked_email(email)
    local, domain = email.to_s.split('@', 2)
    return email if domain.nil? || local.blank?

    "#{local[0]}****@#{domain}"
  end
end
