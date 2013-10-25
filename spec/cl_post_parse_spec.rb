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
                images.each { |x| expect(x).to match(/^[a-zA-Z0-9_\-]*\.jpg$/) }
            end
        end

        context "with a valid post with images that don't exist" do
            before :all do
                path = './spec/resources/cl_post_bad_images.html'
                @bad_img_listing = Nokogiri::HTML(open(path))
            end

            it "returns an empty array" do
                images = CLPostParse.get_images(@bad_img_listing)
                images.should be_empty
            end
        end

        context "with a valid post without images" do
            before :all do
                path = './spec/resources/cl_post_no_images.html'
                @no_img_listing = Nokogiri::HTML(open(path))
            end

            it "returns an empty array" do
                images = CLPostParse.get_images(@no_img_listing)
                images.should be_empty
            end
        end

        context "with an invalid post" do
            before :all do
                url = 'http://www.google.com'
                @google_npage = Nokogiri::HTML(RestClient.get(url))
                @nil_npage = Nokogiri::HTML(nil)
            end

            it "returns an empty array for Google" do
                images = CLPostParse.get_images(@google_npage)
                images.should be_empty
            end
            it "returns an empty array for nil" do
                images = CLPostParse.get_images(@nil_npage)
                images.should be_empty
            end
        end

        context "with a nil post" do
            it "returns an empty array" do
                images = CLPostParse.get_images(nil)
                images.should be_empty
            end
        end
    end
end
