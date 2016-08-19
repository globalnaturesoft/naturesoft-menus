class AddParamsToNaturesoftMenusMenus < ActiveRecord::Migration[5.0]
  def change
    add_column :naturesoft_menus_menus, :params, :string
  end
end
