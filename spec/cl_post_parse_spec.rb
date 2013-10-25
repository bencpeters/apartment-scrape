require 'spec_helper'
require 'rest-client'
require 'nokogiri'

class DummyWriter
    def self.save(*args)
    end
end

describe CLPostParse do
    before :all do
        path = './spec/resources/sample-cl-listing.html'
        @listing = Nokogiri::HTML(open(path))    
    end

    describe "#get_images" do
        before :each do 
            CLPostParse.configure(DummyWriter)
        end

        context "with a valid post with images" do
            it "gets all images" do
                images = CLPostParse.get_images(@listing)
                images.should have(7).items
            end
        end
    end
end
