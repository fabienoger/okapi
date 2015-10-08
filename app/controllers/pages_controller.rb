class PagesController < ApplicationController
  def home
    @keywords = Keyword.all
  end

  def search
    @search = params[:search]
  end

  def marking

    if KeywordMark.where(:user_id => current_user)
      keyword_to_update = KeywordMark.where(:user_id => current_user).first

      if keyword_to_update.update note: params[:note]
        redirect_to '/'
      else

      end
    else
      @marking = KeywordMark.new note: params[:note], keyword_id: params[:keyword_id], user_id: current_user.id
      if @marking.save
        redirect_to '/'
      else

      end
    end
  end
end
