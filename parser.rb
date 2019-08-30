require 'nokogiri'

TAGS_TO_REPLACE =
    "a",
    "figure",
    "img"

def create_pages(html_string)
    TAGS_TO_REPLACE.each do |tag| 
        html_string = remove_tag(tag, html_string, generate_document(html_string))
    end

    html_string = handle_p_tag(html_string, generate_document(html_string))
    html_string = handle_ul_tag(html_string, generate_document(html_string))
    html_string = handle_ol_tag(html_string, generate_document(html_string))
    html_string.gsub!("<br/>", "\n")

    document = generate_document(html_string)
    headers = document.css("h2")
    if headers.empty?
        return {nil => html_string}
    else
        current_char = 0
        pages = Hash.new
        headers.each_with_index do |h, i|
            header_start = h.to_s
            header_start.strip!
            position_start = html_string.index(header_start)
            next_element = headers[i+1]
            if next_element.nil?
                to_save = html_string[position_start..-1]
                pages[h.text] = to_save.sub(header_start, "")
            else
                header_end = next_element.to_s
                header_end.strip!
                position_end = html_string.index(header_end)
                to_save = html_string[position_start..position_end]
                pages[h.text] = to_save.sub(header_start, "")
            end
        end

        return pages
    end
end

def remove_tag(tag, html_string, nokogiri_document)
    links = nokogiri_document.css(tag)
    links.each { |a| html_string.sub!(a.to_s, a.text) }
    return html_string
end

def handle_p_tag(html_string, nokogiri_document)
    paragraphs = nokogiri_document.css("p")
    paragraphs.each do |p|
        original = p.to_s
        original.strip!
        update = "\n\n#{p.text}"
        html_string.sub!(original, update)
    end
    
    return html_string
end

def handle_ul_tag(html_string, nokogiri_document)
    unordered_lists = nokogiri_document.css("ul")
    unordered_lists.each do |list|
        original = list.to_html(save_with: 0)
        original.strip!
        list_elements = generate_document(original).css("li")
        updated = ""
        list_elements.each { |li| updated += "\n\t* " + li.text}
        html_string.sub!(original, updated)
    end

    return html_string
end

def handle_ol_tag(html_string, nokogiri_document)
    ordered_lists = nokogiri_document.css("ol")
    ordered_lists.each do |list|
        original = list.to_html(save_with: 0)
        original.strip!
        list_elements = generate_document(original).css("li")
        updated = ""
        numbering = 1
        list_elements.each do |li| 
            updated += "\n\t#{numbering}. " + li.text
            numbering += 1
        end

        html_string.sub!(original, updated)
    end

    return html_string
end

def generate_document(html_string)
    return Nokogiri::HTML.parse(html_string)
end