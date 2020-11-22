class ProceduresController < ApplicationController
  load_and_authorize_resource :except => [:create]
  before_action :set_procedure, only: [:show, :edit, :update, :destroy]
  include ProceduresHelper

  # GET /procedures
  # GET /procedures.json
  def index
    if current_user.prosecutor.present?
      @pagy, @procedures = pagy(Procedure.where(:state => 0, :local_prosecution_in_charge_id => current_user.prosecutor.local_prosecution.id).or(Procedure.where(:state => 2, :creator_id => current_user.id, :local_prosecution_in_charge_id => current_user.prosecutor.local_prosecution.id)).order(created_at: :desc))
    elsif current_user.police_unit.present?
      @pagy, @procedures = pagy(Procedure.where(:state => 2, :creator_id => current_user.id, :police_unit_in_charge_id => current_user.police_unit.id).order(created_at: :desc))
    elsif current_user.admin?
      @procedures = []
    end
  end

  # GET /procedures/1
  # GET /procedures/1.json
  def show
    #save list with all accuseds person of the procedure
    accuseds_in_procedure = @procedure.person_in_procedures.where(role: 0)
    @accuseds = []
    accuseds_in_procedure.each do |accused|
      @accuseds.append([Person.find(accused.person_id), accused.state, accused.id])
    end
    #save list with all victims person of the procedure
    victims_in_procedure = @procedure.person_in_procedures.where(role: 2)
    @victims = []
    victims_in_procedure.each do |victim|
      @victims.append([Person.find(victim.person_id), victim.witness_declaration])
    end

    #save list with all witnesses person of the procedure
    witnesses_in_procedure = @procedure.person_in_procedures.where(role: 1)
    @witnesses = []
    witnesses_in_procedure.each do |witness|
      @witnesses.append([Person.find(witness.person_id), witness.witness_declaration])
    end
  end

  # GET /procedures/new
  def new
    @procedure = Procedure.new
    get_regiones
  end

  # GET /procedures/1/edit
  def edit
  end

  # POST /procedures
  # POST /procedures.json
  def create
    authorize! :create, Procedure

    if procedure_params[:classification] == "ODP"
      classification_procedure = 1

    elsif procedure_params[:classification] == "Flagrancia"
      classification_procedure = 0
    else
      classification_procedure = 2
    end

    selected_region = ""
    selected_sector = ""

    get_regiones

    @regiones.each do |region|
      if region[:codigo].to_s == procedure_params[:region].to_s
        selected_region = region[:nombre]
      end
      region[:comunas].each do |comuna|
        if comuna[:codigo].to_s == procedure_params[:sector].to_s
          selected_sector = comuna[:nombre]
        end
      end
    end


    d = procedure_params[:date].to_date
    t = procedure_params[:time].to_time


    dateOfArrest = DateTime.new(d.year, d.month, d.day, t.hour, t.min, t.sec, t.zone)


    @procedure = Procedure.new(classification: classification_procedure,
                               creator: current_user,
                               police_in_charge: PoliceMan.find(procedure_params[:police_in_charge]),
                               police_unit_in_charge: PoliceUnit.find(procedure_params[:police_unit_in_charge]),
                               prosecutor_in_charge: Prosecutor.find(procedure_params[:prosecutor_in_charge]),
                               local_prosecution_in_charge: LocalProsecution.find(procedure_params[:prosecution_in_charge]),
                               story: procedure_params[:story],
                               address: procedure_params[:address],
                               sector: selected_sector,
                               region: selected_region,
                               state: procedure_params[:state].to_i,
                               date_of_arrest: dateOfArrest,
                               involves_deceased: procedure_params[:involves_deceased]
                               )
    respond_to do |format|
      if @procedure.save!

        procedure_params[:tag_ids][1..procedure_params[:tag_ids].size].each do |tag|
          @tag = Tagging.new(tag: Tag.find_by_name(tag),
                             procedure: @procedure)
          @tag.save
        end

        procedure_params[:accuseds].each do |accused|
          @criminal = Person.new(name: accused[:name],
                               rut: accused[:rut])
          if @criminal.save!
            @criminal_in_procedure = PersonInProcedure.new(role: 0,
                                                           person: @criminal,
                                                           procedure: @procedure)
            @criminal_in_procedure.save
            @criminal_alias = AliasAccused.new(alias: accused[:alias],
                                           person: @criminal)
            @criminal_alias.save
            if procedure_params[:crimes]
              procedure_params[:crimes].each do |crime|
                @crime_in_accused = CrimeInAccused.new(preponderant: false,
                                                       crime: Crime.find_by_name(crime),
                                                       person: @criminal,
                                                       procedure: @procedure)
                @crime_in_accused.save
              end
            end

            @preponderan_crime_in_accused = CrimeInAccused.new(preponderant: true,
                                                               crime: Crime.find_by_name(procedure_params[:preponderant_crime]),
                                                               person: @criminal,
                                                               procedure: @procedure)
            @preponderan_crime_in_accused.save
          end
        end

        if procedure_params[:victims]
          procedure_params[:victims].each do |victim|
            @victim = Person.new(name: victim[:name],
                                 rut: victim[:rut],
                                 deceased: victim[:deceased],
                                 contact: victim[:contact]
            )
            if @victim.save!
              @victim_in_procedure = PersonInProcedure.new(role: 2,
                                                           person: @victim,
                                                           procedure: @procedure,
                                                           witness_declaration: victim[:story])
              @victim_in_procedure.save
            end
          end
        end


        if procedure_params[:witness]
          procedure_params[:witness].each do |witness|
            @witness = Person.new(name: witness[:name],
                                  rut: witness[:rut],
                                  contact: witness[:contact]
            )
            if @witness.save!
              @witness_in_procedure = PersonInProcedure.new(role: 1,
                                                            person: @witness,
                                                            procedure: @procedure,
                                                            witness_declaration: witness[:story])
              @witness_in_procedure.save
            end
          end
        end

        format.html { redirect_to @procedure, notice: 'Procedure was successfully created.' }
        format.json { render :show, status: :created, location: @procedure }
      else
        format.html { render :new }
        format.json { render json: @procedure.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /procedures/1
  # PATCH/PUT /procedures/1.json
  def update
    #byebug
    respond_to do |format|
      $aux = @procedure.state
      if @procedure.update(state: params[:state])
        #If procedure was closed, notify the police unit
        if @procedure.state == "Close" && $aux == "Open"
          police_unit_id =  @procedure.police_unit_in_charge.id
          police_unit_users = User.where(police_unit_id: police_unit_id)
          police_unit_users.each { |user|
            Notification.create(user_id: user.id, notification_type: 1, reference_id: @procedure.id, seen: false)
          }
        end
        format.html { redirect_to @procedure, notice: 'Procedure was successfully updated.' }
        format.json { render :show, status: :ok, location: @procedure }
      else
        format.html { render :edit }
        format.json { render json: @procedure.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /procedures/1
  # DELETE /procedures/1.json
  def destroy
    @procedure.destroy
    respond_to do |format|
      format.html { redirect_to procedures_url, notice: 'Procedure was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_procedure
    @procedure = Procedure.find(params[:id])
  end

  def procedure_params
    # Only allow a list of trusted parameters through.
    params.require(:procedure).permit(:date,:time,:classification,:involves_deceased,:prosecutor_in_charge, :prosecution_in_charge,:police_unit_in_charge,:police_in_charge,:address,:region,:sector,:preponderant_crime,:state,:photos,:videos, :story, crimes:[],
                                      tag_ids:[], :accuseds => [:name,:alias,:rut], :victims => [:name,:rut,:deceased,:contact,:story],
                                      :witness => [:name,:rut,:story,:contact])
  end
end
