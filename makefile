start_super_peer: super_peer_1 super_peer_2 super_peer_3 super_peer_4

super_peer_1:
	cd super_peers && PEER_ID=super_peer1 ruby index_server.rb

super_peer_2:	
	cd super_peers && PEER_ID=super_peer2 ruby index_server.rb 

super_peer_3:	
	cd super_peers && PEER_ID=super_peer3 ruby index_server.rb 

super_peer_4:	
	cd super_peers && PEER_ID=super_peer4 ruby index_server.rb 

search:
	curl http://localhost:$($(client))/search/$(file)

retrieve:
	curl http://localhost:$($(client))/retrieve/$(file)/$(server)
