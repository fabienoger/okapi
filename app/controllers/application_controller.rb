class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :load_categories

  # Get catégories
  def load_categories
    url = URI.parse("http://bayard.simplon.co/categories.json")
    request = Net::HTTP.get(url)
    if request.length > 2
      responses = JSON.parse(request)
      @menu_categories = []
      responses.each do |r|
        puts "===========================#{r["title"]}".blue
        if r["title"].split(" ")[0] == "Ask"
          @menu_categories.push(r)
          puts "#{r["title"]} pushed in array".green
        else
          puts "Oups ! There no ask okapi category".red
        end
      end
      puts "======================================#{@menu_categories}".light_green
      puts "---------------------------------------------------".yellow
    else
      puts "Request fail".magenta
    end
  end
end
