load 'packet.rb'

#get a port isntead of defining it
$port = 7005
$local_ip = UDPSocket.open {|s| s.connect("64.233.187.99", 1); s.addr.last}

run = 1
wSize = 5

puts "Enter the network IP:"
networkIP = gets.chomp
client = UDPSocket.new
client.bind('', $port)
client.connect(networkIP, $port)

puts "Enter program state. Can be 0 or 1 (send or receive)"
state = gets.chomp

if(state.to_i == 0)
    puts "Input an IP"
    ip = gets.chomp
    while(run == 1)
        msg = ["Hello", "How", "Are", "You", "Bob", "I", "Am", "Fine", "Thanks"]
        packetAmt = msg.size
        # msg = gets.chomp.split(/\W+/)
        receivedACKS = 0
        windowACKS = 0
        while(windowACKS < packetAmt)
            window = fillWindow(ip, windowACKS, msg, wSize)
            sendWindow(networkIP, window, client)
            while(receivedACKS < wSize)
                begin
                    Timeout.timeout(1) do
                    ack = getPacket(client)
                    puts "Received ACK (type = #{ack.type}) response from #{ack.src_ip}"
                    receivedACKS += 1
                    windowACKS += 1
                    end
                rescue Timeout::Error
                    puts "A packet may have been dropped. Resend window"
                    break
                end
            end
        end
    end
else
    while(run == 1)
        packet = getPacket(client)
        puts "Received #{packet.data} from #{packet.src_ip}"
        ack = makePacket(packet.src_ip, $local_ip, 0, 1, 1, "ACK")
        sendPacket(client, $port, ack, networkIP)
    end
end

puts "done"
