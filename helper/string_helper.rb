# -*- encoding : utf-8 -*-
require 'sanitize'

class StringHelper

  HTML_ESCAPE_TABLE = {
    '&' => '&amp;',
    '"' => '&quot;',
    '<' => '&lt;',
    '>' => '&gt;',
  }

  def self.escapeHTML_meta(data)
    case data
    when String
      escapeHTML(data)
    when Array
      new_array = []
      data.each do |el|
        new_array << escapeHTML(el.to_s)
      end
      new_array
    when Hash
      new_hash = {}
      data.each_pair do |key, value|
        new_hash[key] = escapeHTML(value.to_s)
      end
      new_hash
    end
  end

  def self.escapeHTML(string)
    string.gsub(/[&\"<>]/, HTML_ESCAPE_TABLE)
  end

  def self.sanitize_basic(data)
    case data
    when String
      Sanitize.clean(data, Sanitize::Config::BASIC)
    when Array
      new_array = []
      data.each do |el|
        new_array << sanitize_basic(el.to_s)
      end
      new_array
    when Hash
      new_hash = {}
      data.each_pair do |key, value|
        new_hash[key] = sanitize_basic(value.to_s)
      end
      new_hash
    end
  end
end

