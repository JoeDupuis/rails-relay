class ServersController < ApplicationController
  before_action :set_server, only: %i[show edit update destroy]

  def index
    @servers = Server.all
  end

  def show
  end

  def new
    @server = Server.new
  end

  def create
    @server = Server.new(server_params)
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
    @server = Server.find(params[:id])
  end

  def server_params
    params.require(:server).permit(:address, :port, :ssl, :nickname, :username, :realname, :auth_method, :auth_password)
  end
end
