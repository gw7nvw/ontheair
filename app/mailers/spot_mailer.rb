require "base64"

class SpotMailer < ApplicationMailer
  def alert(email, subject, html_body, text_body, image_base64)
    if image_base64.present?
      attachments.inline["map.jpg"] = {
        mime_type: "image/jpeg",
        content: Base64.strict_decode64(image_base64),
        cid: "map.jpg"
      }
    end

    mail(from: "admin@ontheair.nz", to: email, subject: subject) do |format|
      format.html { render html: html_body.html_safe }
      format.text { render plain: text_body }
    end
  end
end
