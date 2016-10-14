module Naturesoft
  class ApplicationController < ActionController::Base
      before_filter :set_menu
      before_action :set_menu
      
      def set_menu
          @current_menu = params[:menu_id].present? ? Naturesoft::Menus::Menu.find(params[:menu_id]) : nil
      end
  end
end