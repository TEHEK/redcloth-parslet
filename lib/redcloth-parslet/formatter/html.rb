module RedClothParslet::Formatter
  class HTML
    def initialize(options={})
      @options = options
    end
    
    def convert(root)
      @output = ""
      @stack = []
      send(root.type, root)
    end
    
    def textile_doc(el)
      inner(el, true).chomp
    end
    
    ([:h1, :h2, :h3, :h4, :h5, :h6, :p, :pre, :div, :table] +
    [:strong, :em, :i, :b, :ins, :del, :sup, :sub, :span, :cite, :acronym, :code]).each do |m|
      define_method(m) do |el|
       "<#{m}#{html_attributes(el.opts)}>#{inner(el)}</#{m}>"
      end
    end
    
    [:blockquote].each do |m|
      define_method(m) do |el|
       "<#{m}#{html_attributes(el.opts)}>\n#{inner(el)}\n</#{m}>"
      end
    end
    
    [:ul, :ol].each do |m|
      define_method(m) do |el|
        @list_nesting ||= 0
        out = ""
        out << "\n" if @list_nesting > 0
        out << "\t" * @list_nesting
        @list_nesting += 1
        out << "<#{m}#{html_attributes(el.opts)}>\n"
        out << list_items(el)
        out << "</li>\n"
        out << "\t" * (@list_nesting - 1)
        @list_nesting -= 1
        out << "</#{m}>"
        out
      end
    end
    
    def li(el)
      ("\t" * @list_nesting) +
      "<li#{html_attributes(el.opts)}>#{inner(el)}"
    end
    
    def link(el)
      "<a#{html_attributes(el.opts)}>#{inner(el)}</a>"
    end
    
    def img(el)
      if el.opts[:alt]
        el.opts[:title] = el.opts[:alt]
      else
        el.opts[:alt] = ""
      end
      %Q{<img#{html_attributes(el.opts, :image)} />}
    end
    
    def table_row(el)
      "<tr#{html_attributes(el.opts)}>#{inner(el)}</tr>"
    end
    def table_data(el)
      "<td#{html_attributes(el.opts)}>#{inner(el)}</td>"
    end
    def table_header(el)
      "<th#{html_attributes(el.opts)}>#{inner(el)}</th>"
    end
    
    def notextile(el)
      inner(el)
    end
    
    def double_quoted_phrase(el)
      "&#8220;#{inner(el)}&#8221;"
    end
    
    def dimension(el)
      el.to_s.gsub(/['"]/) {|m| {"\"" => '&#8243;', "'" => '&#8242;'}[m] }
    end
    
    def entity(el)
      ESCAPE_MAP[el.to_s]
    end
    
    private
    
    def list_items(el, block=false)
      result = ''
      @stack.push(el)
      el.children.each_with_index do |inner_el, index|
        result << "</li>\n" if inner_el.is_a?(RedClothParslet::Ast::Li) && index > 0
        result << send(inner_el.type, inner_el)
        result << "\n" if block
      end
      @stack.pop
      result
    end
    
    # Return the converted content of the children of +el+ as a string. The parameter +indent+ has
    # to be the amount of indentation used for the element +el+.
    #
    # Pushes +el+ onto the @stack before converting the child elements and pops it from the stack
    # afterwards.
    def inner(el, block = false)
      result = ''
      @stack.push(el)
      el.children.flatten.each do |inner_el|
        if inner_el.is_a?(String)
          result << escape_html(inner_el)
        elsif inner_el.respond_to?(:type)
          result << send(inner_el.type, inner_el)
        end
        result << "\n" if block
      end
      @stack.pop
      result
    end
    
    
    # Return the HTML representation of the attributes +attr+.
    def html_attributes(attr, type=:text)
      attr[:style] = attr[:style].map do |k,v|
        case k
        when /padding/
          "#{k}:#{v}em"
        when 'align'
          type == :text ? "text-align:#{v}" : "align:#{v}"
        end
      end.join("; ") if attr[:style]
      order_attributes(attr).map {|k,v| v.nil? ? '' : " #{k}=\"#{escape_html(v.to_s, :attribute)}\"" }.join('')
    end
    
    def order_attributes(attributes)
      return attributes unless @options[:order_attributes]
      attributes.inject({}) do |attrs, (key, value)|
        attrs[key.to_s] = value
        attrs
      end.sort
    end
    
    # :stopdoc:
    ESCAPE_MAP = {
      '<' => '&lt;',
      '>' => '&gt;',
      '&' => '&amp;',
      '"' => '&quot;',
      "\n" => "<br />\n",
      "'" => "&#8217;",
      "--" => "&#8212;",
      " -" => " &#8211;",
      "x" => "&#215;",
      "..." => "&#8230;"
    }
    ESCAPE_ALL_RE = /<|>|&|\n|"|'/
    ESCAPE_PRE_RE = Regexp.union(/<|>|&/)
    ESCAPE_ATTRIBUTE_RE = Regexp.union(/<|>|&|"/)
    ESCAPE_RE_FROM_TYPE = {
      :all => ESCAPE_ALL_RE,
      :pre => ESCAPE_PRE_RE,
      :attribute => ESCAPE_ATTRIBUTE_RE
    }
    # :startdoc:

    # Escape the special HTML characters in the string +str+. The parameter +type+ specifies what
    # is escaped: :all - all special HTML characters as well as entities, :pre - all special HTML
    # characters except breaks and quotes and :attribute - all special HTML
    # characters including the quotation mark but with no curly single quote.
    def escape_html(str, type = :all)
      str.gsub(ESCAPE_RE_FROM_TYPE[type]) {|m| ESCAPE_MAP[m] || m}
    end
    
  end
end