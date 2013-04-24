require 'rubygems'
require 'summarize'

task :make_summary => :environment do
    all_articles = Article.all
    all_articles.each do |article|
        text = article.summary
        if text
        topics = text.summarize(topics: true)[1]
        article.update_attributes(keywords: topics)
        end
    end

end
