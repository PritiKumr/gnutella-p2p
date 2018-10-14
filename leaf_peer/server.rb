require 'sinatra'
require 'pry'
require 'httparty'

require 'dotenv'
Dotenv.load(".env", "#{ENV['PEER_ID']}.env")

# All settings variables are designed to take values from the environmental files.
# Sample:
# port = http://localhost:3001
# index_server_host = http://localhost:4567
# file_directory = /Users/pinki/academics/AOS/p2p/peer/peer1

set :port, ENV['PEER_PORT']
set :index_server_host, ENV['INDEX_HOST']
set :file_directory, ENV['DIRECTORY']

# Search is sent with the query(file name) to the indexing server. 
get '/search/:query' do
  content_type :json
  message = {
    message_id: SecureRandom.hex,
    ttl: 10,
    file_name: params[:query],
    requester_address: ENV['PEER_HOST'],
    address: ENV['PEER_HOST'],
    dest_folder: settings.file_directory
  }
  HTTParty.get("#{settings.index_server_host}/search/#{params[:query]}",
    {
      body: message 
    }).parsed_response
  {results: "Request forwarded to Super Peer" }.to_json
end

# Once the peer knows the peer that has the file, a request is sent to index server to let the server of the peer serve the file.
get '/retrieve/:file_name/:peer_id_that_has_file' do
  # URL encoded properly to follow strict URL restrictions.
	uri = URI.parse(URI.encode(settings.index_server_host.to_s + "/retrieve"))
	HTTParty.post(
      uri, {
        body: { 
          file_name: params[:file_name],
          dest_folder: settings.file_directory,
          peer_id_that_has_file: params[:peer_id_that_has_file]
        }
      }
    )
	puts "File download request sent to Index server"
end

post '/send_file' do
  # Incoming request from the Index server to serve the file to the requesting client
  binding.pry
	file_path = "#{settings.file_directory}/" + params[:file_name]
	puts file_path
  # Files are sent from the serving peer to the requesing peer.
	FileUtils.cp(file_path, params[:dest_folder])
  puts "File sent to peer that requested. Request complete"
	puts "Display File - #{params[:file_name]}"
end

get '/download' do
  # Additional method to the client peer to directly download with the link to file.
  send_file "#{settings.file_directory}/#{params[:file_path]}", :filename => File.basename(params[:file_path]), :type => 'Application/octet-stream'
end