class Friendship < ActiveRecord::Base
  attr_accessible :article_id, :friend_id
  
  belongs_to :article
  belongs_to :friend, :class_name => "Article"
end
