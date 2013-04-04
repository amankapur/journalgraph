require 'nokogiri'
require 'open-uri'


task :makedb do 
	# JIMMY PUT YOUR SCRIPT IN HERE
end


class ArxivEntry
	def initialize id, updated, published, title, summary
		@id = id
		@updated = updated
		@published = published
		@title = title
		@summary = summary
	end
end

# Do funky things with it using Nokogiri::XML::Node methods...

def parseArxivQuery(url,numresults)
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
		authors = entry.xpath('.//xmlns:author') #returns a nodeset
		#uthor_affiliations = doc.xpath('//arxiv:affiliation',namespaces) #returns a nodeset
		doi = doc.xpath('//arxiv:doi',namespaces)
		comment = doc.xpath('//arxiv:comment',namespaces)
		journal_ref   = doc.xpath('//arxiv:journal_ref',namespaces)
		primary_category = doc.xpath('//arxiv:primary_category',namespaces)
		doc.xpath('//arxiv:affiliation',namespaces)

		#puts authors + ' ' + affiliation.first.content
		print id.content
		print updated.content
		print published.content
		print title.content
		print summary.content
		print authors.first.content# + affiliation
	end

	puts namespaces
	#p doc.xpath('//*[@*[xmlns:arxiv="http://arxiv.org/schemas/atom"]]')

end

# Get a Nokogiri::HTML::Document for the page we’re interested in...
url = 'http://export.arxiv.org/api/query?search_query=all:electron&start=0&max_results='
parseArxivQuery(url,25)