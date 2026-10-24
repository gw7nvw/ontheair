class MigrationMailer < ActionMailer::Base
  # Set the "From" address and name
  default from: "ontheair <admin@ontheair.nz>"

  def send_notice(filename, user_email)
    # Read the static HTML file from the public folder
    html_content = File.read(Rails.root.join("public", filename))

    mail(
      to: user_email,
      subject: "Upcoming changes at ParksNPeaks.org",
      body: html_content,
      content_type: 'text/html'
    )
  end
end
