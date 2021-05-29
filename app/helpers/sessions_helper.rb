module SessionsHelper

  def sign_in(user)
    remember_token = User.new_token
    Rails.logger.info "Assign RT: "+remember_token
if ENV["RAILS_ENV"] == "production" then
    cookies[:remember_token2] = {value: remember_token, expires: 1.month.from_now.utc, domain: 'ontheair.nz'}
 else
    cookies[:remember_token3] = {value: remember_token, expires: 1.month.from_now.utc, domain: 'ontheair.nz'}

end
    user.update_attribute(:remember_token2, User.digest(remember_token))
    self.current_user = user
    session[:user_id]=user.id
  end

  def sign_out
    current_user.update_attribute(:remember_token2,
                                  User.digest(User.new_token))
if ENV["RAILS_ENV"] == "production" then
    cookies.delete(:remember_token2, domain: 'ontheair.nz')
else
    cookies.delete(:remember_token3, domain: 'ontheair.nz')

end
    self.current_user = nil
    session[:user_id]=nil

  end

  def signed_in?
    !current_user.nil?
  end
  def current_user=(user)
    @current_user = user
  end

  def current_user
if ENV["RAILS_ENV"] == "production" then
    remember_token = User.digest(cookies[:remember_token2])
else
    remember_token = User.digest(cookies[:remember_token3])
end
    @current_user ||= User.find_by(remember_token2: remember_token)
  end
end

