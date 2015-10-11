class PagesController < ApplicationController
  before_action :authenticate_user!
  require 'net/http'

  def home
    @keywords = Keyword.all
  end

  def search
    ############## Rechercher dans la DB #########################
    def search_in_db(search)

      if search.class == ActiveRecord::Relation
        puts search.dup
        search = search.dup
      elsif (search.class == Keyword)
        puts search.keyword
        search = search.keyword
      elsif (search.class == Linked)
        puts search.keyword_id
        search = Keyword.where(:id => search.keyword_id).dup.first
      elsif (search.is_a? String)
        search = search
      elsif (search == nil)
        puts '!!!ERROR!!!'
      end


        puts "Début de la search_in_db"

        puts "Looking for: #{search} in database"
        result = Keyword.where(:keyword => search)
        resultformated = result.first
        if resultformated.class == Keyword
          puts "*****************************"
          puts "***     #{resultformated[:keyword]}"
          puts "*****************************"
          puts "Found #{result.first[:keyword]} in database"
          if result.length > 0
            puts "Found #{result.length} occurence of #{result.first[:keyword]} in database"
            return resultformated
          else
            puts "Did not found #{search} in database"
            return false
          end
        end
    end

    #####################################################
    ############ Rechercher dans l'API ##################

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

    #####################################################
    ###########  Vérifier si le lien existe #############

    def are_linked_in_db(keyword, linked_keyword)
      puts "Seeking if #{keyword} is linked to #{linked_keyword.keyword} in database"

      if search_in_db(keyword) && search_in_db(linked_keyword)
        db_keyword = search_in_db(keyword)
        puts db_keyword[:id]


        if Linked.where(:keyword_id => db_keyword[:id]).length > 0
          db_linkedstep_keywords = Linked.where(:linked_keyword_id => db_keyword[:id])

          db_linkedstep_keywords.each do |db_linkedstep_keyword|
            puts "°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°"
            puts "#{db_linkedstep_keyword.keyword.keyword}"
            puts "°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°"
            if Keyword.where(:id => db_linkedstep_keyword.keyword.id)
              db_linked_keywords = Keyword.where(:id => db_linkedstep_keyword.keyword.id)

              db_linked_keywords.each do |db_linked_keyword|

                if db_linked_keyword.keyword == keyword
                  puts "#{keyword} and #{db_linked_keyword.keyword} are already linked in database"
                  return true
                else
                  puts "**#{keyword} and #{db_linked_keyword.keyword} are NOT linked in database**"
                  return false
                end
              end


            else
              puts "No match"
              return false
            end
          end
        end
      else
        puts "!!!!!  Error: #{keyword} is not in database !!!!!!"
        return false
      end


    end
    #####################################################
    ################# Lier deux mots ####################

    def link_keywords(keyword, linked_keyword)

      if keyword && linked_keyword
        if keyword[:keyword] == linked_keyword.keyword
          link = Linked.new
          link.keyword_id = keyword[:id]
          link.linked_keyword_id = linked_keyword.id
          if link.save
            puts "#{keyword[:keyword]} existe et a été lié à dans la database ***inside link_keywords***"
            flash[:succes] = "link created between #{keyword} and #{linked_keyword}"
          else
            puts "#{keyword[:keyword]} existe et n'a pas été lié à dans la database ***inside link_keywords***"
            flash[:error] = "Oups, something went wrong during the attempt to link #{keyword} and #{linked_keyword} !"
          end
        end
      end
    end
    #####################################################
    ################## Créer un mots ####################
    def create_keyword(keyword)
      keyword_to_create = Keyword.new
      keyword_to_create.keyword = keyword
      if keyword_to_create.save
        flash[:success] = "#{keyword} as been added to Keywords's table"
        puts "#{keyword} n'existe pas et a été créé dans la database"
        return true
      else
        flash[:success] = "#{keyword} couldn't be added to Keuwords's tables"
      end
    end

    #####################################################
    ############## Mettre à jour les liens ##############

    def update_linked_keywords(responses)
      puts "======================================"
      puts "Début de la mise à jour des mots liés"
      puts "======================================"
      puts "Réponse de l'API : #{responses}"

      responses.each do |response|
        puts "aticle #{response[:id]} avec mots liés"
        puts " ==> #{response["keywords"]} <=="
        response["keywords"].each do |word|
          #pour chaque keyword de chaque article récupéré
          puts "début de la mise a jour du mot lié #{word}"
          db_word = search_in_db(word)
          if word == params[:search]
            puts "#{word} est le mot d'origin, il faut passe à l'étape suivante !"
          elsif db_word == nil
            puts "#{word} not in DB, starting creation..."
            new_keyword = create_keyword(word)
            puts 'sarting to create links'
            link_keywords(search_in_db(search.first[:keyword]), search_in_db(word))
            puts "#{word} et #{search.first[:keyword]} ont été liés dans la database"
          elsif db_word && are_linked_in_db(search_in_db(params[:search]), search_in_db(word))
            #si le mot existe dans la databse et le lien entre la recherche et un mot lié existe dejà dans la database, on passe
            this_search = search_in_db(params[:search])
            puts "#{this_search.keyword} existe et est lié à #{db_word.keyword} dans la database"
            flash[:error] = "#{this_search.keyword} existe et est lié a #{db_word.keyword} ds la db"
          elsif db_word && !are_linked_in_db(params[:search], search_in_db(word))
            #si le mot_lié existe dans la database mais pas le liens avec son mot clé, on créé le lien
            link_keywords(search_in_db(params[:search]), db_word)

          else
            puts "#{word} n'existe pas et n'a pas été lié dans la database"
            flash[:error] = "Oups, something went wrong !"
          end
        end
      end
    end

    #####################################################
    ################# Algorythme général ################

    def algoSearch(search)
      puts "====================="
      puts "Début de la recherche"
      puts "====================="
      if search
        # Si la recherche n'est pas vide
        puts "**********************************************"
        puts "***recherche de: #{search} dans la database***"
        puts "**********************************************"
        if search_in_db(search)
          #si la recherche se trouve dans la DB
          puts "#{search} à été trouvé dans la database"
          responses = search_in_API(search)
          if responses
            # Si le mot existe (toujours) dans l'API
            puts "#{search} existe dans la DB, début de mise à jour via l'API"
            update_linked_keywords(responses)
          else
            puts "#{search} existe dans la DB, mais plus dans l'API"
            flash[:info] = "#{search} as no update or couldn't be update"
          end

        else
          #si la recherche ne se trouve pas dans la DB
          puts "----------------------------------------"
          puts "#{search} Ne ce trouve pas dans la DB !"
          puts "Recherche de #{search} Dans l'API !"

          responses = search_in_API(search)
          if responses
            # algo de récupération
            create_keyword(search)
            update_linked_keywords(responses)
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
    @result = Keyword.where(:keyword => params[:search])
  end

  def showkeyword
    @keyword = Keyword.where(:id => params[:id]).first
    @linkeds = Linked.where(:keyword_id => params[:id])
    @linkedKeywords = []
    @linkeds.each do |linked|
      @linkedKeywords.push(Keyword.where(:id => linked.linked_keyword_id))
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
