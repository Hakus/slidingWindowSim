load 'packet.rb'

#get port instead of defining it
port = 7000

network = UDPSocket.new
#this binds to INADDR_ANY (any incomming IP address)
network.bind('', port.to_i)

dropRate = 20
run = 1

while(run == 1)
	randNum = rand(100)
	packet = getPacket(network)
	if packet.type == 1
		puts "Sending packet #{packet.seqNum} data: #{packet.data} to #{packet.src_ip} from #{packet.dest_ip}"
	else
		puts "Sending ACK #{packet.seqNum} to #{packet.src_ip} from #{packet.dest_ip}"
	end
	
	if(dropRate > randNum)
		if(packet.type == 1)
			puts "Dropped packet #{packet.seqNum}"
		else
			puts "Dropped ACK #{packet.seqNum}"
		end
	else
		sleep(0.2)
		sendPacket(network, port, packet)
	end
end
