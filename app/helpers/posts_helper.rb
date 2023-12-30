module PostsHelper

   def asset_to_csv(items)
      require 'csv'
      csvtext=""
      if items and items.first then
        columns=[]; items.first.attributes.each_pair do |name, value| if !name.include?("password") and !name.include?("digest") and !name.include?("token") and !name.include?("_link") then columns << name end end
        csvtext << columns.to_csv
        items.each do |item|
           fields=[]; item.attributes.each_pair do |name, value| if !name.include?("password") and !name.include?("digest") and !name.include?("token") and !name.include?("_link") then fields << value end end
           csvtext << fields.to_csv
        end
     end
     csvtext
  end

def asset_to_gpx(assets)
require 'rexml/document'
 puts assets
 puts assets.first.to_json
   xml = REXML::Document.new
   gpx = xml.add_element 'gpx', {'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
     'xmlns' => 'http://www.topografix.com/GPX/1/0',
     'xsi:schemaLocation' => 'http://www.topografix.com/GPX/1/0 http://www.topografix.com/GPX/1/0/gpx.xsd',
     'version' => '1.0', 'creator' => 'http://routeguides.co.nz/'}

   assets.each do |a|
     if a.location then
       wpt = gpx.add_element 'wpt'
       wpt.add_element('url').add REXML::Text.new('https://ontheair.nz/'+a.url)
       wpt.add_attributes({'lat' => a.location.y.to_s, 'lon' => a.location.x.to_s})
       wpt.add_element('ele').add(REXML::Text.new(a.altitude.to_s))
       wpt.add_element('name').add(REXML::Text.new(a.name+" ("+a.code+")"+if(a.r_field('points')) then " ["+a.r_field('points').to_s+"]" else "" end))
     end
   end

   xml
end


  def convert_to_text(html)
    line_length = 80
    from_charset = 'UTF-8'
    txt = html
    txt.gsub!(/<!-- start text\/html -->.*?<!-- end text\/html -->/m, '')
    txt.gsub!(/<img.+?alt=\"([^\"]*)\"[^>]*\>/i, '\1')
    txt.gsub!(/<img.+?alt=\'([^\']*)\'[^>]*\>/i, '\1')
    # links
    txt.gsub!(/<a\s.*?href=["'](mailto:)?([^"']*)["'][^>]*>((.|\s)*?)<\/a>/i) do |s|
      if $3.empty?
        ''
      else
        $3.strip + ' ( ' + $2.strip + ' )'
      end
    end
    # handle headings (H1-H6)
    txt.gsub!(/(<\/h[1-6]>)/i, "\n\\1") # move closing tags to new lines
    txt.gsub!(/[\s]*<h([1-6]+)[^>]*>[\s]*(.*)[\s]*<\/h[1-6]+>/i) do |s|
      hlevel = $1.to_i

      htext = $2
      htext.gsub!(/<br[\s]*\/?>/i, "\n") # handle <br>s
      htext.gsub!(/<\/?[^>]*>/i, '') # strip tags

      # determine maximum line length
      hlength = 0
      htext.each_line { |l| llength = l.strip.length; hlength = llength if llength > hlength }
      hlength = line_length if hlength > line_length

      case hlevel
        when 1   # H1, asterisks above and below
          htext = ('*' * hlength) + "\n" + htext + "\n" + ('*' * hlength)
        when 2   # H1, dashes above and below
          htext = ('-' * hlength) + "\n" + htext + "\n" + ('-' * hlength)
        else     # H3-H6, dashes below
          htext = htext + "\n" + ('-' * hlength)
      end

      "\n\n" + htext + "\n\n"
    end

    # wrap spans
    txt.gsub!(/(<\/span>)[\s]+(<span)/mi, '\1 \2')
    # lists -- TODO: should handle ordered lists
    txt.gsub!(/[\s]*(<li[^>]*>)[\s]*/i, '* ')
    # list not followed by a newline
    txt.gsub!(/<\/li>[\s]*(?![\n])/i, "\n")

    # paragraphs and line breaks
    txt.gsub!(/<\/p>/i, "\n\n")
    txt.gsub!(/<br[\/ ]*>/i, "\n")
   # strip remaining tags
    txt.gsub!(/<\/?[^>]*>/, '')

    # decode HTML entities
    he = HTMLEntities.new
    txt = he.decode(txt)

    # no more than two consecutive spaces
    txt.gsub!(/ {2,}/, " ")

#    txt = word_wrap(txt, line_length)
    # remove linefeeds (\r\n and \r -> \n)
    txt.gsub!(/\r\n?/, "\n")

    # strip extra spaces
    txt.gsub!(/[ \t]*\302\240+[ \t]*/, " ") # non-breaking spaces -> spaces
    txt.gsub!(/\n[ \t]+/, "\n") # space at start of lines
    txt.gsub!(/[ \t]+\n/, "\n") # space at end of lines

    # no more than two consecutive newlines
    txt.gsub!(/[\n]{3,}/, "\n\n")

    # the word messes up the parens
    txt.gsub!(/\(([ \n])(http[^)]+)([\n ])\)/) do |s|
      ($1 == "\n" ? $1 : '' ) + '( ' + $2 + ' )' + ($3 == "\n" ? $1 : '' )
    end

    txt.strip

end

def word_wrap(txt, line_length)
    txt.split("\n").collect do |line|
      line.length > line_length ? line.gsub(/(.{1,#{line_length}})(\s+|$)/, "\\1\n").strip : line
    end * "\n"
end


end
