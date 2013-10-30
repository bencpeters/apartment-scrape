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

    describe "#get_description" do

        context "with a valid post" do
            it "gets the description" do
                desc = CLPostParse.get_description(@listing)
                expect(desc).to be_a(String)
                expect(desc.split(/\W/)).to have_at_least(50).words
            end
        end

        context "with a nil post" do
            it "returns nil" do
                desc = CLPostParse.get_description(nil)
                expect(desc).to be_nil
            end
        end

        context "with an invalid post" do
            before :all do
                url = 'http://www.google.com'
                @google_npage = Nokogiri::HTML(RestClient.get(url))
                @nil_npage = Nokogiri::HTML(nil)
            end

            it "returns nil for Google" do
                desc = CLPostParse.get_description(@google_npage)
                expect(desc).to be_nil
            end
            it "returns nil for nil" do
                desc = CLPostParse.get_description(@nil_npage)
                expect(desc).to be_nil
            end
        end
    end

    describe "#get_address" do

        context "with a valid post with an address" do
            it "gets the address" do
                addr = CLPostParse.get_address(@listing)
                expect(addr).to have_key('addr')
                expect(addr).to have_key('city')
                expect(addr).to have_key('state')
                expect(addr).to include('state' => 'Utah', 'city' => 'Park City')
            end
        end

        context "with a valid post with an incomplete address" do
            before :all do
                path = './spec/resources/cl_post_incomplete_addr.html'
                @incomplete_addr = Nokogiri::HTML(open(path))
            end

            it "has incomplete details" do
                addr = CLPostParse.get_address(@incomplete_addr)
                expect(addr).to include('area')
            end
        end

        context "with a valid post without an address" do
            before :all do
                path = './spec/resources/cl_post_no_images.html'
                @no_addr_listing = Nokogiri::HTML(open(path))
            end

            it "returns nil" do
                addr = CLPostParse.get_address(@no_addr_listing)
                expect(addr).to be_nil
            end
        end

        context "with a nil post" do
            it "returns nil" do
                addr = CLPostParse.get_address(nil)
                expect(addr).to be_nil
            end
        end

        context "with an invalid post" do
            before :all do
                url = 'http://www.google.com'
                @google_npage = Nokogiri::HTML(RestClient.get(url))
                @nil_npage = Nokogiri::HTML(nil)
            end

            it "returns nil for Google" do
                addr = CLPostParse.get_address(@google_npage)
                expect(addr).to be_nil
            end
            it "returns nil for nil" do
                addr = CLPostParse.get_address(@nil_npage)
                expect(addr).to be_nil
            end
        end
    end

    describe "#get_metadata" do
        before :all do
            @valid_tags = { 'purrr'=> 'cat_friendly', 'wooof'=> \
                            'dog_friendly', 'Location'=> 'cl_location', \
                            'Posting ID'=> 'cl_id', 'Posted'=> 'post_date', \
                            'Updated'=> 'updated_date' }
            @invalid_tags = {'lbkjdafd'=> 'my_terrible_tag', '12312' => 'not_cool'}
        end

        context "with a valid post" do
            it "gets the tags" do
                meta_data = CLPostParse.get_metadata(@listing, @valid_tags)
                @valid_tags.each_value do |v|
                    expect(meta_data).to include(v)
                end
            end

            it "doesn't find invalid tags" do
                meta_data = CLPostParse.get_metadata(@listing, @invalid_tags)
                @invalid_tags.each_value {|v| expect(meta_data).to include(v)}
                meta_data.each_value {|v| expect(v).to be_nil }
            end
        end

        context "with a valid post without any tags" do
            before :all do
                path = './spec/resources/cl_post_no_images.html'
                @no_addr_listing = Nokogiri::HTML(open(path))
            end

            it "should have CL meta data" do
                meta_data = CLPostParse.get_metadata(@no_addr_listing, \
                                                     @valid_tags)
                expect(meta_data).to include('cl_id'=> '4001852052', \
                     'post_date'=> '2013-08-14,  1:10PM MDT', \
                     'updated_date'=> '2013-10-21, 12:30PM MDT'
                )
                ['dog_friendly', 'cat_friendly', 'cl_location'].each do |k|
                    expect(meta_data[k]).to be_nil
                end
            end
        end

        context "with a nil post" do
            it "returns nil" do
                meta_data = CLPostParse.get_metadata(nil, @valid_tags)
                expect(meta_data).to be_nil
            end
        end

        context "with an invalid post" do
            before :all do
                url = 'http://www.google.com'
                @google_npage = Nokogiri::HTML(RestClient.get(url))
                @nil_npage = Nokogiri::HTML(nil)
            end

            it "doesn't find the tags" do
                meta_data = CLPostParse.get_metadata(@google_npage, @valid_tags)
                @valid_tags.each_value do |v| 
                    expect(meta_data).to include(v)
                    expect(meta_data[v]).to be_nil
                end
            end
            it "doesn't find the tags" do
                meta_data = CLPostParse.get_metadata(@nil_npage, @valid_tags)
                @valid_tags.each_value do |v| 
                    expect(meta_data).to include(v)
                    expect(meta_data[v]).to be_nil
                end
            end
        end
    end
end
