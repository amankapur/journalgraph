=begin

Usage: rake make_summary
Runs a summarization program on each article in the database.
1. Obtains a set of keywords deemed to be important to each article.
2. Updates the "keywords" field for each article entry
	
=end

require 'rubygems'
require 'summarize'

task :make_summary => :environment do
    all_articles = Article.find(:all, conditions: {keywords: nil})
    all_articles.each do |article|
        text = article.summary
        if text
        topics = text.summarize(topics: true)[1]
        article.update_attributes(keywords: topics)
        end
    end

end
