require 'rest-client'
require 'nokogiri'
require 'fileutils'

url = 'http://saltlakecity.craigslist.org/apa/3990520051.html'
if page = RestClient.get(url)
  puts "\nGot #{url} successfully!"
  File.open("data/cl-#{url.match(/[^\/]*$/)}", 'w') { |f| f.write page.body }
  npage = Nokogiri::HTML(page)

  description = npage.css('#postingbody')

  # Grab thumbs/images
  image_links = npage.css('#thumbs a')
  image_names = Array.new
  image_links.each do |link|
    image = RestClient.get(link['href'])
    filename = "img-#{link['href'].match(/[^\/]*$/)}"
    File.open("data/#{filename}", 'w') { |f| f.write image }
    image_names.push(filename)
  end

  # Process CL-id'd data
  cltags = npage.css('.cltags')
  address = cltags.css('.mapaddress')
  cl_data = cltags.css('.blurbs li')
  cl_tags_of_interest = { 'purrr' => 'cat_friendly', 'wooof' => 'dog_friendly', 'Location' => 'cl_location' }
  meta = Hash.new
  meta['images'] = image_names unless image_names.empty?
  meta['url'] = url
  cl_data.each do |data|
    cl_tags_of_interest.each_key do |key|
      if !data.content.match(key).nil?
        if d = data.content.match(/#{key}: (.*)/)
          meta[cl_tags_of_interest[key]] = d.captures[0]
        else
          meta[cl_tags_of_interest[key]] = true
        end
      end
    end
  end

  # Grab posting meta-data
  post_info = npage.css('div.postinginfos p')
  field_names = { 'Posting ID' => 'cl_id', 'Posted' => 'post_date', 'Updated' => 'updated_date' }
  post_info.each do |data|
    if key = data.content.match(/([^:]*):\ (.*)/) and field_names.has_key?(key.captures[0])
      meta[field_names[key.captures[0]]] = key.captures[1]
    end
  end
  
  puts "\n\nRecord Parsed:"
  puts "Description: #{description[0].content.strip()}"
  puts "Address: #{address[0].content.split("\n")[0].strip()}"
  puts "Metadata:"
  meta.each {|k, v| puts "  *#{k}: #{v}" }
else
  puts "Problem fetching #{url}"
end
