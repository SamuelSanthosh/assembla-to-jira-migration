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
EXT = ENV['EXT'] || 'confluence'
API = ENV['CONFLUENCE_API'] || throw('CONFLUENCE_API must be defined')
SPACE = ENV['CONFLUENCE_SPACE'] || throw('CONFLUENCE_SPACE must be defined')
EMAIL = ENV['CONFLUENCE_EMAIL'] || throw('CONFLUENCE_EMAIL must be defined')
PASSWORD = ENV['CONFLUENCE_PASSWORD'] || throw('CONFLUENCE_PASSWORD must be defined')

# Global constants
FIXED_EXT = 'fixed'
LINKS_CSV = "#{DATA}/links.csv"
UPLOADED_IMAGES_CSV ="#{DATA}/uploaded-images.csv"
CREATED_PAGES_CSV ="#{DATA}/created-pages.csv"
UPDATED_PAGES_CSV ="#{DATA}/updated-pages.csv"

# Display environment
puts
puts "DEBUG:    : '#{DEBUG}'"
puts "DATA      : '#{DATA}'"
puts "IMAGES    : '#{IMAGES}'"
puts "EXT       : '#{EXT}'"
puts "API       : '#{API}'"
puts "SPACE     : '#{SPACE}'"
puts "EMAIL     : '#{EMAIL}'"
puts "PASSWORD  : '*******'"
puts

Dir.mkdir(DATA) unless File.exist?(DATA)
Dir.mkdir(IMAGES) unless File.exist?(IMAGES)

HEADERS = {
  'Authorization': "Basic #{Base64.encode64("#{EMAIL}:#{PASSWORD}")}",
  'Content-Type': 'application/json; charset=utf-8',
  'Accept': 'application/json'
}.freeze