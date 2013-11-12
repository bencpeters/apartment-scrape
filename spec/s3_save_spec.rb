require 'spec_helper'
require 'aws/s3'

describe AWSS3Interface do
    before :all do
        AWS::S3::Base.establish_connection!(
            :access_key_id => ENV['AMAZON_ACCESS_KEY_ID'], 
            :secret_access_key => ENV['AMAZON_SECRET_ACCESS_KEY'])
        @bucket_name = 'bencpeters-classifieds-testing'
        AWS::S3::Bucket.create(@bucket_name)
        @test_bucket = AWS::S3::Bucket.find(@bucket_name)
        AWSS3Interface.configure(:bucket => @bucket_name)
    end

    after :all do
        AWS::S3::Bucket.delete(@bucket_name, :force => true)
    end

    describe "#save" do
        after :each do
            AWS::S3::S3Object.delete(name, @bucket_name) unless \
                @test_bucket[name].nil?
        end

        subject do 
            meta = nil unless defined? meta
            file = AWSS3Interface.save(name, data, meta)
            AWS::S3::S3Object.find(file, @bucket_name) unless file.nil?
        end

        let(:name) { "file-name.jpg" }

        context "save a valid image" do
            let(:data) { File.read('./spec/resources/sample-img.jpg') }

            it "should save to S3" do
                expect(subject).to be_a(AWS::S3::S3Object)
                expect(subject.content_type).to eq("image/jpeg")
                expect(subject.content_length.to_i).to be > 0
            end

            context "without a file name" do
                let(:name) { nil }

                it "should save using another name" do
                    expect(subject).to be_a(AWS::S3::S3Object)
                    expect(subject.content_length.to_i).to be > 0
                end
            end
        end

        context "with a nil image" do
            let(:data) { nil }

            it "should not save" do
                expect(subject).to be_nil
            end
        end
    end
    
    describe "#delete" do
        before :each do 
            data = File.read('./spec/resources/sample-img.jpg') 
            AWS::S3::S3Object.store('file-name.jpg', data, @bucket_name)
        end
        
        subject { AWSS3Interface.delete(file) }

        context "with a file that exists" do
            let (:file) { 'file-name.jpg' }

            it "should delete the file" do
                expect { AWS::S3::S3Object.find('file=-name.jpg', @bucket_name) } \
                    .to raise_error AWS::S3::NoSuchKey
            end
        end

        context "with a file that doesn't exist" do
            let (:file) { 'made-up-name.jpg' }
            it "should return quietly" do
                expect(AWS::S3::S3Object.find('file-name.jpg', @bucket_name)) \
                    .to be_a(AWS::S3::S3Object)
            end
        end

        context "with a nil file name" do
            let (:file) { nil }
            it "should not do anything" do
                expect(AWS::S3::S3Object.find('file-name.jpg', @bucket_name)) \
                    .to be_a(AWS::S3::S3Object)
            end
        end
    end
end
