class PagesController < ApplicationController
  def home
  end

  def search
    @search = params[:search]
  end
end
