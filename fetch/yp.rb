require 'common'

site_map = Typhoeus.get('www.yellowpages.com/sitemap')

doc = Nokogiri::HTML(site_map.body)

cities = []
doc.search("//section[@class='local-yp states-list']/div/section/header/a").each do |a|
  state_url = a.attributes['href'].value
  state_name = a.text
  puts "State: #{state_url}"
  state_response = Typhoeus.get("www.yellowpages.com" + state_url)

  state_doc = Nokogiri::HTML(state_response.body)
  state_doc.search("//ul[@class='cities-list']/li/a").each do |a|
    cities << { url: a.attributes['href'].value, state: state_name, city: a.text }
  end
end


source = Source.get('YellowPages')

#search_url = 'www.yellowpages.com/east-los-angeles-ca/screen-printing'


i = cities.index(cities.find { |c| c[:url] == '/satsop-wa' })
c = cities.find do |city|
  search_url = "www.yellowpages.com#{city[:url]}/screen-printing"
  puts search_url
  search_response = Typhoeus.get(search_url)
  !search_response.cached?
end
i = cities.index(i)

cities = cities[i..-1]

cities.each do |city|
  (1..20).each do |page|
    search_url = "www.yellowpages.com#{city[:url]}/screen-printing"
    search_url += "?page=#{page}" unless page == 1
    puts "Search: #{search_url}"
    search_response = Typhoeus.get(search_url)
    search_doc = Nokogiri::HTML(search_response.body)
    search_doc.css(".search-results .v-card .info").each do |div|
      website = div.css('a.track-visit-website').first
      record = {
          name: div.css("h3 .business-name span").first.text,
          address: {},
          phones: div.css(".info-primary li.phone").map { |n| n.text },
          website: website && website.attributes['href'].value,
          reference: div.css('h3 .business-name').first.attributes['href'].value
      }

      if node = div.css(".info-primary p.adr").first
        { address1: 'streetAddress',
          city: 'addressLocality',
          state: 'addressRegion',
          postalcode: 'postalCode' }.each do |attr, prop|
          if span = node.search("span[@itemprop='#{prop}']")
            record[:address][attr] = span.text
          end
        end
        record[:address][:city] = record[:address][:city].gsub(',', '').strip if record[:address][:city]
      end

      Business.insert_update source, record
    end

    break unless search_doc.css(".pagination ul li a").find do |a|
      (page+1) == a.text.to_i
    end
  end
end
