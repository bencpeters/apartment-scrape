# GridFS based interface to save/retrieve files
require 'mongo'
include Mongo

module GridFSInterface
  extend self

  # Configures the mongo database interface for this module
  def configure(hostname, port_num, coll_name)
    @host = hostname
    @port = port_num
    @coll = coll_name
  end

  def host
    @host || 'localhost'
  end

  def port
    @port || 27017
  end

  def coll
    @coll || 'image_store'
  end

  def db
    @db ||= MongoClient.new(host, port).db(coll)
  end

  def grid
    @grid ||= Grid.new(db)
  end

  def user
    @user ||= 'benpeters'
  end

  # Saves data to GridFS using the given file_name
  def save(file_name, data, *meta)
    id = grid.put(data, :filename => file_name,
        meta.nil? ? nil : :metadata => meta[0])
  end
end
