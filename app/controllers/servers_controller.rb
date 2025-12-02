class ServersController < ApplicationController
  before_action :set_server, only: %i[show edit update destroy]

  def index
    @servers = Current.user.servers
  end

  def show
    @channels = @server.channels.includes(:channel_users).order(:name)
    @server_messages = @server.messages
                              .where(channel_id: nil, target: nil)
                              .order(created_at: :desc)
                              .limit(100)
  end

  def new
    @server = Current.user.servers.build
  end

  def create
    @server = Current.user.servers.build(server_params)
    if @server.save
      redirect_to @server
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @server.update(server_params)
      redirect_to @server
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @server.destroy
    redirect_to servers_path
  end

  private

  def set_server
    @server = Current.user.servers.find(params[:id])
  end

  def server_params
    params.require(:server).permit(:address, :port, :ssl, :ssl_verify, :nickname, :username, :realname, :auth_method, :auth_password)
  end
end
