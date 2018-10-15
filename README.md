# A Hierarchical Gnutella-style P2P File Sharing System

## Starting the server

1. `make -j10 start_super_peers`

## Starting Peers

Each super peer has upto 4 leaf peers attached. 

1. `make -j25 start_leaf_peers sp_id=sp1` 

This command starts 4 leaf peers for the super peer sp1.

