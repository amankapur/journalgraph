require 'rubygems'
require 'graph'

task :make_graph => :environment do

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

end