require 'madlibber'
require 'yaml'
require 'httparty'
require 'json'
require_relative 'parser'

MAX_REPLACE = 3

# gets a response in json from the api
def get_response(resource, query_string)
    config = YAML.load(File.read("giantbomb.yaml"))
    api_key = config['api_key']
    api_base = config['api_base']
    return HTTParty.get("#{api_base}/#{resource}/?api_key=#{api_key}&format=json&#{query_string}")
end

# returns a nonempty set of text to parse
def generate_text_resources()

    # get total number of games in database
    upper_limit = JSON.parse(get_response("games", "").body)['number_of_total_results']

    # generate a random id
    random_id = rand(upper_limit)
    
    # get 5 descriptions!
    description_response = JSON.parse(get_response(
        "games",
        "offset=#{random_id}&limit=5&field_list=description,aliases").body)

    # let's return the one's that aren't nil
    nonempty_descriptions = description_response["results"].select{ |x| x["description"] != nil }
    if nonempty_descriptions.empty?
        return generate_text_resources
    else
        return nonempty_descriptions
    end
end

# create a word replacement game thingie from a given string
def generate_lib(string)
    lines = string.split("\n")
    
    # throw away extra newlines
    lines.reject { |l| l.empty? }
    lines_lib = Array.new
    lines.each do |line|
        sentences = line.split(".")
        sentences_lib = Array.new

        # turn each individual sentence into a lib
        sentences.each do |sentence| 
            sentences_lib.push(
                MadLibber.libberfy sentence, {num_of_blanks: rand(MAX_REPLACE)})
        end

        # combine sentences and remove some junk from the parser
        lines_lib.push(sentences_lib.join(". ")
            .gsub(/<sym><*/, "")
            .gsub(/<nnp><*/, "")
            .gsub("//SYM", ""))
    end

    return lines_lib.join("\n")
end

# lets just print the output and move on with our lives
create_pages(generate_text_resources()[0]['description']).each do |key, value|
    puts "KEY: #{key}"
    puts "VALUE: #{generate_lib(value)}"
end