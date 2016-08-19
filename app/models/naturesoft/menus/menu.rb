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
			options = [{"id" => "nil", "text" => "none"}]
			options += items.map { |c| {"id" => c.id, "text" => c.full_name} }
			result = {"items" => options}
		end
    
  end
end
