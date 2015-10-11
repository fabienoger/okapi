class PagesController < ApplicationController
  before_action :authenticate_user!
  require 'net/http'

  def home
    @keywords = Keyword.all
  end

  def search
    def search_in_db(search)

      if !search.is_a? String
        search = search.first[:keyword]

      end


        puts "Début de la search_in_db"
        puts "la class de l'objet recherché est  #{search.class}"
        puts "Looking for: #{search} in database"
        result = Keyword.where(:keyword => search)
        resultformated = result.first
        if resultformated.class == Keyword
          puts "*****************************"
          puts "***                       ***"
          puts "***     #{resultformated[:keyword]}"
          puts "***                       ***"
          puts "*****************************"
          puts "Found #{result} in database"
          if result.length > 0
            puts "Found #{result.length} occurence of #{result} in database"
            return result
          else
            puts "Did not found #{search} in database"
            return false
          end
        end
    end

    def search_in_API(search)
      url = URI.parse("http://bayard.simplon.co/articles.json?by_keyword=#{search}")
      request = Net::HTTP.get(url)
      if request.length > 2
        responses = JSON.parse(request)
        return responses
      else
        return false
      end
    end

    def are_linked_in_db(keyword, linked_keyword)
      puts "Seeking if #{keyword} is linked to #{linked_keyword} in database"
      if search_in_db(keyword) && search_in_db(linked_keyword)
        db_keyword = search_in_db(keyword)
        db_linkedstep_keywords = Linked.where(:keyword_id => db_keyword.first.id)
        db_linked_keywords = Keyword.where(:id => db_linkedstep_keywords.first)
        puts "#{keyword} is linked to "
        db_linked_keywords.each do |db_linked_keywor|
          if db_linked_keyword.keyword.keyword = linked_keyword
            puts "#{keyword} and #{linked_word} are already linked in database"
            return true
            break
          else
            puts "No match"
            return false
          end
        end
      else
        puts "!!!!!  Error: #{keyword} is not in database !!!!!!"
        return false
      end
    end

    def link_keywords(keyword, linked_keyword)
      if keyword && link_keyword
        link = Linked.new
        link.keyword_id = keyword.id
        link.linked_keyword_id = linked_keyword.id
        if link.save
          falsh[:succes] = "link created between #{keyword} and #{linked_keyword}"
        else
          flash[:error] = "Oups, something went wrong during the attempt to link #{keyword} and #{linked_keyword} !"
        end
      end
    end

    def create_keyword(keyword)
      keyword_to_create = Keyword.new
      keyword_to_create.keyword = keyword
      if keyword_to_create.save
        flash[:success] = "#{keyword} as been added to Keywords's table"
      else
        flash[:success] = "#{keyword} couldn't be added to Keuwords's tables"
      end
    end

    def update_linked_keywords(responses)
      puts "Début de la mise à jour des mots liés"
      puts "#{responses}"
      if responses
        flag = false
        responses.each do |response|
          puts "aticle avec mots liés"
          response["keywords"].each do |word|
            #pour chaque keyword de chaque article récupéré
            puts "début de la mise a jour du mot lié #{word}"
            this_word = search_in_db(word)
            if word == params[:search]
              puts "word est le mot d'origin, il faut passe à l'étape suivante !"

            elsif this_word && are_linked_in_db(search_in_db(params[:search]), this_word)
              #si le mot existe dans la databse et le lien entre la recherche et un mot lié existe dejà dans la database, on passe
              puts "#{word} existe et est lié à dans la database"
              flag = true
              break
            elsif this_word && are_linked_in_db(search_in_db(params[:search]), this_word) == false
              #si le mot_lié existe dans la database mais pas le liens avec son mot clé, on créé le lien
              puts "#{word} existe et a été lié à dans la database"
              link_keywords(search_in_db(search), search_in_db(word))
              break
            elsif !this_word
              new_keyword = create_keyword(word)
              puts "#{word} n'existe pas et a pas été créé dans la database"
              link_keywords(search_in_db(search), search_in_db(word))
              puts "#{word} et #{search} ont été liés dans la database"
            else
              puts "#{word} n'existe pas et n'a pas été lié dans la database"
              flash[:error] = "Oups, something went wrong !"
              break
            end
          end
        end
      else
        flash[:error] = "Oups, something went wrong"
      end
    end

    def algoSearch(search)
      puts "====================="
      puts "Début de la recherche"
      puts "====================="
      if search
        # algo
        puts "***recherche de: #{search} dans la database***"
        if search_in_db(search)
          #si la recherche se trouve dans la DB
          puts "#{search} à été trouvé dans la database"
          responses = search_in_API(search)
          if responses
            # Si le mot existe (toujours) dans l'API
            puts "Le Keyword existe, début de mise à jour via l'API"
            update_linked_keywords(responses)
          else
            flash[:info] = "#{search} as no update or couldn't be update"
          end

        else
          #si la recherche ne se trouve pas dans la DB

          @responses = search_in_API(search)
          if @responses
            # algo de récupération
            create_keyword(search)
            update_linked_keywords(@responses)
          else
            puts 'go Google!'
            @googleSearch = "https://www.google.fr/search?q=#{params[:search]}"
          end
        end

      else
        flash[:error] = "Vous devez entrer un mot clef pour lancer une recherche"
      end
    end

    algoSearch(params[:search])
  end

  def showkeyword
    @keyword = Keyword.where(:id => params[:id]).first
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
