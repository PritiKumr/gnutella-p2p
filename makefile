start_super_peers: sp1 sp2 sp3 sp4 sp5 sp6 sp7 sp8 sp9 sp10

sp1:
	cd super_peers && PEER_ID=super_peer1 ruby index_server.rb start
sp2:
	cd super_peers && PEER_ID=super_peer2 ruby index_server.rb start
sp3:
	cd super_peers && PEER_ID=super_peer3 ruby index_server.rb start
sp4:
	cd super_peers && PEER_ID=super_peer4 ruby index_server.rb start
sp5:
	cd super_peers && PEER_ID=super_peer5 ruby index_server.rb start
sp6:
	cd super_peers && PEER_ID=super_peer6 ruby index_server.rb start
sp7:
	cd super_peers && PEER_ID=super_peer7 ruby index_server.rb start
sp8:
	cd super_peers && PEER_ID=super_peer8 ruby index_server.rb start
sp9:
	cd super_peers && PEER_ID=super_peer9 ruby index_server.rb start
sp10:
	cd super_peers && PEER_ID=super_peer10 ruby index_server.rb start

start_leafs: peer1 peer2 peer3 peer4

peer1: peer1_server peer1_client
peer1_server:
	cd leaf_peer && PEER_ID=peer1 SP_ID=$(sp_id) ruby server.rb
peer1_client:
	cd leaf_peer && PEER_ID=peer1 SP_ID=$(sp_id) ruby client.rb


peer2: peer2_server peer2_client
peer2_server:
	cd leaf_peer && PEER_ID=peer2 SP_ID=$(sp_id) ruby server.rb	
peer2_client:
	cd leaf_peer && PEER_ID=peer2 SP_ID=$(sp_id) ruby client.rb


peer3: peer3_server peer3_client
peer3_server:
	cd leaf_peer && PEER_ID=peer3 SP_ID=$(sp_id) ruby server.rb
peer3_client:
	cd leaf_peer && PEER_ID=peer3 SP_ID=$(sp_id) ruby client.rb


peer4: peer4_server peer4_client
peer4_server:
	cd leaf_peer && PEER_ID=peer4 SP_ID=$(sp_id) ruby server.rb
peer4_client:
	cd leaf_peer && PEER_ID=peer4 SP_ID=$(sp_id) ruby client.rb

search:
	curl http://localhost:$(port)/search/$(file)
