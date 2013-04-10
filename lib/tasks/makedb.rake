require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'awesome_print'
require 'RubyDataStructures'

task :makedb => :environment do

	#url = 'http://export.arxiv.org/api/query?search_query=abs:electron&cat:hep-lat&start=0&max_results='

	url = 'http://export.arxiv.org/api/query?search_query=abs:energy&start=0&max_results=5'
	query_result = parseArxivQuery(url)
	ap query_result


	#attr_accessible :arxiv_id, :arxiv_url, :published_date, :summary, :title, :update_date, :journal_ref, :doi, :comment, :category
	#data[id] = [url, updated, published, title, summary, doi, comment, journal_ref, primary_category, authors_data, citations]


	max_count = 2000

	queue = RubyDataStructures::QueueAsArray.new(1000)

	query_result.each do |key, stuff|
		queue.enqueue(stuff)
	end

	while !queue.empty?
		data = queue.dequeue()
		ap data
		if data
			# puts 'data id is   :::    ' + data[11].to_s
		end
		if data[10].length > 100
			next
		end

		if Article.where(arxiv_id: data[11]) == []
			@article = createArticle(data)
		else
			@article = Article.where(arxiv_id: data[11]).first
		end

		# puts @article.creations

		authors = data[9]
		puts authors
		# puts 'AUTHOR LENGTH is :::::  ' + authors.length.to_s
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

		citations = data[10]
		# puts citations
		citations.each do |citation|
			# ap citation
			data = parseArxivId(citation)

			if Article.where(arxiv_id: citation) == []
				@cited_article = createArticle(parseArxivId(citation))
				@article.friendships.build(friend_id: @cited_article.id).save	
				puts 'citation article created'	
			else
				@cited_article = Article.where(arxiv_id: citation)
				if Friendship.where(article_id: @article.id, friend_id: @cited_article.id) != []
					@article.friendships.build(friend_id: @cited_article.id).save		
				end
			end

			if Article.count < max_count
				queue.enqueue(data)
			else
				puts  'REACHED MAXIMUM##################### '
			end

		end #each citation loop

	end  #end while

end #end task



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

def parseArxivQuery(url)
	data = Hash.new
	query = open(url,'Content-Type' => 'text/xml')
	doc = Nokogiri::XML(query)
	namespaces = doc.collect_namespaces()
	# puts namespaces
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
		# puts refs_url
		citations = getReferences(refs_url)

		#puts "refurl " + refs_url
		#puts "citation  " + citations.to_s

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
	#puts namespaces
	return data
end

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