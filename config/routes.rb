Naturesoft::Menus::Engine.routes.draw do
  namespace :backend, module: "backend", path: "backend/menus" do
    resources :menus do
      collection do
        put "enable"
        put "disable"
        delete 'delete'
        get "select2"
        get "params_form"
      end
    end
  end
  
  #begin
    # route for menus
    Naturesoft::Menus::Menu.get_all.each do |m|
      get m.route_path, m.route_params.merge({as: m.path_string})
    end
  #rescue
  #end
end