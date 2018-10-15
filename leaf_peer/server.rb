require 'sinatra'
require 'pry'
require 'httparty'

require 'dotenv'
require 'yaml'
config = YAML::load(File.open("#{ENV['SP_ID']}.yml"))

# All settings variables are designed to take values from the environmental files.
# Sample:
# port = http://localhost:4101
# index_server_host = http://localhost:4100
# file_directory = /Users/pinki/academics/AOS/p2p/leaf_peer/peer1

set :port, config[ENV['PEER_ID']]['PEER_PORT']
set :index_server_host, config[ENV['PEER_ID']]['INDEX_HOST']
set :file_directory, config[ENV['PEER_ID']]['DIRECTORY']
# Search is sent with the query(file name), ttl and other attributes that help in identifying the query to the indexing server. 
# message ID is a unique id assigned to every query, which helps in back propogation and to limit super peers from entering a forever loop.
get '/search/:query' do
  message = {
    message_id: SecureRandom.hex,
    ttl: 10,
    file_name: params[:query],
    requester_address: config[ENV['PEER_ID']]['INDEX_HOST'],
    address: config[ENV['PEER_ID']]['PEER_HOST'],
    dest_folder: settings.file_directory,
    hit: "false"
  }

  # Request passed to the Super Peer from the Leaf Peer.
  HTTParty.get("#{settings.index_server_host}/search/#{params[:query]}",
    {
      body: message 
    }).parsed_response
  puts "Request forwarded to Super Peer - #{settings.index_server_host}"
end

post '/send_file' do
  # Incoming request from the Super Peer to serve the file to the requesting client
	file_path = "#{settings.file_directory}/" + params[:file_name]
	puts file_path
  # Files are sent from the serving peer to the requesing peer.
	FileUtils.cp(file_path, params[:dest_folder])
  puts "File sent to peer that requested. Request complete"
	puts "Display File - #{params[:file_name]}"
end