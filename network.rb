load 'packet.rb'

# Constants
port = 7000

network = UDPSocket.new
#this binds to INADDR_ANY (any incomming IP address)
network.bind('', port.to_i)

run = 1

puts "Please input the bit error rate (in percentage)"
dropRate = gets.chomp.to_i
puts "Please input the network delay (in milliseconds)"
delay = gets.chomp.to_f / 1000.0

puts "Starting the network... Waiting for packets"
while(run == 1)
	randNum = rand(100)
	packet = getPacket(network)
	if packet.type == 1
		puts "Sending packet #{packet.seqNum} data: #{packet.data} to #{packet.src_ip} from #{packet.dest_ip}"
	else
		puts "Sending ACK #{packet.seqNum} to #{packet.src_ip} from #{packet.dest_ip}"
	end
	
	if(dropRate > randNum)
		if packet.type == 1
			puts "Dropped packet #{packet.seqNum}"
		elsif packet.type == 0
			puts "Dropped ACK #{packet.seqNum}"
		elsif packet.type == 2
			puts "Dropped EOT packet"
		end
	else
		sleep(delay)
		sendPacket(network, port, packet)
	end
end
