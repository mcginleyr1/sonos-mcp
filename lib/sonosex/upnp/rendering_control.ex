defmodule Sonosex.UPnP.RenderingControl do
  alias Sonosex.SOAP

  def get_volume(ip) do
    with {:ok, resp} <-
           SOAP.call(ip, :rendering_control, "GetVolume", InstanceID: 0, Channel: "Master") do
      {:ok, String.to_integer(resp["CurrentVolume"])}
    end
  end

  def set_volume(ip, volume) do
    SOAP.call(ip, :rendering_control, "SetVolume",
      InstanceID: 0,
      Channel: "Master",
      DesiredVolume: volume
    )
  end

  def get_mute(ip) do
    with {:ok, resp} <-
           SOAP.call(ip, :rendering_control, "GetMute", InstanceID: 0, Channel: "Master") do
      {:ok, resp["CurrentMute"] == "1"}
    end
  end

  def set_mute(ip, muted) do
    SOAP.call(ip, :rendering_control, "SetMute",
      InstanceID: 0,
      Channel: "Master",
      DesiredMute: if(muted, do: 1, else: 0)
    )
  end

  def get_bass(ip) do
    SOAP.call(ip, :rendering_control, "GetBass", InstanceID: 0, Channel: "Master")
  end

  def set_bass(ip, level) do
    SOAP.call(ip, :rendering_control, "SetBass", InstanceID: 0, DesiredBass: level)
  end

  def get_treble(ip) do
    SOAP.call(ip, :rendering_control, "GetTreble", InstanceID: 0, Channel: "Master")
  end

  def set_treble(ip, level) do
    SOAP.call(ip, :rendering_control, "SetTreble", InstanceID: 0, DesiredTreble: level)
  end
end
