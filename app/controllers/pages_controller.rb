class PagesController < ApplicationController
  before_action :authenticate_user!
  require 'net/http'

  def home
    @keywords = Keyword.all
  end

  def search
    if params[:search]
      @search = params[:search]
      @result = Keyword.where(['keyword LIKE ?', "%#{params[:search]}%"])
      if @result.length > 0
        # Algo nuage de mots clés
      else @result.length < 0
        # Request API
        puts 'Go API !!'
        url = URI.parse("http://bayard.simplon.co/articles.json?by_keyword=#{params[:search]}")
        @request = Net::HTTP.get(url)
        puts @request.length
        if @request.length > 2
          @request = JSON.parse(@request)
          flag = false
          @request.each do |r|
            r['keywords'].each do |word|
              if params[:search] == word && flag == false
                keyword = Keyword.new
                keyword.keyword = word
                if keyword.save
                  flag = true
                  flash[:success] = "Un Keyword a bien été récupéré dans l'API !"
                  break
                else
                  flash[:error] = "Oops ! Something went wrong ! :p"
                end
              else
                puts word
              end
            end
          end
        else
          puts 'go Google!'
          @googleSearch = "https://www.google.fr/search?q=#{params[:search]}"
        end
      end
    else

    end
  end

  def marking

    if KeywordMark.where(["user_id = ? and keyword_id = ?", current_user, params[:keyword_id]]).length > 0
      keyword_to_update = KeywordMark.where(["user_id = ? and keyword_id = ?", current_user, params[:keyword_id]]).first

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
