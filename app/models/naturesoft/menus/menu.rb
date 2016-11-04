module Naturesoft::Menus
  class Menu < ApplicationRecord
    validates :name, presence: true
    validates :custom_url, uniqueness: {allow_blank: true, allow_nil: true}
    include Naturesoft::CustomOrder
    mount_uploader :image, Naturesoft::Menus::MenuUploader
		
    belongs_to :user
    belongs_to :parent, class_name: "Menu", optional: true
    has_many :children, class_name: "Menu", foreign_key: "parent_id"
    
    after_save :update_level
    after_save :update_cache_options
    after_save :reload_routes
    
    @menus = {
      "alias_menu" => {
        "label" => "Alias Menu",
        "controller" => "/naturesoft/menus/menus",
        "action" => nil,
        "params" => {
          "menu_id" => nil
        }
      }
    }
    
    def reload_routes
			# reload routes
      Rails.application.reload_routes!  
		end
    
    def update_cache_options
			self.update_column(:cache_options, options.to_json)
		end
    
    def self.update_all_cache_options
			self.all.each do |m|
				m.update_cache_options
			end
		end
    
    def update_level
			level = 1
			p = self.parent
			while !p.nil? do
				level += 1
				p = p.parent
			end
			self.update_column(:level, level)
		end
    
    # get saved cache options
    def get_cache_options
			return {} if cache_options.nil?
			
			JSON.parse(cache_options)
		end
    
    def self.sort_by
      [
				["Custom order","naturesoft_menus_menus.custom_order"],
			  ["Level","naturesoft_menus_menus.level"],
        ["Name","naturesoft_menus_menus.name"],
        ["Created At","naturesoft_menus_menus.created_at"]
      ]
    end
    
    def self.sort_orders
      [
        ["ASC","asc"],
        ["DESC","desc"]
      ]
    end
    
    #Filter, Sort
    def self.search(params)
      records = self.all
      
      #Search keyword filter
      if params[:keyword].present? or params[:q].present?
				kws = params[:keyword].present? ? params[:keyword] : params[:q]
        kws.split(" ").each do |k|
          records = records.where("LOWER(CONCAT(naturesoft_menus_menus.name)) LIKE ?", "%#{k.strip.downcase}%") if k.strip.present?
        end
      end
      
      # Parent menu
      if params[:parent_id] != "all"
				p_id = params[:parent_id].present? ? params[:parent_id] : nil
				records = records.where(parent_id: p_id)
			end
      
      # for sorting
      sort_by = params[:sort_by].present? ? params[:sort_by] : "naturesoft_menus_menus.name"
      sort_orders = params[:sort_orders].present? ? params[:sort_orders] : "asc"
      records = records.order("#{sort_by} #{sort_orders}")
      
      return records
    end
    
    # enable/disable status
    def enable
			update_columns(status: "active")
		end
    
    def disable
			update_columns(status: "inactive")
		end
    
    # display name with parent
    def full_name
			names = [self.name]
			p = self.parent
			while !p.nil? do
				names << p.name
				p = p.parent
			end
			names.reverse.join(" >> ")
		end
    
    # data for select2 ajax
    def self.select2(params)
			items = self.search(params).order("level")
			if params[:excluded].present?
				items = items.where.not(id: params[:excluded].split(","))
			end
			options = [{"id" => "", "text" => "none"}]
			options += items.map { |c| {"id" => c.id, "text" => c.full_name} }
			result = {"items" => options}
		end
    
    # get menu types from engines
    def self.menus
      types = {}
      Dir.glob(Rails.root.join('engines').to_s + "/*") do |d|
        eg = d.split(/[\/\\]/).last
        
        if eval("@#{eg}").present?
          types[eg] = eval("@#{eg}")
        end
      end
      types
    end
    
    # menu types select options
    def self.menusSelectOptions
      options = []
      self.menus.each do |m|
        opts = []
        m[1].each do |mm|
          opts << [mm[1]["label"], m[0]+"::"+mm[0]]
        end
        options << [m[0], opts]
      end
      options
    end
    
    # get params by menu
    def get_params
      engine = self.engine_name
      mod = self.module_name
        
      # Get default params
      result = get_cache_options["params"]
      
      if params.present?
        result = JSON.parse(params)
      end
      
      return result
    end
    
    # def gnerate route
    def route_params
			return nil if id.nil?
			
			# Alias menu
			if self.menu == 'menus::alias_menu' && self.get_params.present?
				menu = Menu.find(self.get_params["menu_id"])
				return menu.route_params
			end
			
			result = {controller: get_cache_options["controller"], action: get_cache_options["action"], :only_path => true}
			if !get_params.nil?
				get_params.each do |row|
					result = result.merge({:"#{row[0]}" => (row[1].present? and row[1] != "nil" ? row[1] : "__MISSING__")})
				end
			end
			result[:menu_id] = self.id
			return result
		end
    
    # get engine name
    def engine_name
      self.menu.to_s.split("::")[0]
    end
    
    # get module name
    def module_name
      self.menu.to_s.split("::")[1]
    end
    
    # all options
    def options
			Menu.get_options(self)
		end
    
    # def get
    def self.get_options(menu)
			eval("@#{menu.engine_name}")[menu.module_name]
		end
    
    # path
    def path
			return "" if route_params.nil?
			
			# Alias menu
			if self.menu == 'menus::alias_menu' && self.get_params.present?
				menu = Menu.find(self.get_params["menu_id"])
				return menu.path
			end
			
			begin
				return eval("Naturesoft::#{engine_name.split('_').map(&:capitalize).join('')}::Engine").routes.url_for(route_params)
			rescue => ex
				return "<span class='text-danger'>Invalid route!</span><br ><small>#{ex.message}</small>"
			end
		end
    
    # def get_all
    def self.get_all
			self.all
		end
    
    # get route name
    def url
			return nil if name.nil?
			return "/"+custom_url if custom_url.present?
			
			# Alias menu
			if self.menu == 'menus::alias_menu' && self.get_params.present?
				menu = Menu.find(self.get_params["menu_id"])
				return menu.url
			end
			
			names = [Naturesoft::ApplicationController.helpers.url_friendly(self.name)]
			p = self.parent
			while !p.nil? do
				names << Naturesoft::ApplicationController.helpers.url_friendly(p.name)
				p = p.parent
			end
			
			"/"+names.reverse.join("/")+".html"
		end
  end
end
