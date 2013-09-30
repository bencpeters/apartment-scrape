# Grabs a specific craigslist posting
require 'rest-client'
require 'nokogiri'
require 'fileutils'

module CLPostParse
  extend self

  # Configures this modules implementation specfic components,
  # such as telling it how to save images.
  def configure(file_module)
    @file_module = file_module
  end

  # Grabs all images out of a post and saves them to disk.
  # Returns a List of file names corresponding to saved images
  def get_images(npage)
    image_links = npage.css('#thumbs a')
    image_names = Array.new
    image_links.each do |link|
      image = RestClient.get(link['href'])
      filename = "img-#{link['href'].match(/[^\/]*$/)}"
      save_image(image, filename)
      image_names.push(filename)
    end
    return image_names
  end

  def get_description(npage)
    if npage.css('#postingbody').empty?
      'No Description Found'
    else
      npage.css('#postingbody')[0].content.strip()
    end
  end

  def get_address(npage)
    if npage.css('.cltags .mapaddress').empty?
      'No Address Found'
    else
      npage.css('.cltags .mapaddress')[0].content.split("\n")[0].strip()
    end
  end

  def get_metadata(npage, fields)
    meta = Hash.new
    npage.css('.cltags .blurbs li').each do |data|
      fields.each_key do |key|  
        unless data.content.match(key).nil? 
          if d = data.content.match(/#{key}: (.*)/)
            meta[fields[key]] = d.captures[0] 
          else
            meta[fields[key]] = true
          end
        end
      end
    end
    
    post_info = npage.css('div.postinginfos p')
    post_info.each do |data|
      if key = data.content.match(/([^:]*):\ (.*)/) and fields.has_key?(key.captures[0])
        meta[fields[key.captures[0]]] = key.captures[1]
      end
    end
    meta
  end
  
  private

  # Saves an image using the configured @file_module
  # If this module hasn't been configured, uses a 
  # regular filesystem write
  def save_image(image, name)
    if @file_module
      @file_module.save(name, image)
    else
      File.open("data/#{name}", 'w') { |f| f.write image }
    end
  end
end
