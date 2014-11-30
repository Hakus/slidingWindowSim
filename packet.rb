require 'socket'
require 'bit-struct'
require 'timeout'

# global variables
$window = Array.new

# Packet Structure
class Packet < BitStruct
	octets		:dest_ip,	32
	octets		:src_ip,	32
	unsigned	:type,		2
	unsigned	:seqNum,	16
	unsigned	:ackNum,	16
	rest		:data
end

# ==============================================================
# makePacket - Creates a Packet structure and fill it with data
# Takes in the following values:
# type - int value between 0 and 2 (0 = ack, 1 = data, 2 = EOT)
# seqNum - Sequence Number
# winSize - Window Size
# ackNum - Acknowledgement Number
# data - Body content of the packet
#
# returns a Packet struct
# ==============================================================

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

# Data is an array of data size = window size 
def fillWindow(dest_ip, seqNum, data)
	wSize = data.length
	window = Array.new
	for i in seqNum..seqNum+wSize-1
		packet = Packet.new
		packet.dest_ip = dest_ip
		packet.src_ip = $local_ip
		packet.type = 1
		packet.seqNum = seqNum + i
		packet.data = data[i]
		window.push(packet)
	end

	return window
end

def getPacket(socket)
	packet = Packet.new
    #shouldn't this be + 6?
	size = 2048 + 6
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

def sendWindow(networkIP, window, socket)
	for i in 0..window.size-1
		puts window[i].inspect
		sendPacket(socket, $port, window[i], networkIP)
	end
end

