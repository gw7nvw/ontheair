class EmailService
  Payload = Struct.new(:subject, :html_body, :text_body, keyword_init: true)

  # Call ONCE outside (or lazily inside) the loop
  def self.prepare_payload(summary, asset_names, message_url, comment)
    assigns = {
      summary: summary,
      asset_names: asset_names,
      message_url: message_url,
      comment: comment
    }

    html_body = ApplicationController.render(
      template: "spot_mailer/alert",
      layout: "mailer",
      assigns: assigns
    )

    text_body = ApplicationController.render(
      template: "spot_mailer/alert",
      formats: [:text],
      layout: "mailer",
      assigns: assigns
    )

    Payload.new(subject: summary, html_body: html_body, text_body: text_body)
  end

  # Fast non-blocking enqueue inside the loop
  def self.send_alert(user, payload, image_base64)
    return if user.email.blank?

    SpotMailer.alert(
      user.email,
      payload.subject,
      payload.html_body,
      payload.text_body,
      image_base64
    ).deliver_later
  end
end
