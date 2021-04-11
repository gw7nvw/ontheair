class UserMailer < ActionMailer::Base
  helper ApplicationHelper

  default from: "qrp_nz@qrp.nz"

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
    mail to: user.email, subject: "Welcome to the QRPers NZ Group website"
  end

  def membership_request(user,email)
     @user=user
     @email=email
     mail to: @email, subject: "New QRPers NZ membership request via qrp.nz website"
  end

  def membership_request_notification(user, email)
     @user=user
     @email=email
     mail to: @user.email, subject: "Your QRPers NZ membership request"
  end

  def wwff_log_submission(user,park,filename,log,email)
    @user=user
    @park=park
    @address=email
    attachments[filename] = {:mime_type => 'text/plain',
                                   :content => log }
    mail from: "admin@qrp.nz", to: user.email, bcc: "admin@qrp.nz", subject: "WWFF log from "+user.callsign, reply_to: user.email
  end

  def pota_log_submission(user,park,logdate,filename,log,email)
    @user=user
    @park=park
    @logdate=logdate
    attachments[filename] = {:mime_type => 'text/plain',
                                   :content => log }
    mail from: "admin@qrp.nz", to: email, bcc: "admin@qrp.nz", subject: "POTA log from "+user.callsign, reply_to: user.email
  end
  def subscriber_mail(item,user)
    @user=user
    @item=item
    if user and user.email then
      mail to: user.email, subject: "QRP.NZ: New post from "+@item.end_item.updated_by_name+" in your followed topics"
    end
  end

end
