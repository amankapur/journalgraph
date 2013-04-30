class Article < ActiveRecord::Base
  attr_accessible :arxiv_id, :arxiv_url, :published_date, :summary, :title, :update_date, :journal_ref, :doi, :comment, :category, :keywords, :pagerank

  has_many :creations
  has_many :authors, :through => :creations
  
	has_many :friendships
	has_many :friends, :through => :friendships, :uniq => true
	has_many :inverse_friendships, :class_name => "Friendship", :foreign_key => "friend_id"
	has_many :inverse_friends, :through => :inverse_friendships, :source => :user
end
