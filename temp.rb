load 'packet.rb'

#get a port isntead of defining it
$port = 7000
$local_ip = UDPSocket.open {|s| s.connect("64.233.187.99", 1); s.addr.last}

run = 1
wSize = 5

puts "Enter the network IP:"
networkIP = gets.chomp
client = UDPSocket.new
client.bind('', $port)
client.connect(networkIP, $port)

puts "Are you sending or receiving? (Input 0 for send, 1 for receive)"
option = gets.chomp

if(option.to_i == 0)
    puts "Where do you want to send?"
    ip = gets.chomp

    while(run == 1)
        msg = ["Hello", "How", "Are", "You", "Bob", "I", "Am", "Fine", "Thanks"]
        packetAmt = msg.size
        # msg = gets.chomp.split(/\W+/)
        totalACKs = 0
        while(totalACKs < packetAmt)
            windowACKs = 0
            puts "wACKs: #{windowACKs}, totalACKs: #{totalACKs}"
            window = fillWindow(ip, totalACKs, msg, wSize)
            sendWindow(networkIP, window, client)
            while(windowACKs < wSize)
                begin
                    Timeout.timeout(1) do
                    ack = getPacket(client)
                    puts "Received #{ack.seqNum}, expected #{totalACKs}"
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
            run = 0
        else
            puts "Something wrong in windowACKS == wSize"
        end
    end
else
    result = ""
    expected_seqnum = 0
    init_packet = 0
    while(run == 1)
        if(init_packet == 0) 
            packet = getPacket(client)
        else
            begin
                Timeout.timeout(10) do
                    ack_getPacket(client)
                end
            rescue Timeout::Error
                run = 0
                puts "Did not receive any packets in 10 seconds. Assuming disconnection or lost EOT"
            end
        end
        if packet.type == 2
            puts "Received EOT from #{packet.src_ip}"
            ack = makePacket(packet.src_ip, $local_ip, 2, 1, 1, "Received EOT")
            sendPacket(client, $port, ack, networkIP)
            run = 0
        else
            puts "Received packet #{packet.seqNum}: #{packet.data} from #{packet.src_ip}"
            ack = makePacket(packet.src_ip, $local_ip, 0, packet.seqNum, packet.seqNum + 1, "ACK")
            sendPacket(client, $port, ack, networkIP)
            if packet.seqNum == expected_seqnum
                result << " "
                result << packet.data
                expected_seqnum += 1
            end
        end
    end
    puts result
end