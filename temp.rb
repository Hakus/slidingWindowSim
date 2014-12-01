load 'packet.rb'

#get a port isntead of defining it
$port = 7000
$local_ip = UDPSocket.open {|s| s.connect("64.233.187.99", 1); s.addr.last}

run = 1
wSize = 5

# puts "Enter the network IP:"
# networkIP = gets.chomp
networkIP = "192.168.0.8"
client = UDPSocket.new
client.bind('', $port)
client.connect(networkIP, $port)

puts "Enter program state. Can be 0 or 1 (send or receive)"
state = gets.chomp

if(state.to_i == 0)
    puts "Input an IP"
    #ip = gets.chomp
    ip = "192.168.0.5"

    while(run == 1)
        msg = ["Hello", "How", "Are", "You", "Bob", "I", "Am", "Fine", "Thanks"]
        packetAmt = msg.size
        # msg = gets.chomp.split(/\W+/)
        totalACKs = 0
        while(totalACKs < packetAmt)
            windowACKs = 0
            window = fillWindow(ip, totalACKs, msg, wSize)
            sendWindow(networkIP, window, client)
            while(windowACKs < wSize)
                begin
                    Timeout.timeout(1) do
                    ack = getPacket(client)
                    if ack.seqNum == totalACKs
                        puts "Received ACK (type = #{ack.type}) response from #{ack.src_ip}"
                        totalACKs += 1
                        windowACKs += 1
                    end
                end
                rescue Timeout::Error
                    puts "ACK for packet #{totalACKs} may have been dropped. Resend window"
                    break
                end
            end
			if packetAmt - totalACKs < wSize
				wSize = packetAmt - totalACKs
			end
        end
        if(totalACKs == packetAmt)
            sendPacket(client, $port, makePacket(ip, $local_ip, 2, 0, 0, ""), networkIP)
            puts "EOT packet sent"
        else
            puts "Something wrong in windowACKS == wSize"
        end
    end
else
    while(run == 1)
        expected_SeqNum = 0
        packet = getPacket(client)
        if(packet.seqNum = expected_SeqNum)
            puts "Received packet #{packet.seqNum}: #{packet.data} from #{packet.src_ip}"
            ack = makePacket(packet.src_ip, $local_ip, 0, packet.seqNum, packet.seqNum + 1, "ACK")
            sendPacket(client, $port, ack, networkIP)
        elsif packet.type == 2
            puts "Received EOT from #{packet.src_ip}"
            ack = makePacket(packet.src_ip, $local_ip, 2, 1, 1, "Received EOT")
            sendPacket(client, $port, ack, networkIP)
        end
    end
end

puts "done"
