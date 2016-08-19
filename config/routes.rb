Naturesoft::Menus::Engine.routes.draw do
  namespace :admin, module: "admin", path: "admin/menus" do
    resources :menus do
      collection do
        put "enable"
        put "disable"
        delete 'delete'
        get "select2"
      end
    end
  end
end