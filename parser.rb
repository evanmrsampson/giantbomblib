require 'nokogiri'

# tags where we want to preserve
# the .text but delete the surrounding tags
TAGS_TO_REPLACE =
    "a",
    "figure",
    "img"

# generate a dictionary of (section, data)
def create_pages(html_string)
    TAGS_TO_REPLACE.each do |tag| 
        html_string = replace_tag(tag, html_string)
    end

    # these are special replacement cases
    html_string = handle_p_tag(html_string)
    html_string = handle_ul_tag(html_string)
    html_string = handle_ol_tag(html_string)
    html_string.gsub!("<br/>", "\n")

    headers = generate_document(html_string).css("h2")
    pages = Hash.new
    if headers.empty?
        pages[nil] = html_string
    else
        # split the text between the headers
        headers.each_with_index do |h, i|
            header_start = h.to_s
            header_start.strip!
            position_start = html_string.index(header_start)
            next_element = headers[i+1]
            if next_element.nil?
                # if no next header, go straight to end of doc
                to_save = html_string[position_start..-1]
                pages[h.text] = to_save.sub(header_start, "")
            else
                # get the string between current header and next
                header_end = next_element.to_s
                header_end.strip!
                position_end = html_string.index(header_end)
                to_save = html_string[position_start..position_end]
                pages[h.text] = to_save.sub(header_start, "")
            end
        end
    end

    return pages
end

# parse out tags generically
def replace_tag(tag, html_string)
    links = generate_document(html_string).css(tag)
    links.each { |a| html_string.sub!(a.to_s, a.text) }
    return html_string
end

# parse paragraphs and add a tab
def handle_p_tag(html_string)
    paragraphs = generate_document(html_string).css("p")
    paragraphs.each do |p|
        original = p.to_s
        original.strip!
        update = "\n\t#{p.text}"
        html_string.sub!(original, update)
    end
    
    return html_string
end

# parse unordered list elements
def handle_ul_tag(html_string)
    unordered_lists = generate_document(html_string).css("ul")
    unordered_lists.each do |list|
        # save_with: 0 gives us the raw original
        original = list.to_html(save_with: 0)
        original.strip!
        list_elements = generate_document(original).css("li")
        updated = ""
        list_elements.each { |li| updated += "\n\t* " + li.text}
        html_string.sub!(original, updated)
    end

    return html_string
end

# parse ordered list elements into a numbered list
def handle_ol_tag(html_string)
    ordered_lists = generate_document(html_string).css("ol")
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