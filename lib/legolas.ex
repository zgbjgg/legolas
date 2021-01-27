defmodule Legolas do
  @moduledoc """
  Legolas is a process message interceptor for debugging purposes, under the hood
  it uses `dbg` to trace calls over a single process. All received messages to the process
  are intercepted and sent to the designed collectors processes.

  ## Adding targets

  In order to start, first add a target process (pid) to intercept messages.

      iex(1)> Legolas.add_target self()
      :ok

  The above code will intercept all messages sent to the `self` process.

  ## Adding collectors

  A collector is a process (pid) that will receive all messages intercepted in the target processes.

      iex(2)> Legolas.add_collector self()

  In the above code `self` will receive all messages sent to targets processes.

  ## Adding structs

  Structs is a main patter to intercept messages and filter with that pattern. Add multiple structs into Legolas:

      iex(3)> Legolas.add_struct Middle.Earth.Orc

  ## Legolas in action

  Now send a message to the target process and check how the collectors will receive the same message.

  @TODO: We need to support to handle multiple pattern matching for messages, for now Legolas supports to intercept
  messages with a defined struct (defstruct).

      iex(4)> send self(), %Middle.Earth.Orc{}
      %Middle.Earth.Orc{name: "Azog"}
      iex(5)> IEx.Helpers.flush()
      %Middle.Earth.Orc{name: "Azog"}
      {:message, %Middle.Earth.Orc{name: "Azog"}}
      :ok

  When intercept a new message, the collector process receive the message same as target process and emits a log.
  """
  use GenServer

  require Logger

  @doc false
  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Add a target process to catch messages sent and received to it.

  ## Example

      iex(1)> Legolas.add_target self()
      :ok
  """
  @spec add_target(pid(), Keyword.t()) :: :ok
  def add_target(pid_to, opts \\ [])
  def add_target(pid_to, opts) when is_pid(pid_to) do
    GenServer.call(__MODULE__, {:add_target, pid_to, opts})
  end
  def add_target(pid_to, _opts), do: raise ArgumentError, message: "[#{inspect __MODULE__}] the process `#{inspect pid_to}` is not a valid pid."

  @doc """
  Add a collector process to receive intercepted messages from targets.

  ## Example

      iex(1)> Legolas.add_collector self()
      :ok
  """
  @spec add_collector(pid()) :: :ok
  def add_collector(pid) when is_pid(pid) do
    GenServer.call(__MODULE__, {:add_collector, pid})
  end
  def add_collector(pid), do: raise ArgumentError, message: "[#{inspect __MODULE__}] the process `#{inspect pid}` is not a valid pid."

  @doc """
  Add a struct to handle into patterns, so only messages with that struct
  are added into buffer.

  ## Example

      iex(1)> Legolas.add_struct Middle.Earth.Orc
      :ok
  """
  @spec add_struct(atom()) :: :ok
  def add_struct(struct) do
    GenServer.call(__MODULE__, {:add_struct, struct})
  end

  @impl true
  def init([]) do
    # initializes dbg and other deps in order
    # to handle with dbg tracer
    case :dbg.tracer(:process, {&handle_trace/2, :none}) do
      {:error, :already_started} ->
        Logger.warn "[#{inspect __MODULE__}] already started dbg tracer"
      {:ok, dbg_pid} ->
        Logger.debug "[#{inspect __MODULE__}] started dbg at #{inspect dbg_pid}"
    end
    {:ok, []}
  end

  @impl true
  def handle_call({:add_target, pid_to, _opts}, _from, state) do
    {:ok, _} = :dbg.p(pid_to, :m)
    {:reply, :ok, state}
  end
  def handle_call({:add_collector, collector_pid}, _from, state) do
    new_state = case Keyword.get(state, :collectors, []) do
      [] -> Keyword.put(state, :collectors, [collector_pid])
      _ -> Keyword.update!(state, :collectors, &(&1 ++ [collector_pid]))
    end
    {:reply, :ok, new_state}
  end
  def handle_call({:add_struct, struct}, _from, state) do
    new_state = case Keyword.get(state, :structs, []) do
      [] -> Keyword.put(state, :structs, [struct])
      _ -> Keyword.update!(state, :structs, &(&1 ++ [struct]))
    end
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_cast({:handle_trace, _pid, :receive, message}, state) do
    :ok = case Enum.member?(state[:structs], message.__struct__) do
      true ->
        :ok = state
          |> Keyword.get(:collectors)
          |> Enum.each(&send(&1, {:message, message}))
      false -> :ok
    end
    {:noreply, state}
  end

  defp handle_trace({:trace, pid, :receive, %_{} = message}, _acc) do
    GenServer.cast(__MODULE__, {:handle_trace, pid, :receive, message})
    true
  end
  defp handle_trace(_ignored_messages, _acc), do: true
end
