load 'packet.rb'

#get a port isntead of defining it
port = 2000

client = UDPSocket.new

puts "Enter the network IP:"
networkIP = gets.chomp
client.connect(networkIP, port)

puts "enter program state"
state = gets.chomp

run = 1
if(state.to_i == 1)
    puts "Input an IP"
    ip = gets.chomp
    while(run == 1)
        puts "enter a message"
        msg = gets.chomp
        puts "message entered"
        packet = makePacket(ip, 1, 1, 1, 1, msg)
        #pass the port here
        sendPacket(client, port, packet, networkIP)
    end
else
    while(run == 1)
        packet = getPacket(client)
        puts packet.data
    end
end

puts "done"
