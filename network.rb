load 'packet.rb'

#get port instead of defining it
port = 7005

network = UDPSocket.new
#this binds to INADDR_ANY (any incomming IP address)
network.bind('', port.to_i)

dropRate = 50
randNum = rand(100)
run = 1

while(run == 1)
	puts sleep(1.0/randNum.to_f)
	packet = getPacket(network)
	if packet.type == 1
		puts "Sending #{packet.data} to #{packet.dest_ip} from #{packet.src_ip}"
	else
		puts "Sending ACK to #{ack.dest_ip} from #{ack.src_ip}"
	end
	
	if(dropRate > randNum)
		puts "Dropped packet #{packet.seqNum}"
	else
		sendPacket(network, port, packet)
	end
end
