load 'packet.rb'

#get a port isntead of defining it
port = 7005

client = UDPSocket.new

run = 1
wSize = 5
packetAmt = 11

puts "Enter the network IP:"
networkIP = gets.chomp
client.connect(networkIP, port)
client.bind('', port)

puts "enter program state"
state = gets.chomp


if(state.to_i == 1)
    puts "Input an IP"
    ip = gets.chomp
    while(run == 1)
        puts "enter a message"
        msg = gets.chomp
        packet = makePacket(ip, 1, 1, 1, 1, msg)
        sendPacket(client, port, packet, networkIP)
        ack = getPacket(client)
        puts "Received ACK from #{ack[1]}"
    end
else
    while(run == 1)
        packet = getPacket(client)
        puts packet.data
    end
end

puts "done"
