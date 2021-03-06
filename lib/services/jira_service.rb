require 'json'
require 'date'
require 'net/http'
require_relative '../model/event'
require_relative '../model/query'
require_relative 'service_helper'
require_relative '../cached_http_client'

class JiraService
  
  include ServiceHelper
  
  # ID of this service instance
  attr_accessor :id
  
  # URL of the instance, e.g. http://issues.jboss.org
  attr_accessor :instance_url
  
  # API path, e.g. /rest/api/latest
  attr_accessor :api_path
  
  # Returns a list of events satisfying the query
  def events(query)
    JSON.parse(jira_query(query))["issues"].map do |json_evt|
      event = event_from_json(json_evt)
      event.person = query.person
      event
    end
  end
  
  def event_from_json(json_data)
    event = Event.new(self)
    event.time = DateTime.iso8601(json_data["fields"]["created"])
    event.data = json_data
    event
  end

  def jira_query(query)
    params = {
      jql: "reporter=#{user_id(query.person)} AND createdDate>=#{query.from.to_date} AND createdDate<=#{query.to.to_date} ORDER BY created DESC, key DESC",
      fields: "key,summary,issuetype,priority,status,reporter,description,created,assignee,resolution"
    }
    uri = URI ("#{api_url}/search")
    uri.query = URI.encode_www_form(params)
    response = CachedHttpClient.get(uri)

    if response.code != "200"
      raise "Error when accessing Jira: #{response.code} #{response.message}"
    end

    response.body
  end
  
  def api_url 
    "#{instance_url}#{api_path}"
  end
  
end