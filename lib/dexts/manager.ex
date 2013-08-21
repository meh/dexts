#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Dexts.Manager do
  @moduledoc """
  This module manages smart garbage collection for dets tables.
  """

  use Application.Behaviour
  use GenServer.Behaviour

  @doc """
  Start the manager, if it's already started it will just return the original
  process.
  """
  def start(_, _) do
    if pid = Process.whereis(__MODULE__) do
      { :ok, pid }
    else
      :gen_server.start_link({ :local, __MODULE__ }, __MODULE__, [], [])
    end
  end

  @doc """
  Stop the manager, killing the process, keep in mind this will terminate the
  managed tables too.
  """
  def stop(_) do
    Process.exit(Process.whereis(__MODULE__), "application stopped")
  end

  @doc """
  Handle the finalization.
  """
  def handle_info({ :destroy, table }, state) do
    :dets.close(table)

    { :noreply, List.delete(state, table) }
  end
end
