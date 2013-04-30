require 'rubygems'
require 'matrix'
require 'ap'

task :make_pagerank => :environment do
	amount = Article.count
	A = []
	(1..amount).each do |i| #targets
		inward = Friendship.where("friend_id = ?", i) #friendships ending in i
		article_ids = []
		inward.each do |ship|
			article_ids << ship.article_id #articles pointing to i
		end
		row = []
		(1..amount).each do |j| #sources
			if article_ids.include? j #is j pointing to i?
				len = Friendship.where("article_id = ?",j).count #how many articles does j point to?
				#puts 'j: ' + j.to_s + ', len: ' + len.to_s
				row << 1.0/len
			else
				row << 0
			end
		end
		A << row
	end

	mat = Matrix.rows(A)

	puts "Matrix created"

	ranks = pagerank(mat)

	puts "Finished calculating matrix!"

	v = []

	ranks.each(:all) do |item|
		v << item
	end

	ap v

	(0..amount).each do |i|
		#puts v[i]
		Article.find(i+1).update_attributes(pagerank: v[i])
	end

end

def pagerank(g)
	size = g.row_size()
	i = Matrix.identity(size)                       # identity matrix
	#p = (1.0/size) * Matrix.ones(size,1)  # teleportation vector

	v = []
	contrib = 1.0/size
	(1..size).each do |i|
		v << contrib
	end
	p = Matrix.column_vector(v) # teleportation vector

	s = 0.85  # probability of following a link
	t = 1-s   # probability of teleportation

	return t*((i-s*g).inverse)*p
end