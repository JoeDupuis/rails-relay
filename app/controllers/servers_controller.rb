class ServersController < ApplicationController
  def index
    @servers = Server.all
  end

  def new
    @server = Server.new
  end

  def create
    @server = Server.new(server_params)
    if @server.save
      redirect_to servers_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def server_params
      params.require(:server).permit(:address, :port, :ssl, :nickname, :username, :realname, :auth_method, :auth_password)
    end
end
