load 'packet.rb'

# =============================================================================
# File:         client.rb   - A host client that can send and receive packets
# 
# Functions:    sendData()  - Sequence to send packets of data to a destination
#               recvData()  - Sequence to receive packets of data from a socket
#               
# Notes:        A UDP client that communicates between another client using a 
#               send-and-wait sliding window protocol. The client is can be
#               either sending of receiving data depending on user input.
# =============================================================================

# Setup global variables
$port = 7000
$local_ip = UDPSocket.open {|s| s.connect("64.233.187.99", 1); s.addr.last}
$log = setupLog('client.log')

# =============================================================================
# Function:     sendData
# 
# Interface:    sendData(socket, wSize, networkIP)
#               socket:     UDP network socket used to send data
#               wSize:      Window Size for sliding window
#               networkIP:  IP of the network between the two clients
# 
# Notes:        Currently, the amount of packets is specified by the user
#               Each data packet's data portion contains an incremental number
#
#               The loop condition is while we haven't received an ACK for
#               each packet. The end condition is when all the ACKs for each 
#               packet is received, then the client sends an EOT and breaks 
#               the loop
# =============================================================================
def sendData(socket, wSize, networkIP)
    puts "Where do you want to send to?"
    ip = gets.chomp
    puts "How many packets will you send?"
    packetAmt = gets.chomp.to_i
    # Loop forever
    while(1!=0)
        msg = [*0.to_s..(packetAmt-1).to_s]
        totalACKs = 0 # total amount of ACKs received
        # While we haven't received an ACK for each packet
        while(totalACKs < packetAmt)
            # If the amount of packets left is less than wSize, adjust accordingly
            if packetAmt - totalACKs < wSize
                wSize = packetAmt - totalACKs
            end
            # Create a window of wSize
            window = fillWindow(ip, totalACKs, msg, wSize)
            puts "Sending packets #{totalACKs} to #{totalACKs + wSize - 1}"
            $log.info("[SEND] Sending packets #{totalACKs} to #{totalACKs + wSize - 1}")
            # Send the window
            sendWindow(networkIP, window, socket)
            # Wait to get ACKs for each packet in window
            totalACKs = getACKs(socket, wSize, totalACKs, $log)
        end
        # if we got ACKs for every packet, send EOT
        if(totalACKs == packetAmt)
            sendPacket(socket, $port, makePacket(ip, $local_ip, 2, 0, 0, ""), networkIP)
            puts "EOT packet sent"
            $log.info("[SEND] EOT packet sent")
            break
        end
    end
end

# =============================================================================
# Function:     recvData
# 
# Interface:    recvData(socket, networkIP)
#               socket:     UDP network socket used to receive data
#               networkIP:  IP of the network between the two clients
#
# Return:       A string of words sent from the transmitter with a space in
#               between each piece of data 
# 
# Notes:        The receiver will stop the connection if no packets arrive
#               within 10 seconds. The exception is when it waits for the first
#               packet, where it waits indefinitely.
#
#               The receiver sends an ACK for each packet received. But it will
#               only append the data if the packet is expected packet
# =============================================================================
def recvData(socket, networkIP)
    puts "Waiting for data packets..."
    result = ""
    expected_seqNum = 0
    init_packet = 0
    # Loop forever
    while(1!=0)
        # If we haven't received any packets yet
        if(init_packet == 0) 
            packet = getPacket(socket)
            init_packet = 1
        else
            # If we've already received a packet, set a timeout for more packets
            begin
                Timeout.timeout(10) do
                    packet = getPacket(socket)
                end
            rescue Timeout::Error
                puts "Did not receive any packets in 10 seconds. Assuming disconnection or lost EOT"
                $log.info("[RECV] Did not receive any packets in 10 seconds. Assuming disconnection or lost EOT")
                break
            end
        end
        # Handle the packet based on type
        if packet.type == 2 # if it's EOT packet
            puts "Received EOT from #{packet.src_ip}"
            $log.info("[RECV] Received EOT from #{packet.src_ip}")
            break # stop sending
        else # if it's not EOT
            puts "Received packet #{packet.seqNum}: #{packet.data} from #{packet.src_ip}"
            $log.info("[RECV] Received packet #{packet.seqNum}: #{packet.data} from #{packet.src_ip}")
            # make an ACK packet
            ack = makePacket(packet.src_ip, $local_ip, 0, packet.seqNum, packet.seqNum + 1, "ACK")
            # send it
            sendPacket(socket, $port, ack, networkIP)
            # if we get the packet we wanted, update the data received
            if packet.seqNum == expected_seqNum
                result << packet.data << " "
                expected_seqNum += 1
            end
        end
    end
    # return the data we got
    return result
end


# Main logic
puts "Enter the network IP:"
networkIP = gets.chomp
# Create socket and bind to any incoming IP
# Connect the same socket to the network
client = UDPSocket.new
client.bind('', $port)
client.connect(networkIP, $port)

# Loop forever
while(1!=0)
    puts "Are you sending or receiving? (Input 0 for send, 1 for receive)"
    option = gets.chomp

    # If we're sending...
    if(option.to_i == 0)
        # Get the window size
        puts "Input the window size"
        wSize = gets.chomp.to_i
        # Make and send data
        sendData(client, wSize, networkIP)
    #If we're receiving...
    else
        # Get ready to receive data
        result = recvData(client, networkIP)
        puts result
    end
end