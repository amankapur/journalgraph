require 'nokogiri'
require 'open-uri'


# Get a Nokogiri::HTML::Document for the page we’re interested in...
url = 'http://export.arxiv.org/api/query?search_query=all:electron&start=0&max_results='
parseArxivQuery(url,100)

# Do funky things with it using Nokogiri::XML::Node methods...

def parseArxivQuery(url,numresults)
	url = url + numresults.to_s
	query = open(url,'Content-Type' => 'text/xml')
	doc = Nokogiri::XML(query)

	doc.xpath('//xmlns:entry//xmlns:id').each do |link|
		puts 'id ' + link.content
	end

end
