module Naturesoft
  module Menus
    module Admin
      class MenusController < Naturesoft::Admin::AdminController
        before_action :set_menu, only: [:show, :edit, :update, :enable, :disable, :destroy]
        before_action :default_breadcrumb
        
        # add top breadcrumb
        def default_breadcrumb
          add_breadcrumb "Menu", naturesoft_menus.admin_menus_path
          add_breadcrumb "Menus", naturesoft_menus.admin_menus_path
        end
    
        # GET /menus
        def index
          Menu.update_all_cache_options
          @menus = Menu.search(params).paginate(:page => params[:page], :per_page => 10)
        end
    
        # GET /menus/1
        def show
        end
    
        # GET /menus/new
        def new
          @menu = Menu.new
          add_breadcrumb "New Menu", nil,  class: "active"
        end
    
        # GET /menus/1/edit
        def edit
          add_breadcrumb "Edit Menu", nil,  class: "active"
        end
    
        # POST /menus
        def create
          @menu = Menu.new(menu_params)
          @menu.params = params[:params].to_json
          @menu.user = current_user
          
          if @menu.save
            redirect_to naturesoft_menus.edit_admin_menu_path(@menu.id), notice: 'Menu was successfully created.'
          else
            render :new
          end
        end
    
        # PATCH/PUT /menus/1
        def update
          @menu.params = params[:params].to_json
          if @menu.update(menu_params)
            redirect_to naturesoft_menus.edit_admin_menu_path(@menu.id), notice: 'Menu was successfully updated.'
          else
            render :edit
          end
        end
    
        # DELETE /menus/1
        def destroy
          @menu.destroy
          render text: 'Menu was successfully destroyed.'
        end
        
        #CHANGE STATUS /menus
        def enable
          @menu.enable
          render text: 'Menu was successfully active.'
        end
        
        def disable
          @menu.disable
          render text: 'Menu was successfully inactive.'
        end
        
        # DELETE /menus/delete?ids=1,2,3
        def delete
          @menus = Menu.where(id: params[:ids].split(","))
          @menus.destroy_all
          render text: 'Menu(s) was successfully destroyed.'
        end
        
        # GET /menus/select2
        def select2
          render json: Menu.select2(params)
        end
        
        # GET /menus/menu_params
        def params_form
          @menu = params[:id].present? ? Naturesoft::Menus::Menu.find(params[:id]) : Naturesoft::Menus::Menu.new
          @menu.menu = params[:type]
          @params = @menu.get_params.nil? ? {} : @menu.get_params
          
          render layout: nil
        end
    
        private
          # Use callbacks to share common setup or constraints between actions.
          def set_menu
            @menu = Menu.find(params[:id])
          end
    
          # Only allow a trusted parameter "white list" through.
          def menu_params
            params.fetch(:menu, {}).permit(:name, :description, :status, :parent_id, :menu, :image, :custom_url)
          end
      end
    end
  end
end
