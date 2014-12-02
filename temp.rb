load 'packet.rb'

#get a port isntead of defining it
$port = 7000
$local_ip = UDPSocket.open {|s| s.connect("64.233.187.99", 1); s.addr.last}

# Constants
wSize = 5

puts "Enter the network IP:"
networkIP = gets.chomp
client = UDPSocket.new
client.bind('', $port)
client.connect(networkIP, $port)

# Setting up logging feature
logFile = File.open('client.log', 'w')
log = Logger.new(logFile)
log.formatter = proc do |severity, datetime, progname, msg|
   Time.now.asctime + ":: #{msg}\n"
end

# Loop forever
while(1!=0)
    puts "Are you sending or receiving? (Input 0 for send, 1 for receive)"
    option = gets.chomp

    # If we're sending...
    if(option.to_i == 0)
        puts "Where do you want to send to?"
        ip = gets.chomp

        while(1!=0)
            msg = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"]
            packetAmt = msg.size
            totalACKs = 0
            while(totalACKs < packetAmt)
                window = fillWindow(ip, totalACKs, msg, wSize)
                puts "Sending packets #{totalACKs} to #{totalACKs + wSize - 1}"
                log.info("[SEND] Sending packets #{totalACKs} to #{totalACKs + wSize - 1}")
                sendWindow(networkIP, window, client)
                totalACKs = getACKs(client, wSize, totalACKs)
    			if packetAmt - totalACKs < wSize
    				wSize = packetAmt - totalACKs
    			end
            end
            if(totalACKs == packetAmt)
                sendPacket(client, $port, makePacket(ip, $local_ip, 2, 0, 0, ""), networkIP)
                puts "EOT packet sent"
                log.info("[SEND] EOT packet sent")
                break
            end
        end
    #If we're receiving...
    else
        puts "Waiting for data packets..."
        result = ""
        expected_seqnum = 0
        init_packet = 0
        while(1!=0)
            if(init_packet == 0) 
                packet = getPacket(client)
                init_packet = 1
            else
                begin
                    Timeout.timeout(10) do
                        packet = getPacket(client)
                    end
                rescue Timeout::Error
                    puts "Did not receive any packets in 10 seconds. Assuming disconnection or lost EOT"
                    log.info("[RECV] Did not receive any packets in 10 seconds. Assuming disconnection or lost EOT")
                    break
                end
            end

            if packet.type == 2
                puts "Received EOT from #{packet.src_ip}"
                log.info("[RECV] Received EOT from #{packet.src_ip}")
                break
            else
                puts "Received packet #{packet.seqNum}: #{packet.data} from #{packet.src_ip}"
                log.info("[RECV] Received packet #{packet.seqNum}: #{packet.data} from #{packet.src_ip}")
                ack = makePacket(packet.src_ip, $local_ip, 0, packet.seqNum, packet.seqNum + 1, "ACK")
                sendPacket(client, $port, ack, networkIP)
                if packet.seqNum == expected_seqnum
                    result << packet.data << " "
                    expected_seqnum += 1
                end
            end
        end
        puts "The received data is: #{result}"
    end
end