class PagesController < ApplicationController
  before_action :authenticate_user!
  require 'net/http'

  def home
    @keywords = Keyword.all
  end

  def search
    ############## Rechercher un Keyword dans la DB #########################
    params[:search] = params[:search].downcase
    session[:last_search] = params[:search]
    def search_in_keyword_db(search)
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
      puts "Looking for: #{search} in keyword database"
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
      else
        puts '#{result} is not a KEYWORD'
      end
    end
    ############## Rechercher un Linked_keyword dans la DB #########################
    def search_in_linked_db(master, slave)
      if master.class != String
        puts "Master n'est pas une String : #{master.class}"
        master = master.keyword
      elsif slave.class != String
        puts "Slave n'est pas une String : #{slave.class}"
        slave = slave.keyword
        puts slave + " !!!!!!!!!!!!!!!!"
      end
      master = Keyword.where(:keyword => master).first
      slave = Keyword.where(:keyword => slave).first
      result = Linked.where("keyword_id = ? AND linked_keyword_id = ?", master, slave)
      puts "###########---------------------------------#################################"
      puts result.first
      puts "###########---------------------------------#################################"
      if result.length > 0
        return result
      else
        return false
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
      if keyword.class == Keyword
        keyword = keyword.keyword
      end
#      Linked.where("keyword_id = ? AND linked_keyword_id = ?", )
      if search_in_keyword_db(linked_keyword.keyword) != false
        puts "======================================================================="
        puts "========= #{linked_keyword.keyword} exite dans la table Keywords =========="
        puts "======================================================================="
        if search_in_linked_db(keyword, linked_keyword) != false
          puts "======================================================================="
          puts "==== #{keyword} est lié à #{linked_keyword.keyword} dans la table Linked ===="
          puts "======================================================================="
          return true
        else
          puts "======================================================================="
            puts "==#{keyword} n'est PAs lié à #{linked_keyword.keyword} dans la table Linked ==="
          puts "======================================================================="
          return 1
        end
      else
        puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        puts "=== #{linked_keyword.keyword} N'existe pas dans la table Keyword il faut le créer !==="
        puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        return false
      end
    end
    #####################################################
    ################# Lier deux mots ####################

    def link_keywords(keyword, linked_keyword)
      puts "=°=°=°=°=°=°=°=°=°=°=°=°=°=°=°=°=°=°=°=°=°"
      puts "=°=° Linking of #{keyword[:keyword]} and #{linked_keyword.keyword}°=°=°"
      puts "=°=°=°=°=°=°=°=°=°=°=°=°=°=°=°=°=°=°=°=°=°"

      if keyword && linked_keyword
        if keyword[:keyword] != linked_keyword.keyword
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
        flash[:success] = "#{keyword} couldn't be added to Keywords's tables"
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
        puts "article #{response[:id]} avec mots liés"
        puts " ==> #{response["keywords"]} <=="
        response["keywords"].each do |word|
          #pour chaque keyword de chaque article récupéré
          puts "début de la mise a jour du mot lié #{word}"
          db_word = search_in_keyword_db(word)
          if word == params[:search]
            puts "#{word} est le mot d'origin, il faut passer à l'étape suivante !"
          elsif db_word == nil
            new_keyword = create_keyword(word)
            puts 'starting to create links'
            link_keywords(search_in_keyword_db(search.first[:keyword]), search_in_keyword_db(word))
            puts "#{word} et #{search.first[:keyword]} ont été liés dans la database"
          elsif db_word && are_linked_in_db(search_in_keyword_db(params[:search]), search_in_keyword_db(word)) == 1
            puts "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&"
            link_keywords(search_in_keyword_db(params[:search]),search_in_keyword_db(word))
          elsif db_word && are_linked_in_db(search_in_keyword_db(params[:search]), search_in_keyword_db(word))
            #si le mot existe dans la databse et le lien entre la recherche et un mot lié existe dejà dans la database, on passe
            this_search = search_in_keyword_db(params[:search])
            puts "#{this_search.keyword} existe et est lié à #{db_word.keyword} dans la database"
            flash[:success] = "#{this_search.keyword} existe et est lié a #{db_word.keyword} ds la db"
          elsif db_word != false && !are_linked_in_db(search_in_keyword_db(params[:search]), search_in_keyword_db(word))
            #si le mot_lié existe dans la database mais pas le liens avec son mot clé, on créé le lien
            link_keywords(search_in_keyword_db(params[:search]), db_word)
          else
            puts "#{word} n'existe pas et n'a pas été lié dans la database"
            flash[:error] = "Oups, something went wrong !"
          end
          puts "======================================"
          puts "Fin de la mise à jour du mots liés #{word}"
          puts "======================================"
        end
      end
    end

    #####################################################
    ################# Algorythme général ################

    def algoSearch(search)
      puts "====================="
      puts "Début de la recherche"
      puts "====================="
      if search.length > 0
        # Si la recherche n'est pas vide
        puts "**********************************************"
        puts "***recherche de: #{search} dans la database***"
        puts "**********************************************"
        if search_in_keyword_db(search)
          #si la recherche se trouve dans la DB
          puts "#{search} à été trouvé dans la database"
          responses = search_in_API(search)
          if responses.length > 0
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
    @search = params[:search]
    if params[:search].length > 0
      @result = Keyword.where(:keyword => params[:search])
    else
      @result = false
    end
  end

  def showkeyword
    @keyword = Keyword.where(:id => params[:id]).first
    linkeds = Linked.where(:keyword_id => params[:id])
    puts "|_________________________________________________|"
    puts linkeds.class
    puts "|_________________________________________________|"
    @linkedKeywords = []
    linkeds.each do |linked|
    @linkedKeywords.push(Keyword.where(:id => linked.linked_keyword_id).first)
    end
  end

  def marking
    if KeywordMark.where(["user_id = ? and keyword_id = ?", current_user, params[:keyword_id]]).length > 0
      keyword_to_update = KeywordMark.where(["user_id = ? and keyword_id = ?", current_user, params[:keyword_id]]).first

      if keyword_to_update.update note: params[:note]
        redirect_to request.referer || '/'
      else

      end
    else
      @marking = KeywordMark.new note: params[:note], keyword_id: params[:keyword_id], user_id: current_user.id
      if @marking.save
        redirect_to request.referer || '/'
      else

      end
    end
  end
end
