class ChallengesController < ApplicationController
  # Skip the authentication filters that triggered the redirect in the first place
  skip_before_action :authenticate_user!, raise: false 

  def show
    # Generate a secure token and save it in the session for verification
    @verification_token = SecureRandom.hex(16)
    session[:human_challenge_token] = @verification_token
    
    # Store the original URL they were trying to access so we can redirect them back
    session[:challenge_return_to] = params[:referreing_url] || root_path
  end

  # HIT BY THE REAL VISIBLE LINK
  def verify
    if session[:human_challenge_token].present? && params[:id] == session[:human_challenge_token]
      # Clear the session token token
      session[:human_challenge_token] = nil
      
      # Reset the suspicious tracker counters in the database for this IP
      request_ip = request.remote_ip
      user_agent = request.user_agent || 'Unknown'
      UserAgent.where(user_ip: request_ip, user_agent: user_agent).update_all(
        access_count: 0,
        suspicious_access_count: 0,
        suspected_bot: false,
        confirmed_bot: false,
        confirmed_human: true,
        updated_at: Time.now
      )

      # Send the validated human back to their original destination
      redirect_to session.delete(:challenge_return_to)
    else
      show
      render 'show'
    end
  end

  # HIT BY ANY OF THE 49 INVISIBLE LINKS
  def trap
    render_trap
  end

  private

  def render_trap
    request_ip = request.remote_ip
    user_agent = request.user_agent || 'Unknown'

    # Instantly tag them as a malicious bot in the DB
    # You can add a boolean column like `is_blocked: true` to your user_agents table
    UserAgent.where(user_ip: request_ip, user_agent: user_agent).update_all(
      confirmed_bot: true,
      updated_at: Time.now
    )

    # Force clear their session so they lose any state
    reset_session

    # Render a lightweight 404 or send them straight to a static error layout
    render text: "Not Found", status: :not_found
  end
end

