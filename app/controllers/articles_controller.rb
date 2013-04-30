require 'awesome_print'
require 'levenshtein'
require 'tf_idf'

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


  def score(article_tf,terms,idf)
    tf_score = 0
    idf_score = 0

    if idf
      terms.each do |term|
        if article_tf[term]
          tf_score += article_tf[term]
        end
        if article_tf[term]
          idf_score += idf[term]
        end
      end
      return tf_score*idf_score
    else
      terms.each do |term|
        if article_tf[term]
          tf_score += article_tf[term]
        end
      end
      return tf_score
    end
  end

  def search
    query = params['query']

    #@articles = search_bool(query)
    #@articles = search_TF(query)
    @articles = search_TFIDF(query)
    #@articles = search_TFIDF_pagerank(query)

    @found = 1
    if @articles.nil?
      @msg = "None found, try again..."
      @found = 0
      @articles = []
    end
    render "articles"
    
  end

  def search_bool(query)
    terms = query.split(' ')
    articles_bool = []
    terms.each do |term|
      matches = Article.find(:all, conditions: ['summary LIKE ? and title LIKE ?', "%#{term}%", "%#{term}%"])
      matches.each do |article|
        if !articles_bool.include? article
          articles_bool << article
        end
      end
    end

    return articles_bool
    
  end

  def search_TF(query)
    terms = query.split(' ')
    puts terms
    articles_bool = search_bool(query)

    corpus = []
    articles_bool.each do |article|
      summary = article.summary
      split_summary = summary.split(' ')
      corpus << split_summary
    end

    analyzed = nil

    score_map = {}
    articles_bool.each do |article|
      summary = article.summary
      split_summary = summary.split(' ')
      article_tf = TfIdf.new([split_summary])
      score_map[article] = score(article_tf.tf[0],terms,analyzed)
    end

    @articles = articles_bool.sort_by { |article|
      -score_map[article]
    }

    return @articles
    
  end

  def search_TFIDF(query)
    terms = query.split(' ')
    puts terms
    articles_bool = search_bool(query)

    corpus = []
    articles_bool.each do |article|
      summary = article.summary
      split_summary = summary.split(' ')
      corpus << split_summary
    end

    analysis = TfIdf.new(corpus)
    analyzed = analysis.idf

    score_map = {}
    articles_bool.each do |article|
      summary = article.summary
      split_summary = summary.split(' ')
      article_tf = TfIdf.new([split_summary])
      score_map[article] = score(article_tf.tf[0],terms,analyzed)
    end

    @articles = articles_bool.sort_by { |article|
      -(score_map[article])
    }

    return @articles
    
  end


  def search_TFIDF_pagerank(query)
    terms = query.split(' ')
    puts terms
    articles_bool = search_bool(query)

    corpus = []
    articles_bool.each do |article|
      summary = article.summary
      split_summary = summary.split(' ')
      corpus << split_summary
    end

    analysis = TfIdf.new(corpus)
    analyzed = analysis.idf

    score_map = {}
    articles_bool.each do |article|
      summary = article.summary
      split_summary = summary.split(' ')
      article_tf = TfIdf.new([split_summary])
      score_map[article] = score(article_tf.tf[0],terms,analyzed)
    end

    @articles = articles_bool.sort_by { |article|
      pagerank = 1.0/article.keywords.length
      puts pagerank
      -(score_map[article]+pagerank)
    }

    return @articles
    
  end

  def get_works
    tag = params['query']

    @articles = get_articles(tag)
    
    @found = 1  
    if @articles.nil?
      @msg = "None found, try again..."
      @found = 0
      @articles = []
    end

    render "articles"

  end

  def get_articles(author_id)

    @author = Author.find(author_id)

    @articles = []
    @author.creations.each do |creation|
      temp = Article.find(creation.article_id)

      if !@articles.include? temp
        @articles << Article.find(creation.article_id)
      end

    end
    # puts "ARTICLES"

    # ap @articles

    return @articles
  end


  def show_authors
    tag = params['query']

    @article = Article.where('arxiv_id = ?', tag).first
    @authors = @article.authors
    # puts authors

    @found = 1
    if @authors.nil?
      @msg = "None found, try again..."
      @found = 0
      @authors = []
    end

    render "authors"
  end    



  def get_related_authors
    tag = params['query']

    @articles = get_articles(tag)
    # puts 'ARTICLES'
    # ap @articles

    @related_articles = []
    @authors = []

    @articles.each do |article|
      puts "ARTIClE ID "
      puts article.arxiv_id
      getRelatedPapers(article.arxiv_id, -1).each do |related|

        authors = related.authors
        authors.each do |author|

          if !@authors.include?(author)
            @authors << author
          end

        end
      end
    end
    

    @found = 1
    if @authors == []
      @msg = "None found, try again..."
      @found = 0
    end

    render "authors"
  end    


  def get_related
    tag = params['query']


    @articles = getRelatedPapers(tag, -1)
    @found = 1
    if @articles.nil?
      @msg = "None found, try again..."
      @found = 0
      @articles = []
    end

    render "articles"
  end

  def getRelatedPapers(curr_id, n)
    @article = Article.where('arxiv_id = ?', curr_id).first
    
    puts @article
    if @article == [] || @article.nil?
      puts 'articles NOT found'
      return nil
    end
    @valid_friends = []

    @friends = @article.friendships


    @friends.each do |friendship|
      friend = Article.find(friendship.friend_id)
      if friend.category == @article.category
        @valid_friends << friend
      end
    end

    Friendship.find(:all, conditions: {friend_id: @article.id}).each do |cited_by|
      @valid_friends << Article.find(cited_by.article_id)
      puts 'ADDED CITED BY'
    end

    puts "valid_friends"
    puts @valid_friends

    if @valid_friends == []
      puts 'NO VALID FRIENDS'
      return nil
    end

    temp = Hash.new()

    @valid_friends.each do |friend|
      keywords = @article.keywords.split(',')
      friend_keywords = friend.keywords.split(',')
      score = get_score(keywords, friend_keywords)
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
          if !@final_articles.include? article
            if article.id != @article.id
              @final_articles << article
            end
          end
        end

    end
    puts "FINAL"
    puts @final_articles


    if n == -1
      return @final_articles
    else 
      return @final_articles.first(n)
    end

  end

  def get_score(arr1, arr2)
    score = 0

    min = arr1

    if arr2.length < arr1.length
      min = arr2
    end

    for i in 0..min.length
      if !arr1[i].nil? && !arr2[i].nil?
        score += Levenshtein.distance(arr1[i], arr2[i])  
      end
    end

    return score
  end


  def lev_distance(a, b)
    puts 'finding lev'
    case
      when a.empty? then b.length
      when b.empty? then a.length
      else [(a[0] == b[0] ? 0 : 1) + lev_distance(a[1..-1], b[1..-1]),
            1 + lev_distance(a[1..-1], b),
            1 + lev_distance(a, b[1..-1])].min
    end
  end

end

