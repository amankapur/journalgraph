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

  ### This function is called when 'magic' button is clicked

  def search
    query = params['query']       # query sent by user
    searchtype = params['searchtype']   # what type of search is this
    
    # based on search type, call the appropriate search function

    case searchtype
      when 'boolean' then @articles = search_bool(query)
      when 'tf' then @articles = search_TF(query)
      when 'tfidf' then @articles = search_TFIDF(query)
      when 'pagerank' then @articles = search_pagerank(query)
      when 'pageranktfidf' then @articles = search_TFIDF_pagerank(query)
      else @articles = nil
    end

    ap @articles
    @found = 1
    if @articles.nil?
      @msg = "None found, try again..."
      @found = 0
      @articles = []
    end
    render "articles"
    
  end

  # simple boolean search for whether query terms exist in the summary of articles

  def search_bool(query)
    ap "!!!!!!!!!!!!!!!!!!! SEARCH BOOL CALLED WITH query " + query.to_s
    terms = query.split(' ')

    articles_bool = []
    terms.each do |term|
      ap "!!!!!! TERM !!!!"
      ap term
      matches = Article.find(:all, conditions: ['summary LIKE ? and title LIKE ?', "%#{term}%", "%#{term}%"])
      ap "!!!!!!!! MATCHES !!!!!"
      ap matches
      matches.each do |article|
        if !articles_bool.include? article
          articles_bool << article
        end
      end
    end

    return articles_bool
    
  end

  # search based on Term frequency

  def search_TF(query)
    terms = query.split(' ')
    puts terms
    articles_bool = search_bool(query)    # first get a simple boolean search of articles


    # create the corpus of articles 
    corpus = []
    articles_bool.each do |article|
      summary = article.summary
      split_summary = summary.split(' ')
      corpus << split_summary
    end

    analyzed = nil

    # make a hash of TF for each of the articles 
    score_map = {}
    articles_bool.each do |article|
      summary = article.summary
      split_summary = summary.split(' ')
      article_tf = TfIdf.new([split_summary])
      score_map[article] = score(article_tf.tf[0],terms,analyzed)
    end

    # rank this hash by TF and return the articles

    @articles = articles_bool.sort_by { |article|
      -score_map[article]
    }

    return @articles
    
  end


  # TFIDF based search 

  def search_TFIDF(query)
    terms = query.split(' ')
    puts terms
    articles_bool = search_bool(query)


    # make a corpus
    corpus = []
    articles_bool.each do |article|
      summary = article.summary
      split_summary = summary.split(' ')
      corpus << split_summary
    end

    # get IDF values using TFIdf library
    analysis = TfIdf.new(corpus)
    analyzed = analysis.idf


    # get TfIdf scores for each of the articles into a hash

    score_map = {}
    articles_bool.each do |article|
      summary = article.summary
      split_summary = summary.split(' ')
      article_tf = TfIdf.new([split_summary])
      score_map[article] = score(article_tf.tf[0],terms,analyzed)
    end

    # rank by the score and return articles

    @articles = articles_bool.sort_by { |article|
      -(score_map[article])
    }

    return @articles
    
  end


  # Page rank search

  def search_pagerank(query)
    terms = query.split(' ')
    puts terms
    articles_bool = search_bool(query)  # get boolean matches first

    # rank these based on page rank vector

    @articles = articles_bool.sort_by { |article|
      pagerank = article.pagerank   # page rank is a model attribute since its is a independent of the query
      puts pagerank
      -(pagerank)
    }
    return @articles
  end


  # Page rank and TfIdf search

  def search_TFIDF_pagerank(query)
    terms = query.split(' ')
    puts terms
    articles_bool = search_bool(query)  # get boolean articles first

    corpus = []

    # make the corpus 

    articles_bool.each do |article|
      summary = article.summary
      split_summary = summary.split(' ')
      corpus << split_summary
    end

    # get TFIDF article hash

    analysis = TfIdf.new(corpus)
    analyzed = analysis.idf

    score_map = {}
    articles_bool.each do |article|
      summary = article.summary
      split_summary = summary.split(' ')
      article_tf = TfIdf.new([split_summary])
      score_map[article] = score(article_tf.tf[0],terms,analyzed)
    end

    # get pankrank values and sort on the sum of TfIdf and pagerank
    @articles = articles_bool.sort_by { |article|
      pagerank = article.pagerank
      puts pagerank
      -(score_map[article]+pagerank)
    }

    return @articles
    
  end


  # called when show_authors_papers is called on the client

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

  # helper function with gets articles based on author id

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


  # gets all authors of a certain article

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


  # called when get related authors is called

  def get_related_authors
    tag = params['query']

    @articles = get_articles(tag)   # gets all articles of this author
    # puts 'ARTICLES'
    # ap @articles

    @related_articles = []
    @authors = []

    # for each of the author's articles, get 1st degree articles and their respective authors
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

  # called  when get related papers is called on client

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

  # helper function takes in id of the article passed in by client, and n which is number of articles to be returned

  def getRelatedPapers(curr_id, n)
    @article = Article.where('arxiv_id = ?', curr_id).first   # get the article passed in from DB
    
    puts @article
    if @article == [] || @article.nil?
      puts 'articles NOT found'
      return nil
    end
    @valid_friends = []

    @friends = @article.friendships # this returns all 1 degree close articles

    # if they are in the same category, store in valid friends
    @friends.each do |friendship|
      friend = Article.find(friendship.friend_id)
      if friend.category == @article.category
        @valid_friends << friend
      end
    end

    # get all inwards edges for this artcle
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

    # Make a hash for each of these filtered articles
    # the key for this hash the score, and value is the article

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

    # sort based on the score and return the articles.

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

  # gets the Levenshtein distance between the 2 keyword arrays. 

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

end

