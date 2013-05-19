require "knjrbfw"
require "php4r"

class ArgsHandler
  def self.checkval(value, val1, val2 = nil)
    if val2 != nil
      if !value or value == "" or value == "false"
        return val2
      else
        return val1
      end
    else
      if !value or value == "" or value == "false"
        return val1
      else
        return value
      end
    end
  end
  
  def self.inputs(arr)
    html = ""
    arr.each do |args|
      if RUBY_ENGINE == "rbx"
        html << self.input(args).to_s.encode(html.encoding)
      else
        html << self.input(args)
      end
    end
    
    html = html.html_safe if html.respond_to?(:html_safe)
    
    return html
  end
  
  def self.style_html(css)
    return "" if css.length <= 0
    
    str = " style=\""
    
    css.each do |key, val|
      str << "#{key}: #{val};"
    end
    
    str << "\""
    
    return str
  end
  
  def self.attr_html(attrs)
    return "" if attrs.length <= 0
    
    html = ""
    attrs.each do |key, val|
      html << " #{key}=\"#{html_escape(val)}\""
    end
    
    return html
  end
  
  def self.input(args)
    if args.key?(:value)
      if args[:value].is_a?(Array) and (args[:value].first.is_a?(NilClass) or args[:value].first == false)
        value = nil
      elsif args[:value].is_a?(Array)
        if !args[:value][2] or args[:value][2] == :key
          value = args[:value].first[args[:value][1]]
        elsif args[:value][2] == :callb
          value = args[:value].first.send(args[:value][1])
        else
          value = args[:value]
        end
      elsif args[:value].is_a?(String) or args[:value].is_a?(Integer)
        value = args[:value].to_s
      else
        value = args[:value]
      end
    end
    
    args[:value_default] = args[:default] if args[:default]
    
    if value.is_a?(NilClass) and args[:value_default]
      value = args[:value_default]
    elsif value.is_a?(NilClass)
      value = ""
    end
    
    if value and args.key?(:value_func) and args[:value_func]
      cback = args[:value_func]
      
      if cback.is_a?(Method)
        value = cback.call(value)
      elsif cback.is_a?(Array)
        value = Php4r.call_user_func(args[:value_func], value)
      elsif cback.is_a?(Proc)
        value = cback.call(value)
      else
        raise "Unknown class: #{cback.class.name}."
      end
    end
    
    value = args[:values] if args[:values]
    args[:id] = args[:name] if !args[:id]
    
    if !args[:type]
      if args[:opts]
        args[:type] = :select
      elsif args[:name] and args[:name].to_s[0..2] == "che"
        args[:type] = :checkbox
      elsif args[:name] and args[:name].to_s[0..3] == "file"
        args[:type] = :file
      else
        args[:type] = :text
      end
    else
      args[:type] = args[:type].to_sym
    end
    
    attr = {
      "name" => args[:name],
      "id" => args[:id],
      "type" => args[:type],
      "class" => "input_#{args[:type]}"
    }
    attr.merge!(args[:attr]) if args[:attr]
    attr["disabled"] = "disabled" if args[:disabled]
    attr["maxlength"] = args[:maxlength] if args.key?(:maxlength)
    
    raise "No name given to the ArgsHandler::input()-method." if !args[:name] and args[:type] != :info and args[:type] != :textshow and args[:type] != :plain and args[:type] != :spacer and args[:type] != :headline
    
    css = {}
    css["text-align"] = args[:align] if args.key?(:align)
    css.merge!(args[:css]) if args.key?(:css)
    
    attr_keys = [:onchange]
    attr_keys.each do |tag|
      if args.key?(tag)
        attr[tag] = args[tag]
      end
    end
    
    classes_tr = []
    classes_tr += args[:classes_tr] if args[:classes_tr]
    
    tr_attrs = {}
    label_attrs = {}
    td_attrs = {
      :class => :tdc
    }
    
    if !args[:id].to_s.empty?
      tr_attrs[:id] = "#{args[:id]}_tr"
      td_attrs[:id] = "#{args[:id]}_content"
      label_attrs[:for] = args[:id]
    end
    
    if !classes_tr.empty?
      classes_tr_html = " class=\"#{classes_tr.join(" ")}\""
    else
      classes_tr_html = ""
    end
    
    if args.key?(:title)
      title_html = html_escape(args[:title])
    elsif args.key?(:title_html)
      title_html = args[:title_html]
    end
    
    html = ""
    
    classes = ["input_#{args[:type]}"]
    classes = classes | args[:classes] if args.key?(:classes)
    attr["class"] = classes.join(" ")
    
    if args[:type] == :checkbox
      attr["value"] = args[:value_active] if args.key?(:value_active)
      attr["checked"] = "checked" if value.is_a?(String) and value == "1" or value.to_s == "1" or value.to_s == "on" or value.to_s == "true"
      attr["checked"] = "checked" if value.is_a?(TrueClass)
      
      html << "<tr#{classes_tr_html}>"
      html << "<td colspan=\"2\" class=\"tdcheck\">"
      html << "<input#{self.attr_html(attr)} />"
      html << "<label#{attr_html(label_attrs)}\">#{title_html}</label>"
      html << "</td>"
      html << "</tr>"
    elsif args[:type] == :headline
      html << "<tr#{classes_tr_html}><td colspan=\"2\"><h2 class=\"input_headline\">#{title_html}</h2></td></tr>"
    elsif args[:type] == :spacer
      html << "<tr#{classes_tr_html}><td colspan=\"2\">&nbsp;</td></tr>"
    else
      html << "<tr#{classes_tr_html}#{attr_html(tr_attrs)}>"
      html << "<td class=\"tdt\" id=\"#{html_escape("#{args[:id]}_label")}\"><div><label>"
      html << title_html
      html << "</label></div></td>"
      html << "<td#{self.style_html(css)}#{attr_html(td_attrs)}><div>"
      
      if args[:type] == :textarea
        if args.key?(:height)
          if (Float(args[:height]) rescue false)
            css["height"] = "#{args[:height]}px"
          else
            css["height"] = args[:height]
          end
        end
        
        attr["class"] = "input_textarea"
        attr["name" ] = args[:name]
        attr["id"] = args[:id]
        attr.delete("type")
        
        html << "<textarea#{self.style_html(css)}#{self.attr_html(attr)}>#{value}</textarea>"
      elsif args[:type] == :fckeditor
        args[:height] = 400 if !args[:height]
        
        require "/usr/share/fckeditor/fckeditor.rb" if !Kernel.const_defined?(:FCKeditor)
        fck = FCKeditor.new(args[:name])
        fck.Height = args[:height].to_i
        fck.Value = value
        html << fck.CreateHtml
      elsif args[:type] == :ckeditor
        args[:height] = 400 if !args[:height]
        require "ckeditor4ruby" if !Kernel.const_defined?(:CKEditor)
        ck = CKEditor.new
        ck.return_output = true
        html << ck.editor(args[:name], value)
      elsif args[:type] == :select
        attr[:multiple] = "multiple" if args[:multiple]
        attr[:size] = args[:size] if args[:size]
        
        html << "<select#{self.attr_html(attr)}>"
        html << ArgsHandler.opts(args[:opts], value, args[:opts_args])
        html << "</select>"
        
        if args[:moveable]
          html << "<div style=\"padding-top: 3px;\">"
          html << "<input type=\"button\" value=\"#{_("Up")}\" onclick=\"select_moveup($('##{args[:id]}'));\" />"
          html << "<input type=\"button\" value=\"#{_("Down")}\" onclick=\"select_movedown($('##{args[:id]}'));\" />"
          html << "</div>"
        end
      elsif args[:type] == :imageupload
        html << "<table class=\"designtable\"><tr#{classes_tr_html}><td style=\"width: 100%;\">"
        html << "<input type=\"file\" name=\"#{args[:name].html}\" class=\"input_file\" />"
        html << "</td><td style=\"padding-left: 5px;\">"
        
        raise "No path given for imageupload-input." if !args.key?(:path)
        raise "No value given in arguments for imageupload-input." if !args.key?(:value)
        
        path = args[:path].gsub("%value%", value.to_s).untaint
        if File.exists?(path)
          html << "<img src=\"image.rhtml?path=#{html_escape(self.urlenc(path))}&smartsize=100&rounded_corners=10&border_color=black&force=true&ts=#{Time.new.to_f}\" alt=\"Image\" />"
          
          if args[:dellink]
            dellink = args[:dellink].gsub("%value%", value.to_s)
            html << "<div style=\"text-align: center;\">(<a href=\"javascript: if (confirm('#{_("Do you want to delete the image?")}')){location.href='#{dellink}';}\">#{_("delete")}</a>)</div>"
          end
        end
        
        html << "</td></tr></table>"
      elsif args[:type] == :file
        attr["type"] = args[:type]
        attr["class"] = "input_#{args[:type]}"
        attr["name"] = args[:name]
        
        html << "<input#{self.attr_html(attr)} />"
      elsif args[:type] == :textshow or args[:type] == :info
        html << value.to_s
      elsif args[:type] == :plain
        html << "#{Php4r.nl2br(html_escape(value))}"
      elsif args[:type] == :editarea
        css["width"] = "100%"
        css["height"] = args[:height] if args.key?(:height)
        
        attr["id"] = args[:id]
        attr["name"] = args[:name]
        
        html << "<textarea#{self.attr_html(attr)}#{self.style_html(css)}>#{value}</textarea>"
        
        jshash = {
          "id" => args[:id],
          "start_highlight" => true
        }
        
        pos_keys = [:skip_init, :allow_toggle, :replace_tab_by_spaces, :toolbar, :syntax]
        pos_keys.each do |key|
          jshash[key.to_s] = args[key] if args.key?(key)
        end
        
        html << "<script type=\"text/javascript\">"
        html << "function knj_web_init_#{args[:name]}(){"
        html << "editAreaLoader.init(#{Php4r.json_encode(jshash)});"
        html << "}"
        html << "</script>"
      elsif args[:type] == :numeric
        attr[:type] = :text
        attr[:value] = value
        html << "<input#{self.attr_html(attr)} />"
      else
        attr[:value] = value
        html << "<input#{self.attr_html(attr)} />"
      end
      
      html << "</div></td></tr>"
    end
    
    html << "<tr#{classes_tr_html}><td colspan=\"2\" class=\"tdd\">#{args[:descr]}</td></tr>" if args[:descr]
    html = html.html_safe if html.respond_to?(:html_safe)
    
    return html
  end
  
  def self.opts(opthash, curvalue = nil, opts_args = {})
    opts_args = {} if !opts_args
    
    return "" if !opthash
    cname = curvalue.class.name
    curvalue = curvalue.id if (cname == "Knj::Db_row" or cname == "Knj::Datarow" or cname == "Baza::Model" or cname == "Baza::ModelCustom")
    
    html = ""
    addsel = " selected=\"selected\"" if !curvalue
    
    html << "<option#{addsel} value=\"\">#{_("Add new")}</option>" if opts_args and (opts_args[:add] or opts_args[:addnew])
    html << "<option#{addsel} value=\"\">#{_("Choose")}</option>" if opts_args and opts_args[:choose]
    html << "<option#{addsel} value=\"\">#{_("None")}</option>" if opts_args and opts_args[:none]
    html << "<option#{addsel} value=\"\">#{_("All")}</option>" if opts_args and opts_args[:all]
    
    if opthash.is_a?(Hash) or opthash.class.to_s == "Dictionary"
      opthash.each do |key, value|
        html << "<option"
        sel = false
        
        if curvalue.is_a?(Array) and curvalue.index(key) != nil
          sel = true
        elsif curvalue.to_s == key.to_s
          sel = true
        elsif curvalue and curvalue.respond_to?(:is_knj?) and curvalue.id.to_s == key.to_s
          sel = true
        end
        
        html << " selected=\"selected\"" if sel
        html << " value=\"#{html_escape(key)}\">#{html_escape(value)}</option>"
      end
    elsif opthash.is_a?(Array)
      opthash.each_index do |key|
        if opthash[key.to_i] != nil
          html << "<option"
          html << " selected=\"selected\"" if curvalue.to_s == key.to_s
          html << " value=\"#{html_escape(key)}\">#{html_escape(opthash[key])}</option>"
        end
      end
    end
    
    return html
  end
  
  def self.html_escape(str)
    str = str.to_s
    
    if Kernel.const_defined?("CGI")
      return CGI.escape_html(str)
    elsif Kernel.const_defined?("Knj")
      return Knj::Web.html(str)
    else
      raise "Dont know how to HTML-escape string..."
    end
  end
end