defmodule Chat.Server do
  use GenServer

  ## client API
  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  # Store proxy process ids into the state
  def store_pid(name, pid) do
    GenServer.cast(__MODULE__, {:store, name, pid})
  end

  # Send a message to processes with certain names
  def send_message(msg, names, sender) do
    GenServer.cast(__MODULE__, {:send, msg, names, sender})
  end

  # Remove proxy process id
  def remove_pid(pid) do
    GenServer.cast(__MODULE__, {:remove, pid})
  end

  # Broadcast to all clients except to the excluded name
  def broadcast(msg, excludedName \\ nil) do
    GenServer.cast(__MODULE__, {:broadcast, msg, excludedName})
  end

  def state() do
    GenServer.call(__MODULE__, :state)
  end

  ## helper functions
  # Retrieve pids to send messages to
  defp filter_map(state, excludedName) do
    filteredMap = case excludedName do
      nil -> state
      _ ->  Map.delete(state, excludedName)
    end
    filteredMap
  end

  ## implementation
  @impl true
  def init(_) do
    Chat.Proxy.start()
    {:ok, %{}}
  end

  # Info purposes for checking who is currently stored in state
  @impl true
  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast({:store, name, new_pid}, state) do
    case Map.fetch(state, name) do
      :error -> (
        # Code for replacing nickname

        # Find the name based on pid
        {original, _} = case length(Map.keys(state)) do
          0 -> {name, ""}
          _ -> Enum.find(state, {name, ""}, fn {_, pid} -> pid == new_pid end)
        end

        # Check if the operation is for replacing a nickname
        if original == name do
          send(new_pid, {:msg, "You successfully registered your name to " <> name <> "\n"})
          broadcast(name <> " has joined the chat!\n", name)
          {:noreply, Map.put(state, name, new_pid)}
        else
          broadcast(original <> " changed their nickname to " <> name <> "!\n", original)
          {:noreply, Map.delete(state, original) |> Map.put(name, new_pid)}
        end
      )
      {:ok, pid} -> (
        # Code for checking if the nickname is overriding another client's nickname
        if new_pid == pid do
          # Their old nickname is the same as their new one
          send(new_pid, {:msg, "Your nickname is already " <> name <> "\n"})
          {:noreply, state}
        else
          # Their name is already taken
          send(new_pid, {:msg, name <> " already exists. Please choose another name\n"})
          {:noreply, state}
        end
      )
    end
  end

  # Broadcast to all clients with the exception of the passed in excluded nickname
  @impl true
  def handle_cast({:broadcast, msg, excludedNames}, state) do
    Enum.each(Map.values(filter_map(state, excludedNames)), fn pid -> send(pid, {:msg, msg}) end)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:send, msg, names, sender}, state) do
    # Find the nickname associated with the client
    {sender_nick, _} = Enum.find(state, {nil, nil}, fn {_, pid} -> pid == sender end)

    if sender_nick == nil do
      send(sender, {:msg, "Register a nickname before sending any message\n"})
      {:noreply, state}
    else
      # Check if the names are binary
      if names == ";" do
        # Broadcast to all clients
        broadcast(Enum.join(["*", sender_nick, "*: ", msg], ""), sender_nick)
        {:noreply, state}
      else
        # Get the list of pids to send a message to
        pids = Enum.reduce(names, [], fn x, acc -> (
          case Map.fetch(state, x) do
            :error -> acc
            {:ok, pid} -> [pid | acc]
          end
        ) end)

        Enum.each(pids, fn receiver -> send(receiver, {:msg, Enum.join(["*", sender_nick, "*: ", msg], "")}) end)
        {:noreply, state}
      end
    end
  end

  @impl true
  def handle_cast({:remove, old_pid}, state) do
    # Find the name from the port to broadcast a message to connected clients
    {name, pid} = Enum.find(state, {"", nil}, fn {_, pid} -> pid == old_pid end)

    # Delete the port in the state if it exists
    newMap = case pid do
      nil -> state
      _ -> Map.delete(state, name)
    end

    # Debugging
    if name != "" do
      broadcast(name <> " has left the chat!\n", name)
    end

    {:noreply, newMap}
  end
end
