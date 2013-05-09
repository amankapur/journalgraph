=begin

Usage: rake makedb

Scrapes arxiv using initial conditions set in this program
For each article being scraped, generates database entries as well as links

We first grab a small set of initial articles
Then we expand from these articles' citations, ensuring connectedness
	
=end

require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'awesome_print'
require 'RubyDataStructures'

task :makedb => :environment do

	# Given an initial query, grab the first five articles

	url = 'http://export.arxiv.org/api/query?search_query=abs:energy&start=0&max_results=5'
	query_result = parseArxivQuery(url)

	max_count = 2000 # Limits the number of articles to grab

	# Put the initial articles in a queue
	queue = RubyDataStructures::QueueAsArray.new(1000)
	query_result.each do |key, stuff|
		queue.enqueue(stuff)
	end


	while !queue.empty? # While queue is not empty, pop articles off
		data = queue.dequeue() # For each article popped

		if data[10].length > 100
			next
		end

		tag = data[11]
		if Article.find(:first, conditions: ['arxiv_id LIKE ?', "%#{tag}%"])  == nil
			@article = createArticle(data) # Generate a database entry
		else
			puts 'Article already exists'
			puts tag
			@article = Article.find(:first, conditions: ['arxiv_id LIKE ?', "%#{tag}%"])
		end

		# Generate "Creation" links in our graph (links an author to the article written by the author)
		authors = data[9]
		authors.each do |author, value|
			if Author.where(name: author) == []	# If author does not exist in database, create the author node and link
				@author = Author.create(name: author)
				@article.creations.build(author_id: @author.id).save
				puts 'author created'
			else								# If author already exists, just create the link
				@author = Author.where(name: author).first
				@article.creations.build(author_id: @author.id).save
				puts 'author existed'
			end
		end

		# Generate "Friendship" links in our graph (links an article to a cited article)
		# For each article in the queue, add its cited articles to the queue
		citations = data[10]
		citations.each do |citation|
			data = parseArxivId(citation)

			if Article.find(:first, conditions: ['arxiv_id LIKE ?', "%#{citation}%"]) == nil
				@cited_article = createArticle(parseArxivId(citation))
				@article.friendships.build(friend_id: @cited_article.id).save
				puts 'citation article created'
			else
				@cited_article = Article.find(:first, conditions: ['arxiv_id LIKE ?', "%#{citation}%"])
				if Friendship.where(article_id: @article.id, friend_id: @cited_article.id) == []
					@article.friendships.build(friend_id: @cited_article.id).save
					
					puts 'edge made with existing article...'
					puts citation
					puts @article.id
					puts @cited_article.id	
				end
			end

			if Article.count < max_count
				queue.enqueue(data)
			else
				puts 'REACHED MAXIMUM##################### '
			end

		end #each citation loop

	end  #end while

end #end task



# Creates a new database entry

def createArticle(data)
	return Article.create(
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
end



# Scrapes arxiv for a single article by url

def parseArxivQuery(url)
	data = Hash.new
	query = open(url,'Content-Type' => 'text/xml')
	doc = Nokogiri::XML(query)
	namespaces = doc.collect_namespaces()
	puts 'parsing Query'
	doc.xpath('//xmlns:entry').each do |entry|

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


		authors = entry.xpath('.//xmlns:author') # returns a nodeset

		authors_data = Hash.new
		authors.each do |author|
			author_name = author.at_xpath('.//xmlns:name')
			author_affiliation = author.at_xpath('.//arxiv:affiliation',namespaces) # returns a node
			if author_name
				author_name = author_name.content
			end
			if author_affiliation
				author_affiliation = author_affiliation.content
			end
			authors_data[author_name] = author_affiliation # this is the mapping ot be stored in authors_data
		end

		refs_url = url.dup
		refs_url["/abs/"] = "/refs/"
		citations = getReferences(refs_url)

		data[id] = [url,
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
	end

	return data
end



# Gets the arxiv ids of the citations of an article by url

def getReferences(url)
	citations = []
	puts url
	query = open(url,'Content-Type' => 'text/html')

	doc = Nokogiri::HTML(query)

	refs = doc.xpath('//dt/span[contains(@class,"list-identifier")]/a[contains(@title,"Abstract")]')
	refs.each do |ref|
		a = ref.content.match(/:(...*)/)[1]
		citations.push(a)
	end

	return citations
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
		author_affiliation = author.at_xpath('.//arxiv:affiliation',namespaces) # returns a node
		if author_name
			author_name = author_name.content
		end
		if author_affiliation
			author_affiliation = author_affiliation.content
		end
		authors_data[author_name] = author_affiliation # this is the mapping to be stored in authors_data
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