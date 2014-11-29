require 'socket'
require 'bit-struct'

# Packet Structure
class Packet < BitStruct
	octets		:dest_ip,	32
	unsigned	:type,		2
	unsigned	:seqNum,	16
	unsigned	:winSize,	4
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

def makePacket(dest_ip, type, seqNum, winSize, ackNum, data)
	packet = Packet.new

	packet.dest_ip = dest_ip
	packet.type = type
	packet.seqNum = seqNum
	packet.winSize = winSize
	packet.ackNum = ackNum
	packet.data = data

	return packet
end

def getPacket(socket)
	packet = Packet.new
    #shouldn't this be + 6?
	size = 2048 + 5
	begin
		packet = Packet.new(socket.recvfrom_nonblock(size)[0])
	rescue Errno::EAGAIN
		IO.select([socket])
		retry
	end

	return packet
end

def sendPacket(socket, port, packet)
	socket.send(packet, 0, packet.dest_ip.to_s, port)
end

def sendPacket(socket, networkIP, port, packet)
    socket.send(packet, 0, networkIP, port)
end