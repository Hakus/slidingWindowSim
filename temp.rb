load 'packet.rb'

#get a port isntead of defining it
port = 7005


puts "Enter the network IP:"
networkIP = gets.chomp
client = UDPSocket.new
client.bind('', port)
client.connect(networkIP, port)

local_ip = UDPSocket.open {|s| s.connect("64.233.187.99", 1); s.addr.last}

run = 1
wSize = 5
packetAmt = 11

puts "enter program state"
state = gets.chomp

if(state.to_i == 1)
    puts "Input an IP"
    ip = gets.chomp
    while(run == 1)
        puts "enter a message"
        msg = gets.chomp
        packet = makePacket(ip, local_ip, 1, 1, 1, msg)
        sendPacket(client, port, packet, networkIP)
        ack = getPacket(client)
        puts "Received ACK (type = #{ack.type}) response from #{ack.src_ip}"
    end
else
    while(run == 1)
        packet = getPacket(client)
        puts "Received #{packet.data} from #{packet.src_ip}"
        ack = makePacket(packet.src_ip, local_ip, 0, 1, 1, "ACK")
        sendPacket(client, port, ack, networkIP)
    end
end

puts "done"
