# frozen_string_literal: true

TOKEN_EXPIRY = 3
# typed: false
module SessionsHelper
  def sign_in(user)
    remember_token = User.new_token
    Rails.logger.info 'Assign RT: ' + remember_token
    if ENV['RAILS_ENV'] == 'production'
      cookies[:remember_token2] = { value: remember_token, expires: TOKEN_EXPIRY.month.from_now.utc, domain: 'ontheair.nz' }
    else
      cookies[:remember_token3] = { value: remember_token, expires: TOKEN_EXPIRY.month.from_now.utc, domain: 'ontheair.nz' }

    end
    UserToken.create(remember_token: User.digest(remember_token), user_id: user.id)
    self.current_user = user
    session[:user_id] = user.id
    flush_old_tokens(user)
  end

  def flush_old_tokens(user)
    uts=UserToken.where("user_id = #{user.id} and created_at < '#{TOKEN_EXPIRY.months.ago.strftime("%Y-%m-%d %H:%M")}'")
    uts.destroy_all
  end

  def sign_out
    @current_user_token.update_attribute(:remember_token,
                                  User.digest(User.new_token)) if @current_user_token
    if ENV['RAILS_ENV'] == 'production'
      cookies.delete(:remember_token2, domain: 'ontheair.nz')
    else
      cookies.delete(:remember_token3, domain: 'ontheair.nz')

    end
    self.current_user = nil
    self.current_user_token = nil
    session[:user_id] = nil
  end

  def signed_in?
    !current_user.nil?
  end

  def write_access?
    (!current_user.nil? && !current_user.read_only)
  end

  def current_user=(user)
    @current_user = user
  end

  def current_user_token=(user_token)
    @current_user_token = user_token
  end

  def current_user
    remember_token = if ENV['RAILS_ENV'] == 'production'
                       User.digest(cookies[:remember_token2])
                     else
                       User.digest(cookies[:remember_token3])
                     end
    user_token ||= UserToken.find_by(remember_token: remember_token)
    @current_user_token ||= user_token
    @current_user ||= User.find_by(id: user_token.user_id) if user_token
    @current_user
  end
end
