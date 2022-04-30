class UsersController < ApplicationController

  before_action :signed_in_user, only: [:edit, :update, :editgrid]

  def editgrid

  end

  def index_prep
    whereclause="true"
    if params[:filter] then
      @filter=params[:filter]
      whereclause="is_"+@filter+" is true"
    end

    @users=User.find_by_sql [ 'select * from users where '+whereclause+' order by callsign' ]
  end


  def index
    index_prep()
    respond_to do |format|
      format.html
      format.js
      format.csv { send_data users_to_csv(@users), filename: "users-#{Date.today}.csv" }
    end
  end

  def show
    if(!(@user = User.where(callsign: params[:id]).first))
      redirect_to '/'
    else 
      @contacts=Contact.find_by_sql [ "select * from contacts where (callsign1='"+@user.callsign+"' or callsign2='"+@user.callsign+"')" ]
      activationsSites1=Contact.find_by_sql [ " select distinct location1 from contacts where callsign1='#{@user.callsign}';" ];
      activationsSites2=Contact.find_by_sql [ " select distinct location2 as location1 from contacts where callsign2='#{@user.callsign}';" ];
      chaseSites1=Contact.find_by_sql [ " select distinct location2 as location1 from contacts where callsign1='#{@user.callsign}';" ];
      chaseSites2=Contact.find_by_sql [ " select distinct location1 from contacts where callsign2='#{@user.callsign}';" ];
      @activationSites=activationsSites1+activationsSites2
      @chaseSites=chaseSites1+chaseSites2
      as=SotaActivation.find_by_sql [ "select * from sota_activations where callsign='"+@user.callsign+"'" ]

      as=SotaActivation.find_by_sql [ "select * from sota_activations where callsign='"+@user.callsign+"'" ]
      as.each do |a|
        c=Contact.new
        c.callsign1=a.callsign
        c.callsign2=""
        c.date=a.date
        c.time=a.date
        asset=Asset.find_by(code: a.summit_code)
        c.location1=asset.location
        @contacts.push(c)
      end
    end

  end

  def new
    @user = User.new
    @user.timezone=Timezone.find_by(name: 'UTC').id
  end

 def create
    password=params[:user][:password]
    password_confirmation=params[:user][:password_confirmation]

    user = User.new(user_params)
    user.password=password
    user.password_confirmation=password_confirmation

    user.callsign=user.callsign.strip
    existing_user=User.find_by(callsign: user.callsign.upcase)



    #register an auto_created user 
    if existing_user and not existing_user.activated then
      @user=existing_user 
    else 
      @user=user
    end
    @user.callsign=user.callsign
    @user.firstname=user.firstname.strip
    @user.lastname=user.lastname.strip
    @user.email=user.email.strip
    @user.activated=true
    @user.is_active=true
    @user.is_modifier=false
    @user.activated_at=Time.now()

    if !@user.valid_callsign? then
      @user.read_only=true
    end

    if @user.save
      @user.reload
      sign_in @user

      if @user.read_only then
        flash[:success]="Welcome to ZL on the Air. Your account has been created as a restricted, non-amatuer user. Contact admin@ontheair if you expected full access"
      else
        flash[:success] = "Welcome to ZL On the Air"
      end

      redirect_to '/users/'+@user.callsign
    else
#      key = OpenSSL::PKey::RSA.new(1024)
#      @public_modulus  = key.public_key.n.to_s(16)
#      @public_exponent = key.public_key.e.to_s(16)
#      session[:key] = key.to_pem

      render 'new'
    end
end

def edit
   if params[:referring] then @referring=params[:referring] end
   if !@user then @user = User.where(callsign: params[:id]).first end

   if signed_in? and (current_user.is_admin or current_user.callsign == params[:id]) then

   else 
     render 'show'
   end
end

def update
 if signed_in? and (current_user.is_admin or current_user.id == params[:id].to_i) then
   if params[:commit]=="Delete" then
      user = User.find_by_id(params[:id].to_i)
      if user and user.destroy then
        flash[:success] = "User deleted, callsign:"+params[:id]
        index_prep()
        render 'index'
      else
        edit()
        render 'edit'
      end
    else
           password=params[:user][:password]
           password_confirmation=params[:user][:password_confirmation]

      @user = User.find_by_id(params[:id].to_i)

      @user.assign_attributes(user_params)
      if password and password.length>0 then
        @user.password=password
        @user.password_confirmation=password_confirmation
      end

      if @user then 
        if @user.firstname then @user.firstname=@user.firstname.strip end
        if @user.lastname then @user.lastname=@user.lastname.strip end
        @user.callsign=@user.callsign.strip
        if @user.email then @user.email=@user.email.strip end

        #only allow us to change own password unless we are admin
        if @user.id != current_user.id and not current_user.is_admin then
            @user.password=nil
            @user.password_confirmation=nil
        end
  
        if @user.save
          flash[:success] = "User details updated"
  
          # Handle a successful update.
          if params[:referring]=='index' then
            index_prep()
            render 'index'
          else
            render 'show'
          end
        else
          if params[:referring] then @referring=params[:referring] end
          key = OpenSSL::PKey::RSA.new(1024)
          @public_modulus  = key.public_key.n.to_s(16)
          @public_exponent = key.public_key.e.to_s(16)
          session[:key] = key.to_pem

          render 'edit'
        end
      end
   end
  else
    redirect_to '/'
  end

end


  def users_to_csv(items)
    if signed_in? and current_user.is_admin then
      require 'csv'
      csvtext=""
      if items and items.first then
        columns=[]; items.first.attributes.each_pair do |name, value| if !name.include?("password") and !name.include?("digest") and !name.include?("token") then columns << name end end
        csvtext << columns.to_csv
        items.each do |item|
           fields=[]; item.attributes.each_pair do |name, value| if !name.include?("password") and !name.include?("digest") and !name.include?("token") then fields << value end end
           csvtext << fields.to_csv
        end
     end
     csvtext
   end
  end

  def add
  @user=current_user
  if current_user and current_user.is_admin or current_user.group_admin then @user = User.where(callsign: params[:id]).first end
  @topic=Topic.find_by_id(params[:topic_id])

  if @user and @topic then
    utl=UserTopicLink.new
    utl.user_id=@user.id
    utl.topic_id=@topic.id
    utl.mail=true
    utl.save
  else
    flash[:error] = "Error locating user or topic specified"
  end
  @topics=Topic.where(is_active=true)
  render 'show'

  end

  def delete
  @user=current_user
  if current_user and current_user.is_admin then @user = User.where(callsign: params[:id]).first end
  @topic=Topic.find_by_id(params[:topic_id])

  if @user and @topic then
    utls=UserTopicLink.find_by_sql [ "select * from user_topic_links where user_id="+@user.id.to_s+" and topic_id="+@topic.id.to_s ]
    utls.each do |utl|
     utl.destroy
    end
  else
    flash[:error] = "Error locating user or topic specified"
  end
  @topics=Topic.where(is_active=true)
  render 'show'
end

  private

    def user_params
      params.require(:user).permit(:callsign, :firstname, :lastname, :email, :timezone, :home_qth, :pin)
    end


end
