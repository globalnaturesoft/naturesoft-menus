class AddCustomOrderToNaturesoftMenusMenus < ActiveRecord::Migration[5.0]
  def change
    add_column :naturesoft_menus_menus, :custom_order, :integer, default: 0
  end
end
