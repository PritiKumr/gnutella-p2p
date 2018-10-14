require 'sinatra'
require "listen"
require "httparty"
require 'pry'

require 'dotenv'
Dotenv.load("#{ENV['PEER_ID']}.env")

# All instance variables are designed to take values from the environmental files.
# Sample:
# @watching_directory = /Users/pinki/academics/AOS/p2p/peer/peer1
# @peer_host = http://localhost:3001
# @peer_id = 3001
# @index_server_host = http://localhost:4567

@watching_directory = ENV['DIRECTORY']
@peer_host = ENV['PEER_HOST']
@peer_id = ENV['PEER_ID']
@index_server_host = ENV['INDEX_HOST']

# Peer client attenpts to register with the index server on initial setup.
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

def file_added file_path
  puts "File added - #{file_path} to #{@peer_id}"
  update_file_on_index 'add', file_path
end

def file_removed file_path
  puts "File removed - #{file_path} to #{@peer_id}"
  update_file_on_index 'remove', file_path
end

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

