# elixir-go-chat
A chat application created using Elixir and another created in Go. Created in 2022 for a BCIT programming paradigms course.

## Structure

```
elixir-go-chat/
├── elixir-chat/                # Folder containing the files needed to run the Elixir chat server
├── go-chat-modules/            # Folder containing the files needed to run the Go chat server
└── ChatClient.java           	# Java chat client file to connect to the Chat servers
```

## Requirements

```
>= Elixir 1.18.3
>= Go 1.24.1
>= Java 21
```
Note that this application was tested with the following versions, older versions may be sufficient.

## Usage

### Elixir chat

1. Open a console and navigate to ``/elixir-chat/``
2. Run and compile the chat server using ``iex -S mix``
3. Open another console and run the Java client ``/ChatClient.java``
4. Repeat Step 3 for as many clients as needed
5. Begin typing in the Java client consoles using the supported commands

### Go chat

1. Open a console and navigate to ``/go-chat-modules/main/``
2. Build the executable server file using ``go build main.go`` and run the provided ``main.exe`` file or run the Go file with ``go run main.go`` 
3. Open another console and run the Java client ``/ChatClient.java``
4. Repeat Step 3 for as many clients as needed
5. Begin typing in the Java client consoles using the supported commands

### Using the chat

There are two supported commands:
1. ``/nick <nickname>``
2. ``/msg <user/user1,user2/;> <message>``

The command ``/nick`` allows you to give yourself a nickname so that other connected clients will see your messages. The command ``/msg`` allows you to send a message to one or more users with the given message. The ``;`` input for the message command broadcasts a message to all users.

To close a server or client, enter the end-of-file key (CTRL+Z / CTRL+D).

## Implementation Details

