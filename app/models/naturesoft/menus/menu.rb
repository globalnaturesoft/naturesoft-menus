module Naturesoft::Menus
  class Menu < ApplicationRecord
    validates :name, presence: true
		
    belongs_to :user
    belongs_to :parent, class_name: "Menu", optional: true
    has_many :children, class_name: "Menu", foreign_key: "parent_id"
    
    after_save :update_level
    
    def update_level
			level = 1
			p = self.parent
			while !p.nil? do
				level += 1
				p = p.parent
			end
			self.update_column(:level, level)
		end
    
    def self.sort_by
      [
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
      if params[:parent_id].present?
				records = records.where(parent_id: params[:parent_id])
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
      result = Menu.get_default(engine, mod)
      
      if params.present?
        result = JSON.parse(params)
      end
      
      return result
    end
    
    # def gnerate route
    def route_params
			return nil if id.nil?
			
			params = {controller: options["controller"], action: options["action"], :only_path => true}
			if !get_params.nil?
				get_params.each do |row|
					params = params.merge({:"#{row[0]}" => (row[1].present? and row[1] != "nil" ? row[1] : "__MISSING__")})
				end
			end
			
			return params
		end
    
    # get default values from model
    def self.get_default(engine, mod)
      eval("@#{engine}")[mod]["params"]
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
			Menu.config(self)
		end
    
    # path
    def path
			return "" if route_params.nil?
			
			begin
				return eval("Naturesoft::#{engine_name.split('_').map(&:capitalize).join('')}::Engine").routes.url_for(route_params)
			rescue => ex
				return "<span class='text-danger'>Invalid route!</span><br ><small>#{ex.message}</small>"
			end
		end
    
    # get config
    def self.config(menu)
			eval("@#{menu.engine_name}")[menu.module_name]
		end
    
    # def get_all
    def self.get_all
			self.all
		end
    
    # get route name
    def url
			return nil if name.nil?
			"/"+Naturesoft::ApplicationController.helpers.url_friendly(name)+".html"
		end
  end
end
