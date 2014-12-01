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
		puts "[SEND] Sending packet #{packet.seqNum} data: #{packet.data} to #{packet.src_ip}"
	elsif packet.type == 0
		puts "[RECV] Sending ACK #{packet.seqNum} to #{packet.src_ip}"
	else
		puts "[EOT] Sending EOT to #{packet.src_ip}"
	end
	
	if(dropRate > randNum)
		if packet.type == 1
			puts "[NTWK] Dropped packet #{packet.seqNum}"
		elsif packet.type == 0
			puts "[NTWK] Dropped ACK #{packet.seqNum}"
		elsif packet.type == 2
			puts "[NTWK] Dropped EOT packet"
		end
	else
		sleep(delay)
		sendPacket(network, port, packet)
	end
end
