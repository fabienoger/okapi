class PagesController < ApplicationController
  before_action :authenticate_user!
  require 'net/http'

  # Function request API
  def request_api(type, page = nil)
    if page == nil
      url = URI.parse("http://bayard.simplon.co/#{type}.json")
    else
      url = URI.parse("http://bayard.simplon.co/#{type}.json?page=#{page}")
    end
    request = Net::HTTP.get(url)
    if request.length > 2
      responses = JSON.parse(request)
      return responses
    else
      puts "-----------------------------------------".red
      puts "Request Fail".red
      puts "-----------------------------------------".red
      return false
    end
  end

  def articleMarking
    if ArticleMark.where(["user_id = ? and article_id = ?", current_user, params[:article_id]]).length > 0
      article_to_update = ArticleMark.where(["user_id = ? and article_id = ?", current_user, params[:article_id]]).first

      if article_to_update.update note: params[:note]
        redirect_to request.referer || '/'
      else

      end
    else
      @marking = ArticleMark.new note: params[:note], article_id: params[:article_id], user_id: current_user.id
      if @marking.save
        redirect_to request.referer || '/'
      else

      end
    end
  end

  def read
    i = 0
    @article
    while (i < 5)
      if i != 0
        if request_api("articles", i) != false
          request = request_api("articles", i)
          request.each do |r|
            if params[:article_id].to_i == r["id"].to_i
              @article = r
              puts "L'article est dans la categorie => #{r["category_id"]}".green
            else
              puts "L'article n'est pas dans la catégorie Ask Okapi ~something~ => #{r["category_id"]}".red
            end
          end
        else
          puts "Pas de réponse de l'API pour les articles".red
        end
      end
      i += 1
    end
  end

  def category
    i = 0
    @articles = []
    while (i < 5)
      if i != 0
        if request_api("articles", i) != false
          request = request_api("articles", i)
          request.each do |r|
            if params[:id].to_i == r["category_id"].to_i
              @articles.push(r)
              puts "L'article est dans la categorie => #{r["category_id"]}".green
            else
              puts "L'article n'est pas dans la catégorie Ask Okapi ~something~ => #{r["category_id"]}".red
            end
          end
        else
          puts "Pas de réponse de l'API pour les articles".red
        end
      end
      i += 1
    end
  end

  def home
    # Get all categories (Request API)
    if request_api("categories") != false
      @ask_categories = []
      request = request_api("categories")
      request.each do |r|
        if r["title"].split(" ")[0] == "Ask"
          @ask_categories.push(r)
          puts "#{r["title"]} pushed in array".green
        else
          puts "Oups ! There no ask okapi category".red
        end
      end
    else
      puts "Pas de réponse de l'API pour les catégories".red
    end
    # Get all articles (Request API)
    i = 0
    @articles = []
    while (i < 5)
      if i != 0
        if request_api("articles", i) != false
          request = request_api("articles", i)
          request.each do |r|
            @ask_categories.each do |categorie|
              if categorie["id"] == r["category_id"]
                @articles.push(r)
                #puts "L'article est dans la categorie => #{r["category_id"]}".green
              else
                #puts "L'article n'est pas dans la catégorie Ask Okapi ~something~ => #{r["category_id"]}".red
              end
            end
          end
        else
          puts "Pas de réponse de l'API pour les articles".red
        end
      end
      i += 1
    end
    @articles = @articles[0..5].reverse
  end

  def search
    puts "=====================".yellow
    puts "Début de la route".yellow
    puts "=====================".yellow
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
        puts '!!!ERROR!!!'.red
      end
      puts "Looking for: #{search} in keyword database".yellow
      result = Keyword.where(:keyword => search)
      resultformated = result.first
      if resultformated.class == Keyword
        puts "Found #{resultformated[:keyword]} in database".green
        if result.length > 0
          puts "Found #{result.length} occurence of #{result.first[:keyword]} in database".cyan
          return resultformated
        else
          puts "Did not found #{search} in database".red
          return false
        end
      else
        puts '#{result} is not a Keyword object'.magenta
      end
    end
    ############## Rechercher un Linked_keyword dans la DB #########################
    def search_in_linked_db(master, slave)
      if master.class != String
        puts "Master isn't a String : #{master.class}".magenta
        master = master.keyword
      elsif slave.class != String
        puts "Slave isn't a String : #{slave.class}".magenta
        slave = slave.keyword
      end
      master = Keyword.where(:keyword => master).first
      slave = Keyword.where(:keyword => slave).first
      result = Linked.where("keyword_id = ? AND linked_keyword_id = ?", master, slave)
      if result.length > 0
        puts "MATCH!".green
        return result
      else
        puts "NO MATCH!".red
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
        puts "=======================================================================".blue
        puts "========= #{linked_keyword.keyword} exite dans la table Keywords ==========".blue
        puts "=======================================================================".blue
        if search_in_linked_db(keyword, linked_keyword) != false
          puts "=======================================================================".green
          puts "==== #{keyword} est lié à #{linked_keyword.keyword} dans la table Linked ====".green
          puts "=======================================================================".green
          return true
        else
          puts "=======================================================================".yellow
            puts "==#{keyword} n'est PAs lié à #{linked_keyword.keyword} dans la table Linked ===".yellow
          puts "=======================================================================".yellow
          return 1
        end
      else

        puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~".red
        puts "=== #{linked_keyword.keyword} N'existe pas dans la table Keyword il faut le créer !===".red
        puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~".red
        return false
      end
    end
    #####################################################
    ################# Lier deux mots ####################

    def link_keywords(keyword, linked_keyword)
      puts "=°=°=°=°=°=°=°=°=°=°=°=°=°=°=°=°=°=°=°=°=°".light_cyan
      puts "=°=° Linking of #{keyword[:keyword]} and #{linked_keyword.keyword}°=°=°".light_cyan
      puts "=°=°=°=°=°=°=°=°=°=°=°=°=°=°=°=°=°=°=°=°=°".light_cyan

      if keyword && linked_keyword
        if keyword[:keyword] != linked_keyword.keyword && (are_linked_in_db(keyword[:keyword],linked_keyword ) == 1 || are_linked_in_db(keyword[:keyword],linked_keyword ) == false )
          link = Linked.new
          link.keyword_id = keyword[:id]
          link.linked_keyword_id = linked_keyword.id
          if link.save
            puts "#{keyword[:keyword]} existe et a été lié à dans la database ***inside link_keywords***".green
          else
            puts "#{keyword[:keyword]} existe et n'a pas été lié à dans la database ***inside link_keywords***".red
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
        puts "#{keyword} n'existe pas et a été créé dans la database".green
        return true
      else
        puts "#{keyword} n'existe pas et a n'a pas été créé dans la database".red
      end
    end

    #####################################################
    ############## Mettre à jour les liens ##############

    def update_linked_keywords(responses)
      puts "======================================".blue
      puts "Début de la mise à jour des mots liés".blue
      puts "======================================".blue
      puts "Réponse de l'API : #{responses}".cyan

      responses.each do |response|
        puts "article #{response['id']} avec mots liés".blue
        puts " ==> #{response["keywords"]} <==".magenta
        response["keywords"].each do |word|
          #pour chaque keyword de chaque article récupéré
          puts "début de la mise a jour du mot lié #{word}".yellow
          db_word = search_in_keyword_db(word)
          if word == params[:search]
            puts "#{word} is the original word, skipping".magenta
          elsif db_word == nil
            puts 'starting to create #{word}'.yellow
            new_keyword = create_keyword(word)
            puts 'starting to create links'.yellow
            link_keywords(search_in_keyword_db(search.first[:keyword]), search_in_keyword_db(word))
          elsif db_word && are_linked_in_db(search_in_keyword_db(params[:search]), search_in_keyword_db(word)) == 1
            puts 'starting to create links'.light_green
            link_keywords(search_in_keyword_db(params[:search]),search_in_keyword_db(word))
          elsif db_word && are_linked_in_db(search_in_keyword_db(params[:search]), search_in_keyword_db(word))
            #si le mot existe dans la databse et le lien entre la recherche et un mot lié existe dejà dans la database, on passe
            this_search = search_in_keyword_db(params[:search])
            puts "#{this_search.keyword} exist and is linked to #{db_word.keyword}".cyan
            flash[:success] = "#{this_search.keyword} existe et est lié a #{db_word.keyword} ds la db"
          elsif db_word != false && !are_linked_in_db(search_in_keyword_db(params[:search]), search_in_keyword_db(word))
            #si le mot_lié existe dans la database mais pas le liens avec son mot clé, on créé le lien
            puts 'starting to create links'.yellow
            link_keywords(search_in_keyword_db(params[:search]), db_word)
          else
            puts "#{word} n'existe pas et n'a pas été lié dans la database".red
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

    def algoSearch(research)

      puts "=====================".yellow
      puts "Début de la recherche".yellow
      puts "=====================".yellow
      if research.length > 0
        # Si la recherche n'est pas vide
        puts "**********************************************".light_green
        puts "***recherche de: #{research} dans la database***".light_green
        puts "**********************************************".light_green
        if search_in_keyword_db(research)
          #si la recherche se trouve dans la DB
          puts "#{research} à été trouvé dans la database".green
          responses = search_in_API(research)
          if responses.length > 0
            # Si le mot existe (toujours) dans l'API
            puts "#{research} existe dans la DB, début de mise à jour via l'API".cyan
            update_linked_keywords(responses)
          else
            puts "#{research} existe dans la DB, mais plus dans l'API".magenta
            flash[:info] = "#{research} as no update or couldn't be update"
          end
        else
          #si la recherche ne se trouve pas dans la DB
          puts "----------------------------------------".yellow
          puts "#{research} Ne ce trouve pas dans la DB !".red
          puts "Recherche de #{research} Dans l'API !".cyan

          responses = search_in_API(research)
          if responses
            create_keyword(research)
            update_linked_keywords(responses)
          else
            puts 'go Google!'.red
            @googleSearch = "https://www.google.fr/search?q=#{research}"
          end
        end
      else
        flash[:error] = "Vous devez entrer un mot clef pour lancer une recherche"
      end
      puts String.colors
      puts "Fin de la fonction de l'algo".light_magenta
    end
    puts "Lancement de l'algo".magenta
    algoSearch(params[:search])
    puts "fin de l'appel de l'algo".yellow

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

  def loosingtime
    url = URI.parse("http://bayard.simplon.co/articles.json")
    request = Net::HTTP.get(url)
    if request.length > 2
      requests = JSON.parse(request)
      tab = []
      requests.each do |r|
        tab.push(r["id"])
      end
      random = tab.sample(1)[0]
      requests.each do |r|
        if r["id"] == random
          @article = r
        end
      end
    else
      flash[:error] = "No article found"
      return false
    end
  end
end
