=begin

Usage: rake export_gml > out.gml
This will print the entire graph database out to a standard graph file format

=end


require 'rubygems'
require 'graph'

task :export_gml => :environment do
  # print GML header
  puts 'graph ['
  puts 'comment "This is a friendship visualization for arxiv"'
  puts 'directed 1'
  puts 'label "This a label"'

  # print all nodes
  articles = Article.all
  articles.each do |article|
    puts 'node ['
    puts 'id ' + article.id.to_s
    puts 'label "' + article.id.to_s + '"'
    puts ']'
  end

  # print all edges
  friendships = Friendship.all
  friendships.each do |friendship|
    puts 'edge ['
    puts 'edgeid ' + friendship.id.to_s
    puts 'source ' + friendship.article_id.to_s
    puts 'target ' + friendship.friend_id.to_s
    puts 'label "Edge from node ' + friendship.article_id.to_s + ' to node ' + friendship.friend_id.to_s + '"'
    puts ']'
  end

  puts ']'

end