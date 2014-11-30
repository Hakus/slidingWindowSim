load 'packet.rb'

#get port instead of defining it
port = 7005

network = UDPSocket.new
#this binds to INADDR_ANY (any incomming IP address)
network.bind('', port.to_i)

# dropRate = 50
# randNum = rand(100)

while(run == 1)
	packet = getPacket(network)
	if packet.type == 1
		puts "Sending #{packet.data} to #{packet.dest_ip} from #{packet.src_ip}"
	else
		puts "Sending ACK to #{ack.dest_ip} from #{ack.src_ip}"
	end
	# if(dropRate < randNum)
		sendPacket(network, port, packet)
	# end
end
