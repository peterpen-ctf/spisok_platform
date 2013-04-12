# -*- encoding : utf-8 -*-
require 'pony'

class EmailHelper

  MAIL_TEMPLATES_DIR = 'mail_templates'

  def self.send(options)
    if options.has_key?(:template)
      template_path = File.join(MAIL_TEMPLATES_DIR, options[:template])
      html_body = File.open(template_path).read
      html_body %= options[:vars] if options.has_key?(:vars)
      options[:html_body] = html_body
    end
    options[:from] = 'noreply-spisokctf@ppctf.net' unless options.has_key?(:from)
    Pony.mail(options)
  end

end
