defmodule Chat.Proxy do
  def start(port \\ 6666) do
    opts = [:binary, {:active, true}, {:packet, 0}, {:reuseaddr, true}]
    {:ok, socket} = :gen_tcp.listen(port, opts)
    spawn(fn -> accept_client(socket) end)
  end

  def accept_client(socket) do
    {:ok, connected_socket} = :gen_tcp.accept(socket)
    spawn(fn -> accept_client(socket) end)
    loop(connected_socket)
  end

  def loop(socket) do
    receive do
      {:msg, bin} ->
        :gen_tcp.send(socket, bin)
        loop(socket)
      {:tcp, _socket, bin} ->
        [type | params] = String.split(bin, " ")
        type = String.trim(type)

        # Check if the message type is /msg or /nick
        case type do
          "/nick" -> (
            if(length(params) == 1) do
              [nick] = params
              nick = String.downcase(String.trim(nick))

              # Get the first letter of the string to ensure that it's a letter
              {head, tail} = String.split_at(nick, 1)

              # Conditions to satisfy with the nickname
              # Check first letter is alphabet only
              # Check if rest of letters are alphanumeric/ underscore
              # Check if the length of the nickname is below 9
              case {Regex.match?(~r/^[a-zA-Z0-9_]*$/, tail), Regex.match?(~r/^[a-z]*$/, head), String.length(nick) <= 9} do
                {true, true, true} -> (
                  # Store a nickname associated with the socket
                  Chat.Server.store_pid(nick, self())
                )
                # Errors in the name
                {false, _, _} -> (
                  :gen_tcp.send(socket, "Your name must be followed by alphanumeric letters or the underscore character after the first character.\n")
                )
                {_, false, _} -> (
                  :gen_tcp.send(socket, "Your name must begin with an alphabet character\n")
                )
                {_, _, false} -> (
                  :gen_tcp.send(socket, "Your name must only contain a maximum of 9 letters.\n")
                )
              end
            else
              :gen_tcp.send(socket, "Error in setting nickname\n")
            end
          )
          "/msg" -> (
            # Messages less than 2 words is not considered valid
            if(length(params) >= 2) do
              [nicknames | msg] = params

              # Maintain the white space from before the message was split
              formatted_msg = Enum.join(msg, " ")

              # Remove white space from nicknames
              nick_list = case nicknames do
                ";" -> nicknames
                _ -> String.split(nicknames, ",")
              end

              Chat.Server.send_message(formatted_msg, nick_list, self())
            else
              :gen_tcp.send(socket, "Message format is incorrect\n")
            end
          )
          _ -> :gen_tcp.send(socket, "Command not recognized\n")
        end

        loop(socket)
      {:tcp_closed, socket} ->

        # Remove pid number from the state if it is closed
        Chat.Server.remove_pid(self())

        :gen_tcp.close(socket)
    end
  end
end
