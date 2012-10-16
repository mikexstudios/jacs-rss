require 'sinatra'

require 'mechanize' #use mechanize since it handles setting cookies
require 'uri'
#require 'builder'

url = 'http://pubs.acs.org/toc/jacsat/0/ja' 
uri = URI.parse(url)
base_url = '%s://%s' % [uri.scheme, uri.host]

get '/' do
  "Hello, world"
end

get '/just_accepted.atom' do
  agent = Mechanize.new
  page = agent.get('http://pubs.acs.org/toc/jacsat/0/ja')
  articles = page.search('.articleBoxMeta')

  builder do |atom|
    atom.instruct!
    atom.feed 'xmlns' => 'http://www.w3.org/2005/Atom' do
      atom.id url
      atom.updated Time.now.utc.iso8601(0)
      atom.title 'Journal of the American Chemical Society - Just Accepted Manuscripts', :type => 'text'
      atom.link :rel => "self", :href => "/just_accepted.atom"
    
      articles.each do |a|
        title = a.at_css('.titleAndAuthor h2 a').content
        link = a.at_css('.titleAndAuthor h2 a')['href']
        link = '%s%s' % [base_url, link]
        authors = a.at_css('.articleAuthors').content
        
        #The date comes right after <strong>Publication date (Web):</strong>
        date = a.at_css('.epubdate strong').next.content
        date = DateTime.parse(date)
        type = a.at_css('.NLM_title').content
        #DOI comes after <strong>DOI:</strong>
        doi = a.at_css('.DOI strong').next.content
        doi.strip!
    
        atom.entry do
          atom.title title
          atom.author authors
          atom.link 'href' => link
          atom.id doi
          atom.published date.iso8601(0)
          atom.updated date.iso8601(0)
        end
      end
    end
  end

end
