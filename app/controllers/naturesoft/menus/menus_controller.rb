module Naturesoft
  module Menus
      class MenusController < Naturesoft::Admin::AdminController
        
        # GET /menus
        def index
          c = Naturesoft::Articles::Admin::ArticlesController.new
          c.request = request
          c.response = response
          c.index
        end
    
      end
  end
end
