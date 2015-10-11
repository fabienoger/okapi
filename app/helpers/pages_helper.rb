 module PagesHelper


  #################################################################################
  #  if params[:search]
  #    @search = params[:search]
  #    @result = Keyword.where(['keyword LIKE ?', "%#{params[:search]}%"])
  #    if @result.length > 0
      # Algo nuage de mots clés
      #    else @result.length < 0
      # Request API
      #      puts 'Go API !!'
      #      url = URI.parse("http://bayard.simplon.co/articles.json?by_keyword=#{params[:search]}")
      #      @request = Net::HTTP.get(url)
      #      if @request.length > 2
      #        @request = JSON.parse(@request)
      #        puts "=================="
      #        puts "000000000000000000"
      #        puts @request
      #        puts "000000000000000000"
      #        puts "=================="
      #
      #        keywordflag = false
      #        @request.each do |r|
      #          r['keywords'].each do |word|
      #            check = Keyword.where(:keyword => word)
      #            puts "===================="
      #            puts "********************"
      #            puts  word
      #            puts "********************"
      #            puts "===================="
      #            if params[:search] == word && keywordflag == false

      #              keyword = Keyword.new
      #              keyword.keyword = word
      #              if keyword.save
      #                keywordflag = true
      #                flash[:success] = "Un Keyword a bien été récupéré dans l'API !"
      #              else
      #                flash[:error] = "Oops ! Something went wrong ! :p"
      #              end
      #            elsif params[:search] != word && check
      #              puts "===================="
      #              puts check
      #            puts "===================="
      #            related_keyword = Keyword.new
      #            related_keyword.keyword = word
      #            if related_keyword.save
      #              flash[:success] = " #{related_keyword} a bien été récupéré dans l'API !"
      #            else
      #              flash[:error] = "Oops ! Something went wrong ! :p"
      #            end
      #          end
      #        end
      #      end
      #      else
      #        puts 'go Google!'
      #        @googleSearch = "https://www.google.fr/search?q=#{params[:search]}"
      #      end
      #    end
      #  else

      #  end

end
