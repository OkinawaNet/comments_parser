require 'nokogiri'
require 'open-uri'
require 'csv'
require 'capybara'
require 'capybara/dsl'

TAGS = %w(best cat compilation).freeze
PATH = "www.youtube.com"
RESULT_FILE = 'searches.csv'

class CommentsParser
  include Capybara::DSL
  Capybara.default_driver = :selenium

   def parse(url)
     page.visit url
     sleep 5

     doc = Nokogiri::HTML(page.html)
     doc.css('ytd-comment-renderer #content-text').map { |link| link.children.text }.compact.uniq
   end

   def self.parse(url)
     new.parse(url)
   end
end

def get_tagged_pages(tags)
  uri = URI::HTTP.build(host: PATH, path: '/results', query: URI.encode_www_form({ search_query: tags.join(' ') }))
  doc = Nokogiri::HTML(open(uri))
  doc.css('a').map { |link| link['href'] if link['href'].include?('watch') }.compact.uniq
end

links = get_tagged_pages(TAGS)

CSV.open(RESULT_FILE, 'wb') do |csv|
  links.each do |link|
    url = "https://#{PATH}#{link}"

    comments = CommentsParser.parse(url)

    comments.each do |comment|
      csv << [comment]
    end

    pp "Found #{comments.count} comments on #{url}"
  end
end
