
class ArticlesController < ApplicationController
  # GET /articles
  # GET /articles.json
  def index    

  end

  # GET /articles/1
  # GET /articles/1.json
  def show
    @article = Article.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @article }
    end
  end

  def search
    # puts params['query']
    
    tag = params['query']

    @articles = getRelatedPapers(tag)

    @found = 1
    if @articles.nil?
      @msg = "None found, try again..."
      @found = 0
    end

    render "articles"
    
  end

  def getRelatedPapers(curr_id)
    @article = Article.where('arxiv_id = ?', curr_id).first

    if @article == []
      return []
    end
    @valid_friends = []

    @friends = @article.friendships

    @friends.each do |friendship|

      friend = Article.find(friendship.friend_id)

      if friend.category == @article.category
        @valid_friends << friend
      end
    end

    return @valid_friends

  end

end

