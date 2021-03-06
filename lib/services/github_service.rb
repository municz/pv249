require 'json'
require 'date'
require 'net/http'
require_relative '../model/event'
require_relative '../model/query'
require_relative 'service_helper'

class GithubService

  include ServiceHelper

  # ID of this service instance  
  attr_accessor :id
  
  # Returns a list of events satisfying the query
  def events(query)
    ret = Array.new
    json_array = JSON.parse(github_query(user_id(query.person)))
    json_array.each do |event_json|
      event = event_from_json(event_json)
      event.person = query.person
      
      if (event.time < query.to && event.time > query.from)
        ret << event
      end
    end

    ret
  end

  private

  def event_from_json(json_data)
    event = Event.new(self)
    event.time = DateTime.iso8601(json_data["created_at"])
    event.data = json_data
    
    event
  end

  def github_query(user)

    uri = URI.parse("https://api.github.com/users/#{user}/events/public")
    response = CachedHttpClient.get(uri)

    if response.code != "200"
      raise "Error when accessing GitHub: #{response.code} #{response.message}"
    end

    response.body
  end

end
