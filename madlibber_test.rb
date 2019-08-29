require 'madlibber'
require 'yaml'
require 'httparty'
require 'json'

def get_response(resource, query_string)
    config = YAML.load(File.read("giantbomb.yaml"))
    api_key = config['api_key']
    api_base = config['api_base']
    return HTTParty.get("#{api_base}/#{resource}/?api_key=#{api_key}&format=json&#{query_string}")
end

def generate_text_resources()
    # get total number of games in database
    upper_limit = JSON.parse(get_response("games", "").body)['number_of_total_results']

    # generate a random id
    random_id = rand(upper_limit)
    
    # get 100 descriptions!
    return JSON.parse(get_response("games", "offset=#{random_id}&limit=5&field_list=description,aliases").body)
end

puts generate_text_resources()