class Admin::LocalProsecutionsController < ApplicationController
  load_and_authorize_resource except: [:create]
  before_action :set_admin_local_prosecution, only: [:edit, :update, :destroy]
  before_action :authenticate_admin!

  # GET /admin/local_prosecutions
  # GET /admin/local_prosecutions.json
  def index
    @local_prosecutions = LocalProsecution.not_deleted
  end

  # GET /admin/local_prosecutions/new
  def new
    @local_prosecution = LocalProsecution.new
  end

  # GET /admin/local_prosecutions/1/edit
  def edit
  end

  # POST /admin/local_prosecutions
  # POST /admin/local_prosecutions.json
  def create
    x = LocalProsecution.all.pluck(:id).sort[-1] + 1
    @local_prosecution = LocalProsecution.new(id: x, name: admin_local_prosecution_params["name"], regional_prosecution_id: admin_local_prosecution_params["regional_prosecution_id"].to_i)

    respond_to do |format|
      if @local_prosecution.save
        format.html { redirect_to admin_local_prosecutions_path, notice: 'Fiscalía Local ha sido creada con éxito.' }
      else
        format.html { render :new }
      end
    end
  end

  # PATCH/PUT /admin/local_prosecutions/1
  # PATCH/PUT /admin/local_prosecutions/1.json
  def update
    respond_to do |format|
      if @local_prosecution.update(admin_local_prosecution_params)
        if params["viene"]
          format.html { redirect_to admin_local_prosecutions_path, notice: 'Fiscalía Local ha sido actualizada con éxito.' }
        else
          format.html { redirect_to admin_prosecutors_path, notice: 'Fiscalía Local ha sido actualizada con éxito.' }
        end
      else
        format.html { render :edit }
      end
    end
  end

  # DELETE /admin/local_prosecutions/1
  # DELETE /admin/local_prosecutions/1.json
  def destroy
    #@local_prosecution.destroy
    @local_prosecution.soft_delete
    @local_prosecution.user.soft_delete
    @local_prosecution.prosecutors.each { |pros|
      pros.soft_delete
      pros.user.soft_delete
    }
    respond_to do |format|
      format.html { redirect_to admin_local_prosecutions_url, notice: 'Fiscalía Local ha sido eliminada con éxito.' }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_admin_local_prosecution
      @local_prosecution = LocalProsecution.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def admin_local_prosecution_params
      params.fetch(:local_prosecution, {}).permit(:name, :regional_prosecution_id)
    end
end
