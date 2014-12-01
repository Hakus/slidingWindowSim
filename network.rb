load 'packet.rb'

#get port instead of defining it
port = 7000

network = UDPSocket.new
#this binds to INADDR_ANY (any incomming IP address)
network.bind('', port.to_i)

dropRate = 50
run = 1

while(run == 1)
	randNum = rand(100)
	packet = getPacket(network)
	if packet.type == 1
		puts "Sending #{packet.data} to #{packet.dest_ip} from #{packet.src_ip}"
	else
		puts "Sending ACK to #{packet.dest_ip} from #{packet.src_ip}"
	end

	sleep(1.0/randNum.to_f)
	
	if(dropRate > randNum)
		puts "Dropped packet #{packet.seqNum}"
	else
		sendPacket(network, port, packet)
	end
end
