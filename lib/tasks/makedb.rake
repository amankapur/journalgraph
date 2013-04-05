require 'nokogiri'
require 'open-uri'


task :makedb do
	url = 'http://export.arxiv.org/api/query?search_query=all:electron&start=0&max_results='
	refs_url = 'http://arxiv.org/refs/1304.1032'
	#query_result = parseArxivQuery(url,1)
	refs_result = getReferences(refs_url)
	puts url
	#puts query_result
	puts refs_result
end


def parseArxivQuery(url,numresults)
	data = Hash.new
	url = url + numresults.to_s
	query = open(url,'Content-Type' => 'text/xml')
	doc = Nokogiri::XML(query)
	namespaces = doc.collect_namespaces()

	doc.xpath('//xmlns:entry').each do |entry|
		id = entry.at_xpath('.//xmlns:id')
		updated = entry.at_xpath('.//xmlns:updated')
		published = entry.at_xpath('.//xmlns:published')
		title = entry.at_xpath('.//xmlns:title')
		summary = entry.at_xpath('.//xmlns:summary')

		doi = doc.xpath('//arxiv:doi',namespaces)
		comment = doc.xpath('//arxiv:comment',namespaces)
		journal_ref   = doc.xpath('//arxiv:journal_ref',namespaces)
		primary_category = doc.xpath('//arxiv:primary_category',namespaces)
		doc.xpath('//arxiv:affiliation',namespaces)

		authors = entry.xpath('.//xmlns:author') #returns a nodeset

		authors_data = Hash.new
		authors.each do |author|
			author_name = author.at_xpath('.//xmlns:name').content
			author_affiliation = author.at_xpath('.//arxiv:affiliation',namespaces).content #returns a node
			authors_data[author_name] = author_affiliation #this is the mapping ot be stored in authors_data
		end

		data[id.content] = [updated.content, published.content, title.content, summary.content, authors_data]
	end
	#puts namespaces
	return data
end

def getReferences(url)
	query = open(url,'Content-Type' => 'text/html')
	doc = Nokogiri::HTML(query)
	#puts doc

	refs = doc.xpath('//dt/span[contains(@class,"list-identifier")]/a[contains(@title,"Abstract")]').content
	return refs
end