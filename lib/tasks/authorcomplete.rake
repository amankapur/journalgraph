=begin

Usage: rake authorcomplete

We ran into rate-limiting issues while scraping the arxiv domain
This caused our graph to be incompete at some parts
This script allows us to ensure graph integrity by filling in missing authors
	
=end


require 'rubygems'
require 'awesome_print'

task :authorcomplete => :environment do
    all_articles = Article.all
    todo_articles = []
    all_articles.each do |article|
    	if article.authors == []
    		todo_articles << article
    	end
    end

    i = 0
    count = todo_articles.length
    puts "TODO ARTICLES LEFT: ", todo_articles.length

end


def doAuthor(article)
	
	id = article.arxiv_id
	puts 'COMPLETEING ID ', article.id

	all_data = parseArxivId(id)

	puts all_data[9].length
	puts all_data[10].length

	createAuthors(article, all_data[9])

	createCitations(article, all_data[10])

	puts "!!!!!!!! AFTER COUNT !!!!!!"
	article = Article.find(article.id)
	puts article.authors.length
	puts article.friendships.length
end


def createAuthors(article, authors)
	@article = article


	authors.each do |author, value|
		if Author.where(name: author) == []
			@author = Author.create(name: author)
			@article.creations.build(author_id: @author.id).save
			# puts 'author created'
		else
			@author = Author.where(name: author).first
			@article.creations.build(author_id: @author.id).save
			# puts 'author existed'
		end
	end

end

def createCitations(article, citations)
	
	@article = article

	citations.each do |citation|
			# ap citation
			# data = parseArxivId(citation)

			if Article.find(:first, conditions: ['arxiv_id LIKE ?', "%#{citation}%"]) == nil
				# @cited_article = createArticle(parseArxivId(citation))
				# @article.friendships.build(friend_id: @cited_article.id).save	
				puts 'not creating new article'

			else
				@cited_article = Article.find(:first, conditions: ['arxiv_id LIKE ?', "%#{citation}%"])
				if Friendship.where(article_id: @article.id, friend_id: @cited_article.id) == []
					@article.friendships.build(friend_id: @cited_article.id).save	
					
					# puts 'edge made with existing article...'
					# puts citation
					# puts @article.id
					# puts @cited_article.id	
				end
			end

		end #each citation loop
end



def parseArxivId(arg_id)
	url = 'http://export.arxiv.org/api/query?id_list=' + arg_id

	data = Hash.new
	query = open(url,'Content-Type' => 'text/xml')
	doc = Nokogiri::XML(query)
	namespaces = doc.collect_namespaces()
	# puts namespaces

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
		# puts url
		id = url.match(/abs\/(...*)/)[1]
		# puts id
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
		authors_data[author_name] = author_affiliation #this is the mapping ot be stored in authors_data
	end

	refs_url = url.dup
	refs_url["/abs/"] = "/refs/"
	citations = getReferences(refs_url)

	#puts "refurl " + refs_url
	#puts "citation  " + citations.to_s

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
	#puts namespaces
	return final

end