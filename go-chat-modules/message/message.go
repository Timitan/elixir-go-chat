package message

type Message struct {
	Recipients	[]string
	Text 		string
	Sender		chan string
	MsgType 	string
}

func NewMessage(recipients []string, text string, sender chan string, msgType string) *Message {
	m := new(Message)
	m.Recipients = recipients
	m.Text = text
	m.Sender = sender
	m.MsgType = msgType
	return m
}