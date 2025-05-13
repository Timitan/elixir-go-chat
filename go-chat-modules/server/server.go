package server

import (
	"tim.com/message"
)

func broadcast(nick map[string]chan string, message string, name string) {
	for nick, channel := range nick {
		// Broadcast to all channels except the inputted name
		if name != nick {
			channel <- message
		}
	}
}

func ServerStart(nick map[string]chan string, in chan message.Message) {
	for {
		// Block until a message is received
		m := <-in

		if(len(m.Recipients) == 0) {
			// Delete nickname from map
			if(m.MsgType == "delete") {
				// Find nickname from channel
				nick_in := ""
				for k, v := range nick {
					if v == m.Sender {
						nick_in = k
						break
					}
				}

				delete(nick, nick_in)
				broadcast(nick, nick_in + " has left the chat!\n", nick_in)
			} else {
				// The message type is for setting a nickname

				// Check if nickname exists already
				if channel, ok := nick[m.Text]; ok {
					// Their old nickname is the same as their new one
					if channel == m.Sender {
						m.Sender <- "Your nickname is already " + m.Text + "\n"
					} else {
						m.Sender <- m.Text + " already exists. Please choose another\n"
					}
				} else {
					// Find nickname from channel
					nick_in := ""
					for k, v := range nick {
						if v == m.Sender {
							nick_in = k
							break
						}
					}
					
					if(nick_in != "") {
						// Found a channel from the map, change their nickname since it doesn't exist
						delete(nick, nick_in)
						nick[m.Text] = m.Sender
						broadcast(nick, nick_in + " changed their name to " + m.Text + "\n", m.Text)
						m.Sender <- "Name changed successfully\n"
					} else {
						// Nickname doesn't exist, add it to the map
						nick[m.Text] = m.Sender
						broadcast(nick, m.Text + " has joined the chat!\n", m.Text)
						m.Sender <- "Name registered successfully\n"
					}
				}
			}
		} else {
			// Find nickname from channel to send to other clients
			nick_in := ""
			for k, v := range nick {
				if v == m.Sender {
					nick_in = k
					break
				}
			}

			// User needs to register a name before sending anything
			if(nick_in == "") {
				m.Sender <- "You must register a nickname first\n"
				continue
			}

			// The message type is for sending a message
			if(m.Recipients[0] == ";") {
				broadcast(nick, nick_in + ": " + m.Text, nick_in)
			} else {
				// Send to all recipients listed
				for i := range m.Recipients {
					if channel, ok := nick[m.Recipients[i]]; ok {
						channel <- nick_in + ": " + m.Text
					}
				}
			}
		}
	}
}