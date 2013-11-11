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

        subject { CLPostParse.get_images(page) }

        context "with a valid post with images" do
            let(:page) { @listing }

            it "gets all images" do
                expect(subject).to have(7).items
                subject.each { |x| expect(x).to match(/^[a-zA-Z0-9_\-]*\.jpg$/) }
            end
        end

        context "with a valid post with images that don't exist" do
            let(:page) do
                path = './spec/resources/cl_post_bad_images.html'
                Nokogiri::HTML(open(path))
            end

            it "returns an empty array" do
                expect(subject).to be_empty
            end
        end

        context "with a valid post without images" do
            let(:page) do
                path = './spec/resources/cl_post_no_images.html'
                Nokogiri::HTML(open(path))
            end

            it "returns an empty array" do
                expect(subject).to be_empty
            end
        end

        context "with non CL website" do
            let(:page) do
                url = 'http://www.google.com'
                Nokogiri::HTML(RestClient.get(url))
            end

            it "returns an empty array" do
                expect(subject).to be_empty
            end
        end

        context "with a nil page" do
            let(:page) { Nokogiri::HTML(nil) }

            it "returns an empty array" do
                expect(subject).to be_empty
            end
        end

        context "with a nil post" do
            let(:page) { nil }
            it "returns an empty array" do
                expect(subject).to be_empty
            end
        end
    end

    describe "#get_description" do
        subject { CLPostParse.get_description(page) }

        context "with a valid post" do
            let(:page) { @listing }

            it "gets the description" do
                expect(subject).to be_a(String)
                expect(subject.split(/\W/)).to have_at_least(50).words
            end
        end

        context "with a nil post" do
            let(:page) { nil }
            it "returns nil" do
                expect(subject).to be_nil
            end
        end

        context "with non CL website" do
            let(:page) do
                url = 'http://www.google.com'
                Nokogiri::HTML(RestClient.get(url))
            end

            it "returns nil" do
                expect(subject).to be_nil
            end
        end

        context "with a nil page" do
            let(:page) { Nokogiri::HTML(nil) }

            it "returns nil" do
                expect(subject).to be_nil
            end
        end
    end

    describe "#get_address" do
        subject { CLPostParse.get_address(page) }

        context "with a valid post with an address" do
            let(:page) { @listing }
            it "gets the address" do
                expect(subject).to have_key('addr')
                expect(subject).to have_key('city')
                expect(subject).to have_key('state')
                expect(subject).to include('state' => 'Utah', 'city' => 'Park City')
            end
        end

        context "with a valid post with an incomplete address" do
            let(:page) do
                path = './spec/resources/cl_post_incomplete_addr.html'
                Nokogiri::HTML(open(path))
            end

            it "has incomplete details" do
                expect(subject).to include('area')
            end
        end

        context "with a valid post without an address" do
            let(:page) do
                path = './spec/resources/cl_post_no_images.html'
                Nokogiri::HTML(open(path))
            end

            it "returns nil" do
                expect(subject).to be_nil
            end
        end

        context "with a nil post" do
            let(:page) { nil }
            it "returns nil" do
                expect(subject).to be_nil
            end
        end

        context "with non CL website" do
            let(:page) do
                url = 'http://www.google.com'
                Nokogiri::HTML(RestClient.get(url))
            end

            it "returns nil" do
                expect(subject).to be_nil
            end
        end

        context "with a nil page" do
            let(:page) { Nokogiri::HTML(nil) }

            it "returns nil" do
                expect(subject).to be_nil
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
        subject { CLPostParse.get_metadata(page, tags) }
        let(:tags) { @valid_tags }

        context "with a valid post" do
            let(:page) { @listing }

            it "gets the tags" do
                @valid_tags.each_value do |v|
                    expect(subject).to include(v)
                end
            end

            context "and invalid tags" do
                let(:tags) { @invalid_tags }

                it "doesn't find invalid tags" do
                    @invalid_tags.each_value {|v| expect(subject).to include(v)}
                    subject.each_value {|v| expect(v).to be_nil }
                end
            end
        end

        context "with a valid post without any tags" do
            let(:page) do
                path = './spec/resources/cl_post_no_images.html'
                Nokogiri::HTML(open(path))
            end

            it "should have CL meta data" do
                expect(subject).to include('cl_id'=> '4001852052', \
                     'post_date'=> '2013-08-14,  1:10PM MDT', \
                     'updated_date'=> '2013-10-21, 12:30PM MDT'
                )
                ['dog_friendly', 'cat_friendly', 'cl_location'].each do |k|
                    expect(subject[k]).to be_nil
                end
            end
        end

        context "with a nil post" do
            let(:page) { nil }
             it "returns nil" do
                expect(subject).to be_nil
            end
        end

        context "with non CL website" do
            let(:page) do
                url = 'http://www.google.com'
                Nokogiri::HTML(RestClient.get(url))
            end

            it "doesn't find the tags" do
                @valid_tags.each_value do |v| 
                    expect(subject).to include(v)
                    expect(subject[v]).to be_nil
                end
            end
        end

        context "with a nil page" do
            let(:page) { Nokogiri::HTML(nil) }

            it "doesn't find the tags" do
                @valid_tags.each_value do |v| 
                    expect(subject).to include(v)
                    expect(subject[v]).to be_nil
                end
            end
        end
    end

    describe "#parse_page" do
        subject { CLPostParse.parse_page(page, url) }
        let (:url) { 'http://saltlakecity.craigslist.org/apa/3986668275.html' }
        context "with a valid post" do
            let(:page) { @listing }

            it "Parses the page correctly" do
                expect(subject).to be_a(Hash)
                expect(subject).to have_key('images')
                expect(subject['images']).to be_a(Array)
                expect(subject).to have_key('address')
                expect(subject).to have_key('description')
                expect(subject).to have_key('url')
                expect(subject).to have_key('updated')
                expect(subject).to have_key('retrieved')
                expect(subject).to have_key('metadata')
                expect(subject['metadata']).to be_a(Hash)
            end
        end

        context "with a nil post" do
            let(:page) { nil }
            it "returns nil" do
                expect(subject).to be_nil
            end
        end

        context "with non CL website" do
            let(:page) do
                url = 'http://www.google.com'
                Nokogiri::HTML(RestClient.get(url))
            end

            it "returns nil" do
                expect(subject).to be_nil
            end
        end

        context "with a nil page" do
            let(:page) { Nokogiri::HTML(nil) }

            it "returns nil" do
                expect(subject).to be_nil
            end
        end
    end
end
