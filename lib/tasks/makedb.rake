require 'nokogiri'
require 'open-uri'
require 'awesome_print'

task :makedb do
	#url = 'http://export.arxiv.org/api/query?search_query=abs:electron&cat:hep-lat&start=0&max_results='
	url = 'http://export.arxiv.org/api/query?search_query=abs:energy&start=0&max_results=5'
	query_result = parseArxivQuery(url,20)
	ap query_result
	#refs_url = 'http://arxiv.org/refs/1304.1032'
	#refs_result = getReferences('http://arxiv.org/refs/hep-ex/9406005v1')
	#puts refs_result
end


def parseArxivQuery(url,numresults)
	data = Hash.new
	#url = url + numresults.to_s
	query = open(url,'Content-Type' => 'text/xml')
	doc = Nokogiri::XML(query)
	namespaces = doc.collect_namespaces()
	puts namespaces

	doc.xpath('//xmlns:entry').each do |entry|
		id = entry.at_xpath('.//xmlns:id')
		updated = entry.at_xpath('.//xmlns:updated')
		published = entry.at_xpath('.//xmlns:published')
		title = entry.at_xpath('.//xmlns:title')
		summary = entry.at_xpath('.//xmlns:summary')

		doi = entry.at_xpath('.//arxiv:doi',namespaces)
		comment = entry.at_xpath('.//arxiv:comment',namespaces)
		journal_ref   = entry.at_xpath('.//arxiv:journal_ref',namespaces)
		primary_category = entry.at_xpath('.//arxiv:primary_category',namespaces)

		if id
			id = id.content
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
			author_name = author.at_xpath('.//xmlns:name').content
			#author_affiliation = author.at_xpath('.//arxiv:affiliation',namespaces).content #returns a node
			author_affiliation = nil
			authors_data[author_name] = author_affiliation #this is the mapping ot be stored in authors_data
		end

		refs_url = id.dup
		refs_url["/abs/"] = "/refs/"
		citations = getReferences(refs_url)

		#puts "refurl " + refs_url
		#puts "citation  " + citations.to_s

		data[id] = [updated,
			published,
			title,
			summary,
			doi,
			comment,
			journal_ref,
			primary_category,
			authors_data,
			citations]
	end
	#puts namespaces
	return data
end

def getReferences(url)
	citations = []
	query = open(url,'Content-Type' => 'text/html')
	doc = Nokogiri::HTML(query)
	#puts doc

	refs = doc.xpath('//dt/span[contains(@class,"list-identifier")]/a[contains(@title,"Abstract")]')
	#refs.map { |ref| ref.content }
	refs.each do |ref|
		citations.push(ref.content)
	end
	return citations
end