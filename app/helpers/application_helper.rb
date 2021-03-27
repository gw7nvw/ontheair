module ApplicationHelper
  def sign_in(user)
    remember_token = User.new_token
    cookies[:remember_token] = {value: remember_token, expires: 1.month.from_now.utc}
    user.update_attribute(:remember_token, User.digest(remember_token))
    self.current_user = user
    session[:user_id]=user.id
  end

end
