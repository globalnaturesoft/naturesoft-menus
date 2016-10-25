class AddCustomUrlToNaturesoftMenusMenus < ActiveRecord::Migration[5.0]
  def change
    add_column :naturesoft_menus_menus, :custom_url, :string
  end
end
