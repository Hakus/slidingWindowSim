require 'socket'
require 'bit-struct'
require 'timeout'
require 'logger'

# =============================================================================
# File: 		packet.rb - Packet structure and common methods
# 
# Functions:    makePacket() 	- Create and return a packet
# 				getPacket() 	- Receive a packet from the socket
# 				sendPacket() 	- Send a packet through the socket
# 				fillWindow() 	- Create an array of packets (aka "window")
# 				sendWindow()	- Send a window of packets
# 				getACKs()		- Receive acknowledgement packets for a window
# 				setupLog()		- Setup logging feature for each host
# 				
# Notes:        This contains structure of packets being sent, as well as
# 				common methods used by all the hosts dealing with packets. 
# 
# 				The exception is setupLog(), which is rather misplaced but due
# 				to the nature that every host file includes this file and uses
# 				setuplog(), we have decided to place it here for now.
# =============================================================================

# Packet Structure
# dest_ip	- destination IP, 32 bit octet
# src_ip	- source IP, 32 bit octet
# type		- Packet type, 2 bit int, can be one of [0, 1, 2] for [ACK, DATA, EOT]
# seqNum	- Sequence number, 16 bit int
# ackNum	- Acknowledgement number, 16 bit int. Currently not fully used
# data 		- Data. The size is the rest of the packet minus the above "headers"

class Packet < BitStruct
	octets		:dest_ip,	32
	octets		:src_ip,	32
	unsigned	:type,		2
	unsigned	:seqNum,	16
	unsigned	:ackNum,	16
	rest		:data
end

# =============================================================================
# Function:     makePacket
# 
# Interface:    makePacket(dest_ip, src_ip, type, seqNum, ackNum, data)
#               dest_ip: 	IP address of the receiver/destination
# 				src_ip: 	IP address of the sender/source
# 				type: 		Type of packet. value between 0 and 2 
# 							(0 = ACK, 1 = DATA, 2 = EOT)
#               seqNum: 	The sequence number of the packet
# 				ackNum: 	The acknowledgement number of the packet
# 				data: 		The string data that the packet contains
#
# Return:       A bit-struct that contains the header and data of a packet
# 
# Notes:        Makes a packet according to the Packet structure.
# 				At the time of writing, ackNum is not being used between hosts
# =============================================================================
def makePacket(dest_ip, src_ip, type, seqNum, ackNum, data)
	packet = Packet.new

	packet.dest_ip = dest_ip
	packet.src_ip = src_ip
	packet.type = type
	packet.seqNum = seqNum
	packet.ackNum = ackNum
	packet.data = data

	return packet
end

# =============================================================================
# Function:     getPacket
# 
# Interface:    getPacket(socket)
#               socket: 	The UDPSocket that is connected to a host
#
# Return:       The packet received from the socket
# 
# Notes:        Gets a packet object from the socket.
# 				Current the size variable is hardcoded, due to the program
# 				only sending small strings between hosts. In future versions
# 				where the program sends actual files, the size variable will
# 				indicate the buffer for receving data from the socket
# =============================================================================
def getPacket(socket)
	packet = Packet.new
	size = 128
	begin
		packet = Packet.new(socket.recvfrom_nonblock(size)[0])
	rescue Errno::EAGAIN
		IO.select([socket])
		retry
	end
	return packet
end

def sendPacket(socket, port, packet, *networkIP)
	if(networkIP.size == 0)
		socket.send(packet, 0, packet.dest_ip, port)
	else
		socket.send(packet, 0, networkIP[0], port)
	end
end

# =============================================================================
# Function:     fillWindow
# 
# Interface:    fillWindow(dest_ip, seqNum, data, wSize)
#               dest_ip: 	IP address of the receiver/destination
#               seqNum: 	The sequence number that the window will start
# 							populating at.
# 				data: 		Array of string for the data of the packets.
# 				wSize: 		Window size for the sliding window
#
# Return:       An array of packets with size of wSize, with sequence numbers
# 				starting from seqNum
# 
# Notes:        Creates an array (size wSize) of packets of struct Packet.
# 
# 				Instead of creating all the packets at once and storing it
# 				into an array, this implementation generates an array of wSize
# 				packets and sends only those. This is inefficent in situations
# 				with high drop rates due to having the same packet repeatly
# 				generated. Future version should consider modifying to improve
# 				efficency and generate each packet only once.
# =============================================================================
def fillWindow(dest_ip, seqNum, data, wSize)
	window = Array.new

	for i in 0..wSize-1
		packet = Packet.new

		packet.dest_ip = dest_ip
		packet.src_ip = $local_ip
		packet.type = 1
		packet.seqNum = seqNum + i
		packet.ackNum = seqNum + i + 1
		packet.data = data[seqNum + i]

		window.push(packet)
	end

	return window
end

# =============================================================================
# Function:     sendWindow
# 
# Interface:    sendWindow(networkIP, window, socket)
#               networkIP: 	IP address of the network host
# 				window: 	The window of packets to be sent
# 				socket: 	The network socket to be sent through
#
# Notes:        Sends all the packets in the window do the network host
# =============================================================================
def sendWindow(networkIP, window, socket)
	for i in 0..window.size-1
		sendPacket(socket, $port, window[i], networkIP)
	end
end

# =============================================================================
# Function:     getACKs
# 
# Interface:    getACKs(socket, wSize, totalACKs, log)
#               socket: 	The UDPsocket to receive packets from
#               wSize: 		Size of the sliding window
# 				totalACKs: 	Total amount of ACKs received so far
# 				log: 		Logger class used to log to file
#
# Return:       Updated totalACKs
# 
# Notes:        Gets ACK packets from an UDPSocket. The program will loop until
# 				either all the ACKs for a wSize of packets have been received,
# 				or the program experiences a timeout
# 
# 				Current the timeout time is hardcoded to 1.2. This is because
# 				we do not have a proper setup for adjusting network delay and
# 				host timeout. Future implementations should aim to correct this
# =============================================================================
def getACKs(socket, wSize, totalACKs, log)
	windowACKs = 0
	while(windowACKs < wSize)
	    begin
	        Timeout.timeout(1.2) do
	        ack = getPacket(socket)
	        if ack.seqNum == totalACKs
	            puts "Received ACK ##{ack.seqNum} from #{ack.src_ip}"
	            log.info("Received ACK ##{ack.seqNum} from #{ack.src_ip}")
	            totalACKs += 1
	            windowACKs += 1
	        else
	        	next
	        end
	    end
	    rescue Timeout::Error
	        puts "ACK for packet #{totalACKs} may have been dropped. Resend window"
	        log.info("ACK for packet #{totalACKs} may have been dropped. Resend window")
	        break
	    end
	end
	return totalACKs
end

# =============================================================================
# Function:     setupLog
# 
# Interface:    setupLog(fileName)
#               fileName: 	Filename of the log to store to
#
# Return:       A logger object
# 
# Notes:        Creates a Logger object by specifying a file. If the file does
# 				not exist it will be created. If the file exists it will be
# 				replaced. The logs are formatted by TIME::MSG
# =============================================================================
def setupLog(fileName)
	# Setting up logging feature
	logFile = File.open(fileName, 'w')
	log = Logger.new(logFile)
	log.formatter = proc do |severity, datetime, progname, msg|
	   Time.now.asctime + ":: #{msg}\n"
	end
	return log
end
