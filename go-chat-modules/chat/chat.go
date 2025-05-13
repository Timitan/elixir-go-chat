package chat

import (
	"bytes"
	"fmt"
	"net"
	"os"
	"strings"
	"regexp"
	"tim.com/message"
)

func handleClientRequests(conn net.Conn, serverIn chan message.Message, out chan string) {
	// Make a buffer to hold incoming data.
	defer conn.Close()
	for {
		// Read the incoming connection into the buffer.
		buf := make([]byte, 1024)

		_, err := conn.Read(buf)
		if err != nil {
			// Send a message to remove a nickname
			msg := message.NewMessage(nil, "delete", out, "delete")
			serverIn <- *msg

			close(out)

			//fmt.Println("Error reading:", err.Error())
			break
		}
		// Send a response back to person contacting us.
		text := string(bytes.Trim(buf, "\x00"))

		textSplit := strings.Split(text, " ");
		if(len(textSplit) <= 0) {
			continue
		}
		msgType := strings.Trim(textSplit[0], " ")

		if msgType == "/nick" {
			if len(textSplit) == 2 {
				nick := strings.ToLower(strings.Trim(strings.Trim(textSplit[1], "\r\n"), " "))
				tail := strings.Trim(nick[1:], "\r\n")

				// Check size of nickname
				if len([]rune(nick)) > 9 {
					conn.Write([]byte("Your name must be a maximum of 9 letters\n"))
					continue
				}

				// Check that all letters other than the head are alphanumeric
				r1 := regexp.MustCompile("^[a-zA-Z0-9_]*$")
				alphanumeric := r1.MatchString(tail)
				if(!alphanumeric) {
					conn.Write([]byte("Your name must be followed by alphanumeric letters or the underscore character after the first character\n"))
					continue
				}
				
				// Check that the first letter is alphabetical
				r2 := regexp.MustCompile("^[a-z]*$")
				letter := r2.MatchString(nick[:1])
				if(!letter) {
					conn.Write([]byte("Your name must begin with an alphabet character\n"))
					continue
				}

				// Send a message to the server to store a nickname
				msg := message.NewMessage(nil, strings.Trim(nick, "\r\n"), out, "nick")
				serverIn <- *msg
			} else {
				conn.Write([]byte("Invalid nickname command: " + text))
			}
		} else if msgType == "/msg" {
			if len(textSplit) >= 3 {
				// Get nicknames and the text to send
				nicks := strings.Split(strings.ToLower(textSplit[1]), ",")
				text := strings.Join(textSplit[2:], " ")

				msg := message.NewMessage(nicks, text, out, "message")

				serverIn <- *msg
			} else {
				conn.Write([]byte("Invalid message command: " + text))
			}
		} else {
			conn.Write([]byte("Invalid Command: " + text))
		}
	}
}

func handleServerMessages(conn net.Conn, out chan string) {
	for {
		m := <-out
		conn.Write([]byte(m))
	}
}

func Listen(serverIn chan message.Message) {
	// Listen for incoming connections.
	l, err := net.Listen("tcp", "localhost:6666")
	if err != nil {
		fmt.Println("Error listening:", err.Error())
		os.Exit(1)
	}
	// Close the listener when the application closes.
	defer l.Close()
	fmt.Println("Listening on localhost:6666")
	for {
		// Listen for an incoming connection.
		conn, err := l.Accept()
		if err != nil {
			fmt.Println("Error accepting: ", err.Error())
			os.Exit(1)
		}
		// String channel for the server to communicate with the goroutine to send to the client
		out := make(chan string)

		// For sending messages from the client to the server, includes storing nicknames and sending messages
		go handleClientRequests(conn, serverIn, out)

		// For sending messages to the client from the server
		go handleServerMessages(conn, out)
	}
}
