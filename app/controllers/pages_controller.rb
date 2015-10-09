class PagesController < ApplicationController
  def home
  end

  def search
    if params[:search]
      @search = params[:search]
      @result = Keyword.where(['keyword LIKE ?', "%#{params[:search]}%"])
      if @result.length > 0
        # Algo nuage de mots clés
      else
        # Request API
      end
    else

    end
  end
end
