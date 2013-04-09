# -*- encoding : utf-8 -*-

class StringHelper

  HTML_ESCAPE_TABLE = { 
    '&' => '&amp;',
    '"' => '&quot;',
    '<' => '&lt;',
    '>' => '&gt;',
  }

  def self.escapeHTML(string)
    string.gsub(/[&\"<>]/, HTML_ESCAPE_TABLE)
  end 
end

