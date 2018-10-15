require 'sinatra'
require "listen"
require "httparty"
require 'pry'
require 'fileutils'
require 'dotenv'
require 'yaml'
config = YAML::load(File.open("#{ENV['SP_ID']}.yml"))

# All instance variables are designed to take values from the environmental files.
# Sample:
# @watching_directory = /Users/pinki/academics/AOS/p2p/leaf_peer/peer1
# @peer_host = http://localhost:4101
# @peer_id = 4101
# @index_server_host = http://localhost:4100
@watching_directory = config[ENV['PEER_ID']]['DIRECTORY']
@peer_host = config[ENV['PEER_ID']]['PEER_HOST']
@peer_id = config[ENV['PEER_ID']]['PEER_ID']
@index_server_host = config[ENV['PEER_ID']]['INDEX_HOST']

# Creates peer directories on Initialization
unless File.directory?(@watching_directory)
  FileUtils.mkdir_p(@watching_directory)
end

puts "----------**********************************************************************************--------"

# Peer client attenpts to register with its super peer.
def register_peer
  puts "Registering with Index Server at #{@index_server_host}\n"
  begin 
    HTTParty.post(
      "#{@index_server_host}/register_peer", 
      {body: {peer_id: @peer_id, host: @peer_host}}
    )
  rescue => e
    puts "Failed to register with Index Server. Exiting..."
    exit false
  end
  puts "Successfully registered with Index Server - #{@peer_id}"
end


# Method executes when leaf peer has a new file added to its path
def file_added file_path
  puts "File added - #{file_path} to #{@peer_id}"
  update_file_on_index 'add', file_path
end

# When file from leaf peer directory is removed
def file_removed file_path
  puts "File removed - #{file_path} to #{@peer_id}"
  update_file_on_index 'remove', file_path
end

# An update sent to Super Peer to make note of its directory changes.
def update_file_on_index op, file_path
  begin 
    HTTParty.post(
      "#{@index_server_host}/update_index", {
        body: {
          peer_id: @peer_id, 
          file_path: file_path,
          op: op
        }
      }
    )
    puts "Successfully updated the index server"
  rescue => e
    puts "Failed to update the index server"
  end
end

def clean_file_path path
  path.gsub "#{@watching_directory}/", ""
end

puts "Initializing Peer - #{@peer_id} at #{@peer_host}"
register_peer

# Added listener to client directories to monitor all changes to the directory, so the central indexing server can always be at sync with the client peers.
# Using Listen library to monitor all changes.
listener = Listen.to(@watching_directory) do |modified, added, removed|
  file_added clean_file_path(added.first) unless added.empty?
  file_removed clean_file_path(removed.first) unless removed.empty?
end

listener.start # not blocking
puts "Watching file changes at #{@watching_directory}\n"
sleep

