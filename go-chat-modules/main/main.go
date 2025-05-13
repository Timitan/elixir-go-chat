package main

import (
	"tim.com/server"
	"tim.com/chat"
	"tim.com/message"
)

func StartChat() {
	// For the server to receive messages
	serverIn := make(chan message.Message)

	// The map for storing nicknames and channels
	nickMap := make(map[string]chan string)

	go server.ServerStart(nickMap, serverIn)
	chat.Listen(serverIn)
}

func main() {
	StartChat()
}
