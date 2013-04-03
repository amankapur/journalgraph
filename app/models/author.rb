class Author < ActiveRecord::Base
  attr_accessible :name

  has_many :creations
  has_many :articles, :through => :creations
end
