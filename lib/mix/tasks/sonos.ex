defmodule Mix.Tasks.Sonos do
  @moduledoc false

  def ensure_discovery do
    Application.ensure_all_started(:req)

    case GenServer.whereis(SonosMcp.Discovery) do
      nil -> SonosMcp.Discovery.start_link([])
      pid -> {:ok, pid}
    end

    wait_for_speakers()
  end

  defp wait_for_speakers do
    # Discovery's initial scan takes ~5-10s for large networks (SSDP + HTTP per speaker).
    # The GenServer is blocked during the scan so we sleep first, then poll with a long timeout.
    Process.sleep(8_000)

    Enum.reduce_while(1..10, [], fn _, _acc ->
      case GenServer.call(SonosMcp.Discovery, :list, 30_000) do
        [] ->
          Process.sleep(2_000)
          {:cont, []}

        speakers ->
          {:halt, speakers}
      end
    end)
  end
end
