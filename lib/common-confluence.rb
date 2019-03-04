# frozen_string_literal: true

require 'json'
require 'csv'
require 'fileutils'
require 'dotenv/load'
require 'rest-client'
require 'base64'

# Check that the correct ruby version is being used.
version = File.read('.ruby-version').strip
puts "Ruby version: #{RUBY_VERSION}"
unless RUBY_VERSION == version
  puts "Ruby version = '#{version}' is required, run the following command first:"
  puts "rvm use #{version}"
  exit
end

# Load environment
DEBUG = ENV['DEBUG'] == 'true'
DATA = ENV['DATA'] || 'data/confluence'
IMAGES = ENV['IMAGES'] || 'data/confluence/images'
DOCUMENTS = ENV['DOCUMENTS'] || 'data/confluence/documents'
WIKI = ENV['ASSEMBLA_WIKI'] || throw('ASSEMBLA_WIKI must be defined')
API = ENV['CONFLUENCE_API'] || throw('CONFLUENCE_API must be defined')
SPACE = ENV['CONFLUENCE_SPACE'] || throw('CONFLUENCE_SPACE must be defined')
EMAIL = ENV['CONFLUENCE_EMAIL'] || throw('CONFLUENCE_EMAIL must be defined')
PASSWORD = ENV['CONFLUENCE_PASSWORD'] || throw('CONFLUENCE_PASSWORD must be defined')

# Global constants
LINKS_CSV = "#{DATA}/links.csv"
UPLOADED_IMAGES_CSV = "#{DATA}/uploaded-images.csv"
CREATED_PAGES_CSV = "#{DATA}/created-pages.csv"
CREATED_PAGES_NOK_CSV = "#{DATA}/created-pages-nok.csv"
UPDATED_PAGES_CSV = "#{DATA}/updated-pages.csv"
WIKI_FIXED_CSV = "#{DATA}/wiki-pages-fixed.csv"

# Display environment
puts
puts "DEBUG:    : '#{DEBUG}'"
puts "DATA      : '#{DATA}'"
puts "IMAGES    : '#{IMAGES}'"
puts "DOCUMENTS : '#{DOCUMENTS}'"
puts "WIKI      : '#{WIKI}'"
puts "API       : '#{API}'"
puts "SPACE     : '#{SPACE}'"
puts "EMAIL     : '#{EMAIL}'"
puts

# Create directories if not already present
[DATA, IMAGES, DOCUMENTS].each { |dir| Dir.mkdir(dir) unless File.exist?(dir) }

# Authentication header
HEADERS = {
    'Authorization': "Basic #{Base64.encode64("#{EMAIL}:#{PASSWORD}")}",
    'Content-Type': 'application/json; charset=utf-8',
    'Accept': 'application/json'
}.freeze

# The Assembla HTML is a complete mess! Ensure that the html can be  parsed
# by the confluence api, e.g. avoid the dreaded 'error parsing xhtml' error.
def fix_html(html)
  result = html.
      gsub('<br>', '<br/>').
      gsub('<wbr>', '&lt;wbr&gt;').
      gsub('<package>', '&lt;package&gt;').
      gsub('<strike>', '<del>').
      gsub('</strike>', '</del>').
      gsub(%r{</?span([^>]*?)>}, '').
      gsub(%r{</?colgroup>}, '').
      gsub(%r{(<h[1-6].*?)/>}, '\1>').
      gsub(%r{(<(col|img)[^>]+)(?<!/)>}, '\1/>')
  begin
    result = HtmlBeautifier.beautify(result)
  rescue RuntimeError => e
    puts "HtmlBeautifier error (#{e})"
  end
  result
end
