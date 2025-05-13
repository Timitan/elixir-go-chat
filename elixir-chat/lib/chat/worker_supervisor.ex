defmodule Chat.WorkerSupervisor do
  use DynamicSupervisor

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, nil, name: __MODULE__)
    DynamicSupervisor.start_child(__MODULE__, {Chat.Server, :ok})
  end

  @impl true
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_chat() do
    # arguments are supervisor and child specification
    DynamicSupervisor.start_child(__MODULE__, {Chat.Server, :ok})
  end
end
