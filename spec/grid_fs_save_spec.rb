require 'spec_helper'
require 'mongo'

describe GridFSInterface do
    before :all do
        #TODO: update this so that mongo server isn't hard-coded into spec
        @mongo = MongoClient.new('localhost', 27017)
        raise "No valid mongo connection established! Verify that the mongo " \
              "server is running?" unless @mongo.connected?
        GridFSInterface.user = 'test_user'
    end
    
    before :each do
        @mongo.drop_database('grid_fs_save_test')
        @grid_handle = GridFSInterface.grid
    end

    describe "#save" do
        before :each do
            meta = nil unless defined? meta
            @id = GridFSInterface.save(name, data, meta)
        end

        subject { @grid_handle.get(@id) }

        context "saving a valid image" do
            let(:name) { "file-name" }
            let(:data) { File.read('./spec/resources/sample-img.jpg') }

            it { should be_a(Mongo::GridIO) }
            its(:file_length) { should be > 0 }
            its(:filename) { should eq("file-name") }
            
            context "without a file name" do
                let(:name) { nil }

                it { should be_a(Mongo::GridIO) }
                its(:file_length) { should be > 0 }
                its(:filename) { should be_nil }
            end
        end

        context "trying to save a nil image" do
            let(:data) { nil }
            let(:name) { "file-name" }
            subject { @id }

            it { should be_nil }
        end
    end

    describe "#grid" do
        subject(:image) { GridFSInterface.grid.get(id) }

        context "accessing a previously saved image" do
            let(:id) { @grid_handle.put(File.read( \
                './spec/resources/sample-img.jpg' ), :filename => 'my_file') }

            it "should be able to get the image" do
                expect(image).to be_a(Mongo::GridIO)
                expect(image.file_length).to be > 0
                expect(image.filename).to eq('my_file')
            end
        end
    end

    after :all do
        @mongo.drop_database('grid_fs_save_test')
    end

end
