=begin

Usage: rake make_pagerank
Runs pagerank on the entire database, updates each entry with a pagerank value
Runtime for our database: ~1 hour

Terminology:
target refers to the end of a directed link in the graph
source refers to the beginning of a directed link

Connections in our graph look like this:
source --------> target

We call a connection by citation a "friendship"

=end

require 'rubygems'
require 'matrix'
require 'ap'

task :make_pagerank => :environment do

	# ****************************************************************************
	# The first part of this program constructs the transition probability matrix for our graph
	# Here is an example transition probability matrix,
	#   where each directed edge coming out of a node is weighted by 1/n,
	#   where n is that node's total number of outgoing edges
	#
	#     a   b   c   d
	# a | 0   0  .33  0  |
	# b | 1   0  .33  0  |
	# c | 0   0   0   0  |
	# d | 0   1  .33  0  |
	#
	# This matrix represents the following graph:
	# a ----> b
	# ^     /^|
	# |   /   |
	# | /     |/
	# c ----> d
	# 
	# Each row corresponds to an article which is being cited.
	# 
	# ****************************************************************************

	amount = Article.count # specify number of articles here. this can be lowered for testing purposes
	A = []
	(1..amount).each do |i| # for each target i
		inward = Friendship.where("friend_id = ?", i) # get all friendships ending at i
		article_ids = []
		inward.each do |ship|
			article_ids << ship.article_id # get sources j which have a friendship pointing to i
		end

		row = [] # Get all edges which cite target i

		(1..amount).each do |j| # for each source j
			if article_ids.include? j # is j pointing to i?
				len = Friendship.where("article_id = ?",j).count # how many articles does j point to?
				row << 1.0/len
			else
				row << 0
			end
		end
		A << row
	end

	# ****************************************************************************
	# The second part of this program runs the pagerank function on the matrix representation of our graph
	# 
	# ****************************************************************************
	mat = Matrix.rows(A) # create the ruby Matrix object

	ranks = pagerank(mat) # calculate pagerank

	v = [] # store the ranking for each article
	ranks.each(:all) do |item|
		v << item
	end
	ap v # print the rankings

	(0..amount).each do |i| # update the database entry with the rank
		Article.find(i+1).update_attributes(pagerank: v[i])
	end

end

	# ****************************************************************************
	# Pagerank works as follows:
	# The transition probability matrix is an operator for a dynamical system
	# This system represents a "liquid" that "flows" between each of our nodes
	# The amount of "liquid" is essentially the ranking of the node
	# Nodes with higher amounts of "liquid" tend to have more incoming directed edges with more weight
	# The steady state vector (the state when the liquid has been allowed to flow for a long time)
	#   is the pagerank vector we are looking for
	# 
	# You might see a constant below which we label "probability of teleportation"
	# This is simply how we simulate the flow in this system. If there is a node with no
	#   outgoing links then liquid will "pile up" there, leading to inaccurate results
	# Therefore, every time step, there is a probability that we will teleport to
	#   a different node instead of following the links given in our system
	#
	# ****************************************************************************

def pagerank(g)
	size = g.row_size()
	i = Matrix.identity(size) # identity matrix

	v = []
	contrib = 1.0/size
	(1..size).each do |i|
		v << contrib
	end
	p = Matrix.column_vector(v) # pagerank vector

	s = 0.85  # probability of following a link
	t = 1-s   # probability of teleportation

	return t*((i-s*g).inverse)*p
end