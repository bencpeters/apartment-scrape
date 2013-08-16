require 'rest-client'
require 'nokogiri'
require 'fileutils'
require_relative './lib/cl_post_parse'

url = 'http://saltlakecity.craigslist.org/apa/3990520051.html'
url = 'http://saltlakecity.craigslist.org/apa/3986668275.html'
if page = RestClient.get(url)
  puts "\nGot #{url} successfully!"
  File.open("data/cl-#{url.match(/[^\/]*$/)}", 'w') { |f| f.write page.body }
  npage = Nokogiri::HTML(page)

  # Grab thumbs/images
  image_names = CLPostParse.get_images(npage)
  description = CLPostParse.get_description(npage)
  address = CLPostParse.get_address(npage)
  cl_tags_of_interest = { 'purrr' => 'cat_friendly', 'wooof' => 'dog_friendly', 'Location' => 'cl_location' }
  fieldnames = { 'Posting ID' => 'cl_id', 'Posted' => 'post_date', 'Updated' => 'updated_date' }.merge(cl_tags_of_interest)
  meta = CLPostParse.get_metadata(npage, fieldnames)
  meta['images'] = image_names

  puts "\n\nRecord Parsed:"
  puts "Description: #{description}"
  puts "Address: #{address}"
  puts "Metadata:"
  meta.each {|k, v| puts "  *#{k}: #{v}" }
else
  puts "Problem fetching #{url}"
end
