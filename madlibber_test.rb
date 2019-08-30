require 'madlibber'
require 'yaml'
require 'httparty'
require 'json'
require_relative 'parser'

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
    
    # get 5 descriptions!
    description_response = JSON.parse(get_response("games", "offset=#{random_id}&limit=5&field_list=description,aliases").body)

    # let's return the one's that aren't nil
    nonempty_descriptions = description_response["results"].select{|x| x["description"] != nil}

    return nonempty_descriptions
end

def generate_madlib(string)
    lines = string.split("\n")
    lines_lib = Array.new
    lines.each do |line|
        sentences = line.split(".")
        sentences_lib = Array.new
        sentences.each { |sentence| sentences_lib.push(MadLibber.libberfy sentence, {num_of_blanks: rand(3)}) }
        lines_lib.push(sentences_lib.join(". ")
            .gsub("<sym><<", "")
            .gsub("<nnp><", ""))
    end
    return lines_lib.join("\n")
end

output = generate_text_resources()[0]['description']
puts output
puts 'BREAK'
create_pages(output).each do |key, value|
    puts "KEY: #{key}"
    puts "VALUE: \n#{generate_madlib(value)}"
end