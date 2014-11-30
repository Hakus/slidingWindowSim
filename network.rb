load 'packet.rb'

#get port instead of defining it
port = 7005

network = UDPSocket.new
#this binds to INADDR_ANY (any incomming IP address)
network.bind('', port.to_i)

# for i in 0..Socket.ip_address_list.size-1
# 	puts Socket.ip_address_list[i].ip_address
# end

run = 1
wSize = 5
packetAmt = 11

while(run == 1)
	packet = getPacket(network)
	puts "Sending #{packet.data} to #{packet.dest_ip} from #{packet.src_ip}"
	sendPacket(network, port, packet)
	ack = getPacket(network)
	puts "Sending ACK type #{ack.type} to #{packet.dest_ip} from #{packet.src_ip}"
	sendPacket(network, port, ack)
end
