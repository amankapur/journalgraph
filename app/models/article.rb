class Article < ActiveRecord::Base
  attr_accessible :arxiv_id, :arxiv_url, :published_date, :summary, :title, :update_date

  has_many :creations
  has_many :authors, :through => :creations
end
