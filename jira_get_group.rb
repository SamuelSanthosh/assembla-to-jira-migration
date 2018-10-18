# frozen_string_literal: true

load './lib/common.rb'

JIRA_API_USER_ATTRIBUTES = %w{name key accountId emailAddress displayName active}.freeze

# Unique users taken from all of the jira user groups.
# name,key,accountId,emailAddress,displayName,active
@jira_all_users = []

def jira_get_user_by_email(emailAddress)
  jira_get_all_users unless @jira_all_users.length.nonzero?
  return @jira_all_users.find {|user| user['emailAddress'] == emailAddress}
end

def jira_get_group(group_name)
  result = []
  batchsize = 50
  startAt = 0
  processing = true
  while processing
    url = "#{JIRA_API_HOST}/group/member?groupname=#{group_name}&includeInactiveUsers=true&startAt=#{startAt}&maxResults=#{batchsize}"
    begin
      response = RestClient::Request.execute(method: :get, url: url, headers: JIRA_HEADERS_ADMIN)
      body = JSON.parse(response.body)
      users = body['values']
      puts "GET #{url} => OK (#{users.length})"
      users.each do |user|
        # Not interested in the following attributes
        %w{self avatarUrls timeZone}.each {|attr| user.delete(attr)}
        result << user
      end
      processing = !body['isLast']
    rescue => e
      puts "GET #{url} => NOK (#{e.message})"
      result = []
      processing = false
    end
    startAt = startAt + batchsize if processing
  end
  # We are not interested in system users
  result.select {|user| !/^addon_/.match(user['name'])}
end

JIRA_API_USER_GROUPS.split(',').each do |group|
  jira_get_group(group).each do |user|
    unless @jira_all_users.find {|u| u['name'] == user['name']}
      @jira_all_users << user
    end
  end
end

puts "\nTotal Jira users: #{@jira_all_users.length}"
@jira_all_users.each do |user|
  unless jira_get_user_by_email(user['emailAddress'])['accountId'] == user['accountId']
    puts "Test => NOK for user['emailAddress']='#{user['emailAddress']}'"
    exit
  end
  attributes = []
  JIRA_API_USER_ATTRIBUTES.each do |attr|
    attributes << "#{attr}='#{user[attr]}'"
  end
  puts attributes.join(',')
end

puts "Test => OK"
