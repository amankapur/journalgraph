require 'rubygems'
require 'graph'

task :export_gml => :environment do
  puts 'graph ['
  puts 'comment "This is a friendship visualization for arxiv"'
  puts 'directed 1'
  puts 'label "Hi I am dat pretty mofo"'

  articles = Article.all
  articles.each do |article|
    puts 'node ['
    puts 'id ' + article.id.to_s
    puts 'label "' + article.id.to_s + '"'
    puts ']'
  end

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
=begin
  digraph do

    friendships = Friendship.all

    friendships.each do |friendship|
      # puts friendship.friend_id
      # puts friendship.article_id

      edge friendship.friend_id friendship.article_id
      
    end

    node_attribs << lightblue << filled
    save 'languages', 'png'

  end
=end

#puts: inserts newline
#print: no newline
#p: in quotes
