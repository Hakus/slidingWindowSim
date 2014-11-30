load 'udp-common.rb'

# Constants
port = 2000
size = 2048
ip = "127.0.0.1"

# Packet = Struct.new(:type, :seqNum, :data, :windowSize, :ackNum)

client = UDPSocket.new
client.bind("localhost", port+1)
client.connect("localhost", port)

puts "Enter a filename"
fileName = gets.chomp
client.puts(fileName)

run = 1
sentData = 0
seqNum = 1
ackNum = 1
send_EOT = 0

File.open(fileName, 'rb') do |file|
	client.puts(file.size)
	packetAmount = (file.size.to_f / size).ceil
	puts "#{packetAmount} packets will be sent"


	while(run == 1)
		# sleep(1)
		# Fill the packet with data
		if(send_EOT == 1)
			sendPacket(client, makePacket(2, 0, 0, 0, ip, ""))
			puts "Sent EOT"
		else
			packet = makePacket(1, seqNum, 1, seqNum, ip, file.read(size))
			sendPacket(client, packet)
			# update the sent amount
			sentData += packet.data.size
			puts "Sent: #{packet.data.size} bytes " +
					"| Total sent: #{sentData} bytes | Num: #{packet.seqNum}"
		end

		ack = getPacket(client)

		if(ack.type == 2)
			puts "Received ACK for EOT"
			run = 0
		else
			seqNum = ack.ackNum
			if(sentData == file.size)
				send_EOT = 1
			end
		end
	end
end
