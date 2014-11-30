load 'packet.rb'

#get port instead of defining it
port = 7005

network_1 = UDPSocket.new
#this binds to INADDR_ANY (any incomming IP address)
network_1.bind('', port.to_i)


run = 1
wSize = 5
packetAmt = 11

while(run == 1)
	packet = getPacket(network_1)
	puts "Sending #{packet.data} to #{packet.dest_ip}"
	sendPacket(network_1, port, packet)
end
