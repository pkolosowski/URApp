require 'socket'
require_relative "robotscript"


HOST = "192.168.0.110"
PORT = 30001

socket = Socket.new Socket::AF_INET, Socket::SOCK_STREAM
socket.connect Socket.pack_sockaddr_in(PORT, HOST)
script = RobotScript.new('prog', socket)
script.execute(script, "", "")
