load 'udp-common.rb'

# Constants
port = 2000
offset = 5

# Packet = Struct.new(:type, :seqNum, :data, :windowSize, :ackNum)

server = UDPSocket.new
server.bind("localhost", port)
server.connect("localhost", port+1)

fileName = server.gets.chomp
puts "Filename is " + fileName
fileSize = server.gets.chomp
puts "FileSize is " + fileSize

recvSize = 0
run = 1

File.open("received/#{fileName}", 'wb') do |file|
	puts "Receiving #{fileName} and storing it to received folder"
	while(run == 1)

		# Get data from socket
		packet = getPacket(server)

		if(packet.type == 2)
			sendPacket(server, makePacket("localhost", 2, 0, 0, 0, ""))
			puts "Acknowledged EOT"
			break
		else
			# Write to file
			file.print packet.data
			# Increase received size
			recvSize += packet.data.size
			puts "Received: #{packet.data.size} bytes " +
					"| Total received: #{recvSize} bytes | Num: #{packet.seqNum}"
			
			ack = makePacket(0, packet.seqNum, 1, packet.seqNum+1, localhost, "")
			sendPacket(server, ack)
		end
	end
end
