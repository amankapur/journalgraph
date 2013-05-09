=begin

Usage: rake extendgraph
Given an initial graph, we can choose which nodes to explore one level further
This helps us extend our graph in a controlled manner,
  ensuring we don't get rate-limited or banned from the arxiv domain

=end

require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'awesome_print'
require 'RubyDataStructures'

task :extendgraph => :environment do

	start = 325
	ending = 335

	arr = []
	(start..ending).each do |i|
		arr << i 
	end

	arr.each do |id|
		complete_graph(id)
	end

end



def complete_graph(id)
	puts id
	@article = Article.find(id)

	if @article == [] || @article.nil?
		puts "ARTICLE NOT FOUND!!"
		return nil
	end

	query_result = parseArxivId(@article.arxiv_id)

	citations = query_result[10]

	citations.each do |citation|
		puts citation
		make_node(@article, citation)
	end
end


# Creates a new database by article id

def make_node(article, id)

	if Article.find(:first, conditions: ['arxiv_id LIKE ?', "%#{id}%"]) == nil
		puts 'making new node'
		data = parseArxivId(id)
		new_article = create_Article(data)
		article.friendships.build(friend_id: new_article.id).save	
	else 
		old_article = Article.find(:first, conditions: ['arxiv_id LIKE ?', "%#{id}%"])
		if Friendship.where(article_id: article.id, friend_id: old_article.id) ==[]
			article.friendships.build(friend_id: old_article.id).save	
		end
	end
end


# Creates a new database entry given data from scraping

def create_Article(data)

	new_article =  Article.create(
				arxiv_id: data[11], 
				arxiv_url: data[0],
				update_date: data[1],
				published_date: data[2],
				title: data[3],
				summary: data[4],
				doi: data[5],
				comment: data[6],
				journal_ref: data[7], 
				category: data[8]
				)

	puts 'creating Article'
	do_Author(new_article, data)

	return new_article

end


# Gets the arxiv ids of the citations of an article by url

def getReferences(url)
	citations = []
	puts url
	query = open(url,'Content-Type' => 'text/html')

	doc = Nokogiri::HTML(query)

	refs = doc.xpath('//dt/span[contains(@class,"list-identifier")]/a[contains(@title,"Abstract")]')
	refs.each do |ref|
		# ap ref
		a = ref.content.match(/:(...*)/)[1]
		citations.push(a)
	end

	return citations


end


# Wrapper function for create_Authors

def do_Author(article, data)
	
	puts 'do_Author'

	id = article.arxiv_id
	all_data = data
	create_Authors(article, all_data[9])

end


# For each author in an article, create an author object in our database

def create_Authors(article, authors)
	@article = article

	puts 'createAuthors'
	ap authors

	authors.each do |author, value|
		if Author.where(name: author) == []
			@author = Author.create(name: author)
			@article.creations.build(author_id: @author.id).save
			puts 'author created'
		else
			@author = Author.where(name: author).first
			@article.creations.build(author_id: @author.id).save
			puts 'author existed'
		end
	end

end



# Scrapes arxiv for the article information from a specific arxiv id

def parseArxivId(arg_id)
	url = 'http://export.arxiv.org/api/query?id_list=' + arg_id

	data = Hash.new
	query = open(url,'Content-Type' => 'text/xml')
	doc = Nokogiri::XML(query)
	namespaces = doc.collect_namespaces()

	entry = doc.at_xpath('//xmlns:entry')

	url = entry.at_xpath('.//xmlns:id')
	updated = entry.at_xpath('.//xmlns:updated')
	published = entry.at_xpath('.//xmlns:published')
	title = entry.at_xpath('.//xmlns:title')
	summary = entry.at_xpath('.//xmlns:summary')

	doi = entry.at_xpath('.//arxiv:doi',namespaces)
	comment = entry.at_xpath('.//arxiv:comment',namespaces)
	journal_ref   = entry.at_xpath('.//arxiv:journal_ref',namespaces)
	primary_category = entry.at_xpath('.//arxiv:primary_category',namespaces)

	id = nil

	if url 
		url = url.content
		id = url.match(/abs\/(...*)/)[1]
	end

	if updated
		updated = updated.content
	end
	if published
		published = published.content
	end
	if title
		title = title.content
	end
	if summary
		summary = summary.content
	end
	if doi
		doi = doi.content
	end
	if comment
		comment = comment.content
	end
	if journal_ref
		journal_ref = journal_ref.content
	end
	if primary_category
		primary_category = primary_category['term']
	end


	authors = entry.xpath('.//xmlns:author') #returns a nodeset

	authors_data = Hash.new
	authors.each do |author|
		author_name = author.at_xpath('.//xmlns:name')
		author_affiliation = author.at_xpath('.//arxiv:affiliation',namespaces) #returns a node
		if author_name
			author_name = author_name.content
		end
		if author_affiliation
			author_affiliation = author_affiliation.content
		end
		authors_data[author_name] = author_affiliation #this is the mapping to be stored in authors_data
	end

	refs_url = url.dup
	refs_url["/abs/"] = "/refs/"
	citations = getReferences(refs_url)

	final = [url,
		updated,
		published,
		title,
		summary,
		doi,
		comment,
		journal_ref,
		primary_category,
		authors_data,
		citations,
		id]

	return final
end