require 'sinatra'
require 'pry'
require "httparty"
require 'dotenv'

Dotenv.load("#{ENV['PEER_ID']}.env")

set :local_url, "http://localhost:"
set :port, ENV['PEER_PORT']
set :leaf_peers, {}

left = ENV['PEER_PORT'] == '4001' ? '4003' : ENV['PEER_PORT'].to_i - 1 
right = ENV['PEER_PORT'] == '4003' ? '4001' : ENV['PEER_PORT'].to_i + 1 
set :neighbour_peers, {
  "left": left,
  "right": right
}

set :files, {}
set :messages, []

puts "Super Peer starting..."

# Index server registers peers once they connect, adds it to registry if it isn't already present.
post '/register_peer' do
  if already_registered?
    puts "Peer #{params['peer_id']} already registered"
  else
    # Registering peer to the index server by adding it to the leaf_peers data structure.
    settings.leaf_peers[params['peer_id']] = {
      host: params['host'],
      peer_id: params['peer_id']
    }
    puts "Peer #{params['peer_id']} - #{params['host']} successfully registered"
  end
end

# File registry updated when there is any changes to the peer file system.
post '/update_index' do
  if params['op'] == 'add'
    # Update registry when new files added.
    add_file_to_index params['file_path'], params['peer_id']
    puts "New File #{params['file_path']} - #{params['peer_id']} added to index."
  elsif params['op'] == 'remove'
    # Update registry when files are removed from the system.
    remove_file_from_index params['file_path'], params['peer_id']
    puts "File #{params['file_path']} - #{params['peer_id']} removed from index."
  end
end

get '/file_index' do
  # Registry index
  settings.files.to_s
end

get '/search/:query' do
  content_type :json
  return "Timeout".to_json if condition_checks(params)
  settings.messages << params
  search_result = search_files(params, params[:query])
  params[:ttl] = params[:ttl].to_i - 1
  # If file found not found in leaf peers
  if search_result.empty?
    puts "Query MISS ---- Request sent to next Super Peer - #{settings.local_url}:#{settings.neighbour_peers[:right]} -- TTL - #{params[:ttl]}"
    params[:address] = ENV['PEER_HOST']
    params[:leaf] = false
    HTTParty.get("#{settings.local_url}#{settings.neighbour_peers[:right]}/search/#{params[:query]}",
    {
      body: params 
    }).parsed_response
  else
    # When the previous request was from a leaf node
    if params[:requester_address] == params[:address]
      puts "Download request forwarded to Super Peer Server to process download."
      HTTParty.post(
          "#{settings.leaf_peers[search_result.first[:peer_id]][:host]}/send_file", {
            body: { 
              file_name: params[:file_name],
              dest_folder: params[:dest_folder]
            }
          }
        )
    else
      puts "Query HIT ----- Back propogation request passed to - #{params[:address]}"
      params[:source_address] = 
      HTTParty.get("#{params[:address]}/search/#{params[:query]}",
      {
        body: params 
      }).parsed_response
    end
  end
  {results: search_result }.to_json
end

post '/retrieve' do
  # Index server posts to peer server to serve clients
  puts "Download request forwarded to Super Peer Server to process download."
  HTTParty.post(
      "#{settings.leaf_peers[params['peer_id_that_has_file']][:host]}/send_file", {
        body: { 
          file_name: params[:file_name],
          dest_folder: params[:dest_folder]
        }
      }
    )
end

post '/broadcast' do
  # Index server posts to peer server to serve clients
  puts "Broadcasting to Neighbour peers"
  HTTParty.post(
      "#{settings.leaf_peers[params['peer_id_that_has_file']][:host]}/send_file", {
        body: { 
          file_name: params[:file_name],
          dest_folder: params[:dest_folder]
        }
      }
    )
end


private

def already_registered?
  # Checks to see if peer already present. Returns boolean
  settings.leaf_peers.has_key? params['peer_id']
end

def filename path
  File.basename path
end

def add_file_to_index file_path, peer_id
  settings.files[filename file_path] ||= []

  return if file_already_indexed? file_path, peer_id

  settings.files[filename file_path] << {
    peer_id: peer_id,
    file_path: file_path
  } 
end

def remove_file_from_index file_path, peer_id
  # Remove files from the registry once the file is removed from the peer directory.
  return if settings.files.fetch(filename(file_path), []).empty?
  settings.files[filename file_path].delete_if do |entry|
    entry[:peer_id] == peer_id && entry[:file_path] == file_path
  end
end

def file_already_indexed? file_path, peer_id
  # Checks if file already indexed. Returns boolean.
  settings.files[filename file_path].any? do |entry| 
    entry[:peer_id] == peer_id && entry[:file_path] == file_path
  end
end

def search_files params, query
  # Used by peers to see the list of peers that has the requested file. Returns file name and peer that has the file to the client peer that is requesting.
  settings.files.keys.select do |name| 
    name.start_with? query
  end.map do |file|
    settings.files[file]
  end.flatten.map do |result|
    result.merge({
      url: "#{settings.leaf_peers[result[:peer_id]][:host]}/download?file_path=#{result[:file_path]}",
      ttl: 10,
      requester_address: params[:address]
    }) rescue nil
  end.compact
end

def condition_checks params
  return true if params[:ttl].to_i <= 0
  return true if params[:address] == ENV['PEER_HOST']
end