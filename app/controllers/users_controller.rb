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
      @contacts=Contact.find_by_sql [ "select id, callsign1, callsign2, location1, location2 from contacts where (callsign1='"+@user.callsign+"' or callsign2='"+@user.callsign+"')" ]
    end

  end

  def new
    @user = User.new

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

    # Don't mark membership requested until T&Cs accepted on next screen 
    membership_requested=user.membership_requested
    if !existing_user then @user.membership_requested=false end

    if @user.save
      @user.reload
      sign_in @user

      flash[:success] = "Welcome to the Huts on the Air"
      if membership_requested then
        redirect_to 'http://qrp.nz/qrpnzmembers/new?referring=hota'
      else
        redirect_to '/users/'+@user.callsign
      end
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
        puts "got password"
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


#editgrid handlers

  def data
            users = User.all.order(:callsign)

            render :json => {
                 :total_count => users.length,
                 :pos => 0,
                 :rows => users.map do |user|
                 {
                   :id => user.id,
                   :data => [user.id,user.callsign,user.firstname,user.lastname,user.email,user.is_admin,user.is_modifier, user.is_active, user.activated, user.membership_confirmed]
                 }
                 end
            }
  end

def db_action
  if signed_in? and current_user.is_admin then
    @mode = params["!nativeeditor_status"]
    id = params['c0']
    callsign = params['c1']
    firstname = params['c2']
    lastname = params['c3']
    email = params['c4']
    is_admin = params['c5']
    is_modifier = params['c6']
    is_active = params['c7']
    activated = params['c8']
    membership_confirmed = params['c9']

    @id = params["gr_id"]

    case @mode

    when "inserted"
        user = User.create :callsign => callsign, :firstname => firstname,:lastname => lastname, :email => email, :is_admin => is_admin, :is_modifier => is_modifier, :is_active => is_active, :activated => activated, :membership_confirmed => membership_confirmed
       if user then
          @tid = user.id
       else
          @mode="error"
          @tid=nil
       end


    when "deleted"
        if User.find(@id).destroy then
          @tid = @id
        else
          @mode="error"
          @tid=nil
       end

   when "updated"
        @user = User.find(@id)
        @user.callsign = callsign
        @user.firstname = firstname
        @user.lastname = lastname
        @user.email = email
        @user.is_admin = is_admin
        @user.is_modifier = is_modifier
        @user.is_active = is_active
        @user.activated = activated
        @user.membership_confirmed = membership_confirmed
        if !@user.save then @mode="error" end

        @tid = @id
    end
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

  private

    def user_params
      params.require(:user).permit(:callsign, :firstname, :lastname, :email, :timezone, :membership_requested, :membership_confirmed, :home_qth)
    end


end
