require 'awesome_print'

class ArticlesController < ApplicationController
  # GET /articles
  # GET /articles.json
  def index    

  end

  def show_all
    @articles = Article.all
    render "articles"
  end


  def show
    @article = Article.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @article }
    end
  end


  def search
    # puts params['query']
    

    
  end

  def get_related
    tag = params['query']


    @articles = getRelatedPapers(tag)

    

    @found = 1
    if @articles.nil?
      @msg = "None found, try again..."
      @found = 0
      @articles = []
    end

    render "articles"
  end

  def getRelatedPapers(curr_id)
    @article = Article.where('arxiv_id = ?', curr_id).first

    if @article == [] || @article.nil?
      return nil
    end
    @valid_friends = []

    @friends = @article.friendships

    if @friends == [] || @friends.nil?
      puts 'no friends of article ' + curr_id.to_s
      return nil
    end

    @friends.each do |friendship|
      friend = Article.find(friendship.friend_id)
      if friend.category == @article.category
        @valid_friends << friend
      end
    end

    puts "valid_friends"
    puts @valid_friends

    temp = Hash.new()

    @valid_friends.each do |friend|
      keywords = @article.keywords.split(',')
      friend_keywords = friend.keywords.split(',')
      score = lev_distance(keywords, friend_keywords)
      puts "SCORE"
      puts score

      if !temp[score]
        temp[score] = []
      end
      temp[score] << friend
    end

    @final_articles = []

    # puts "TEMP SORT"
    # ap temp

    sorted = temp.dup

    sorted.sort.each do |score|


        temp[score[0]].each do |article|
          puts "ARTICLE"
          puts article
          @final_articles << article
        end

    end
    puts "FINAL"
    puts @final_articles

    return @final_articles.last(3)

  end

  # def getScore(keywords1, keywords2)

  #   if keywords1.length > 0 && keywords2.length > 0
  #     if keywords1.first == keywords2.first       # COMPLETE MATCH
  #       return 1 + getScore(keywords1[1..-1], keywords2[1..-1])
  #     end
  #     if keywords1.first.include?(keywords2.first) || keywords2.first.include?(keywords1.first) #PARTIAL MATCH
  #       return 0.75 + getScore(keywords1[1..-1], keywords2[1..-1])
  #     end
  #     return -0.25 + getScore(keywords1[1..-1], keywords2[1..-1]) # NO MATCH

  #   else
  #     return 0
  #   end
  
  # end

  def lev_distance(a, b)
    case
      when a.empty? then b.length
      when b.empty? then a.length
      else [(a[0] == b[0] ? 0 : 1) + lev_distance(a[1..-1], b[1..-1]),
            1 + lev_distance(a[1..-1], b),
            1 + lev_distance(a, b[1..-1])].min
    end
  end

end

