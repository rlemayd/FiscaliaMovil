class Admin::CrimesController < ApplicationController
  before_action :set_crime, only: [:edit, :update, :destroy]
  before_action :authenticate_admin!

  def index
    @crimes = Crime.all
  end

  # GET /people/new
  def new
    @crime = Crime.new
  end

  # GET /people/1/edit
  def edit
  end

  # POST /people
  # POST /people.json
  def create
    x = Crime.all.pluck(:id).sort[-1] + 1
    @crime = Crime.new(id: x, name: crime_params["name"])
    respond_to do |format|
      if @crime.save
        format.html { redirect_to admin_crimes_path, notice: 'Crime was successfully created.' }
      else
        format.html { render :new }
      end
    end
  end

  # PATCH/PUT /people/1
  # PATCH/PUT /people/1.json
  def update
    respond_to do |format|
      if @crime.update(crime_params)
        format.html { redirect_to admin_crimes_path, notice: 'Crime was successfully updated.' }
      else
        format.html { render :edit }
      end
    end
  end

  # DELETE /people/1
  # DELETE /people/1.json
  def destroy
    @crime.destroy
    respond_to do |format|
      format.html { redirect_to admin_crimes_path, notice: 'Crime was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_crime
    @crime= Crime.find(params[:id])
  end
  # Only allow a list of trusted parameters through.
  def crime_params
    params.require(:crime).permit(:name)
  end

end