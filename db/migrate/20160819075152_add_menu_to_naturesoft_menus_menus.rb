class AddMenuToNaturesoftMenusMenus < ActiveRecord::Migration[5.0]
  def change
    add_column :naturesoft_menus_menus, :menu, :string
  end
end
