# AWS S3-based interface to save/retrieve files
require 'aws/s3'

module AWSS3Interface
    extend self

    def configure(options={})
        if options.has_key?(:access_key)
            @access_key=options[:access_key]
        end
        if options.has_key?(:access_secret)
            @access_secret=options[:access_secret]
        end
        if options.has_key?(:bucket)
            @bucket=options[:bucket]
        end
        initialize
    end

    def access_key
        @access_key || ENV['AMAZON_ACCESS_KEY_ID']
    end

    def access_secret
        @access_secret || ENV['AMAZON_SECRET_ACCESS_KEY']
    end

    def initalize
        if not @initialized
            AWS::S3::Base::establish_connection!(
                :access_key_id => access_key,
                :secret_access_key => access_secret)
        end
        @initalized=true
    end

    def bucket
        @bucket || 'bencpeters-classifieds'
    end

    def save(file_name, data, *meta)
        if data.nil? then return nil end
        initialize
        if file_name.nil?
            file_name = rand(36**8).to_s(20) 
        end
        AWS::S3::S3Object.store(file_name, data, bucket)
        file_name
    end
end
