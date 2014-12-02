load 'packet.rb'

# Setting up the logger
$log = setupLog('network.log')

# Constants
port = 7000

#this binds to any incoming IP address
network = UDPSocket.new
network.bind('', port.to_i)

# Receiving required user inputs
puts "Please input the bit error rate (in percentage)"
dropRate = gets.chomp.to_i
puts "Please input the network delay (in milliseconds)"
delay = gets.chomp.to_f / 1000.0

puts "Starting the network... Waiting for packets"
$log.info("[NTWK] Starting the network")

# Run forever
while(1!=0)
	# Wait for a packet from the network socket
	packet = getPacket(network)
	# Once we get a packet, determime the type
	# 0 = ACK, 1 = DATA, 2 = EOT
	if packet.type == 1
		puts "[SEND] Sending data packet #{packet.seqNum}: #{packet.data} to #{packet.src_ip}"
		$log.info("[SEND] Sending data packet #{packet.seqNum}: #{packet.data} to #{packet.src_ip}")
	elsif packet.type == 0
		puts "[RECV] Sending ACK packet #{packet.seqNum} to #{packet.src_ip}"
		$log.info("[RECV] Sending ACK packet #{packet.seqNum} to #{packet.src_ip}")
	else
		puts "[EOT] Sending EOT to #{packet.src_ip}"
		$log.info("[EOT] Sending EOT to #{packet.src_ip}")
	end

	
	randNum = rand(100) # Generate a random number
	if(dropRate > randNum) # Determine whether or not to drop a packet
		if packet.type == 1
			puts "[NTWK] Dropped packet #{packet.seqNum}"
			$log.info("[NTWK] Dropped packet #{packet.seqNum}")
		elsif packet.type == 0
			puts "[NTWK] Dropped ACK #{packet.seqNum}"
			$log.info("[NTWK] Dropped ACK #{packet.seqNum}")
		elsif packet.type == 2
			puts "[NTWK] Dropped EOT packet"
			$log.info("[NTWK] Dropped EOT packet")
		end
	else
		sleep(delay) # network delay before sending a packet
		sendPacket(network, port, packet)
	end
end
