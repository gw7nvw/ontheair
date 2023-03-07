class UserMailer < ActionMailer::Base
  helper ApplicationHelper

  default from: "admin@ontheair.nz"

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.user_mailer.account_activation.subject
  #
  def account_activation(user)
    @user = user
    mail to: user.email, subject: "Account activation"
  end
  def award_notification(aul)
    @aul = aul
    mail to: aul.user.email, subject: "It looks like you qualify for a new QRP award"
  end

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.user_mailer.password_reset.subject
  #
  def password_reset(user)
    @user = user
    mail to: user.email, subject: "Password reset"
  end
  def address_auth(authlist)
    @authlist = authlist
    mail to: authlist.address, subject: "Address authentication"
  end

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.user_mailer.password_reset.subject
  #
  def new_password(user)
    @user = user
    mail to: user.email, subject: "Welcome to the ontheair.nz website"
  end

  def wwff_log_submission(user,park,filename,log,email)
    @user=user
    @park=park
    @address=email
    attachments[filename] = {:mime_type => 'text/plain',
                                   :content => log }
    mail from: "admin@ontheair.nz", to: @address, cc: user.email, bcc: "admin@ontheair.nz", subject: "WWFF log from "+user.callsign, reply_to: user.email
#    mail from: "admin@ontheair.nz", to: user.email, cc: user.email, bcc: "admin@ontheair.nz", subject: "WWFF log from "+user.callsign, reply_to: user.email
  end

  def pota_log_submission(user,park,logdate,filename,log,email)
    @user=user
    @park=park
    @logdate=logdate
    attachments[filename] = {:mime_type => 'text/plain',
                                   :content => log }
    mail from: "admin@ontheair.nz", to: email, cc: user.email, bcc: "admin@ontheair.nz", subject: "POTA log from "+user.callsign, reply_to: user.email
  end
  def subscriber_mail(item,user)
    @user=user
    @item=item 
    if @item.end_item.image_content_type then
      attachments['map.jpg'] = File.read(@item.end_item.image.path)
    end
    if user and user.email then
      if @item.end_item.callsign and @item.end_item.callsign.length>0 then callsign=@item.end_item.callsign.upcase else callsign=@item.end_item.updated_by_name end
      if item.topic.is_spot then
        mail to: user.email, subject: callsign+" spotted on "+(if (@item.end_item.freq and @item.end_item.freq.length>0) or (@item.end_item.mode and @item.end_item.mode.length>0) then @item.end_item.freq+" - "+@item.end_item.mode else "UNKNOWN" end)

      elsif item.topic.is_alert then
        mail to: user.email, subject: callsign+" alerted for "+(if @item.end_item.referenced_date then @item.end_item.referenced_date.strftime("%Y-%m-%d") else "" end)+" "+(if @item.end_item.referenced_time then @item.end_item.referenced_time.strftime("%H:%M (UTC)") else "" end)+" at "+(if @item.end_item.site then @item.end_item.site else "UNKNOWN" end)

      else
        mail to: user.email, subject: "ontheair.nz: New post from "+@item.end_item.updated_by_name+" in "+item.topic.name
      end
    end
  end

  def zlsota_mail(body, subject)
    @body=body
    puts "MAILER: sending :"+body
    mail from: "zl4nvw@ontheair.nz", to: "zl-sota@zl-sota.org", subject: subject
    #mail from: "zl4nvw@ontheair.nz", to: "mattbriggs@yahoo.com", subject: subject
  end

  def free_form_mail(to, from, subject, body)
     @to=to
     @from=from
     @subject=subject
     @body=body
     mail from: from, to: to, subject: subject
  end
end
