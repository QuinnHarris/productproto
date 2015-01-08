require_relative 'common'

b_ds = Business.where((~Sequel.expr(id: BusinessEmail.select(:business_id)) & ~Sequel.expr(website: nil))).order(:id)
#b_ds = b_ds.where { id > 21789 }

def parallel(b_ds)
 hydra = Typhoeus::Hydra.hydra
 b_ds.paged_each do |business|
   request = Typhoeus::Request.new(business.website)
   request.on_complete do |response|
 #    doc = Nokogiri::HTML(response.body)
     puts "Response: #{business.id} #{response.request.url}"
   end

   puts "Request: #{business.website}"

   hydra.queue request
 end
 hydra.run
end

def parse_mailto(doc)
  doc.search("//a[starts-with(@href, 'mailto:')]").map do |a|
    a.attributes['href'].value.gsub(/^mailto:/, '').gsub(/\?.+$/, '').strip
  end
end

def process_url(url, processed = [], depth = 0)
  return [] if depth > 2
  puts "  #{url}"
  response = Typhoeus.get(url, timeout: 5, followlocation: true)
  url = response.effective_url

  doc = Nokogiri::HTML(response.body.encode('UTF-8', :invalid => :replace, :undef => :replace, :replace => ''))

  emails = parse_mailto(doc)

  emails += response.body.encode('ASCII', :invalid => :replace, :undef => :replace, :replace => '').scan(/\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\b/i)

  urls = doc.search("//a[contains(translate(text(), 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), 'contact')]").map do |a|
    v = a.attributes['href']
    v = v && v.value.strip.gsub(' ', '%20')
    v.blank? ? nil : v
  end.compact.uniq - processed
  urls.delete_if { |u| u.include?('javascript') }
  urls.each do |u|
    emails += process_url(u.include?("://") ? u : (url + u), urls, depth + 1)
  end

  emails
end

b_ds.all.each do |business|
  puts business.id
  url = business.website
  emails = process_url(url)

  unless emails.empty?
    emails.uniq!
    puts "  * : #{emails.inspect}"
    business.add_emails(emails, url)
  end
end

#response = Typhoeus.get('kinteco.com')
#doc = Nokogiri::HTML(response.body)

