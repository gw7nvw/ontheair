module ApplicationHelper
  def sign_in(user)
    puts "Self: "+self.to_s
    remember_token = User.new_token
    cookies[:remember_token] = {value: remember_token, expires: 1.month.from_now.utc}
    user.update_attribute(:remember_token, User.digest(remember_token))
    self.current_user = user
    session[:user_id]=user.id
  end
   
  def convert_to_text(html, line_length = 65, from_charset = 'UTF-8')
    require 'htmlentities'

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
