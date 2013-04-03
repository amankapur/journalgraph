class Creation < ActiveRecord::Base
  attr_accessible :article_id, :author_id
  belongs_to :article
  belongs_to :author
end
