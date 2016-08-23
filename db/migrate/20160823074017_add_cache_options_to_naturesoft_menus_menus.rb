class AddCacheOptionsToNaturesoftMenusMenus < ActiveRecord::Migration[5.0]
  def change
    add_column :naturesoft_menus_menus, :cache_options, :text
  end
end
