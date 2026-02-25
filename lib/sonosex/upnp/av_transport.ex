defmodule Sonosex.UPnP.AVTransport do
  alias Sonosex.SOAP

  def play(ip), do: SOAP.call(ip, :av_transport, "Play", InstanceID: 0, Speed: 1)

  def pause(ip), do: SOAP.call(ip, :av_transport, "Pause", InstanceID: 0)

  def stop(ip), do: SOAP.call(ip, :av_transport, "Stop", InstanceID: 0)

  def next(ip), do: SOAP.call(ip, :av_transport, "Next", InstanceID: 0)

  def previous(ip), do: SOAP.call(ip, :av_transport, "Previous", InstanceID: 0)

  def seek(ip, target) do
    SOAP.call(ip, :av_transport, "Seek", InstanceID: 0, Unit: "REL_TIME", Target: target)
  end

  def get_transport_info(ip) do
    SOAP.call(ip, :av_transport, "GetTransportInfo", InstanceID: 0)
  end

  def get_position_info(ip) do
    SOAP.call(ip, :av_transport, "GetPositionInfo", InstanceID: 0)
  end

  def get_media_info(ip) do
    SOAP.call(ip, :av_transport, "GetMediaInfo", InstanceID: 0)
  end

  def set_av_transport_uri(ip, uri, metadata \\ "") do
    SOAP.call(ip, :av_transport, "SetAVTransportURI",
      InstanceID: 0,
      CurrentURI: uri,
      CurrentURIMetaData: metadata
    )
  end

  def add_uri_to_queue(ip, uri, metadata \\ "") do
    SOAP.call(ip, :av_transport, "AddURIToQueue",
      InstanceID: 0,
      EnqueuedURI: uri,
      EnqueuedURIMetaData: metadata,
      DesiredFirstTrackNumberEnqueued: 0,
      EnqueueAsNext: 0
    )
  end

  def remove_all_tracks_from_queue(ip) do
    SOAP.call(ip, :av_transport, "RemoveAllTracksFromQueue", InstanceID: 0)
  end

  def set_play_mode(ip, mode)
      when mode in ~w(NORMAL REPEAT_ALL REPEAT_ONE SHUFFLE_NOREPEAT SHUFFLE SHUFFLE_REPEAT_ONE) do
    SOAP.call(ip, :av_transport, "SetPlayMode", InstanceID: 0, NewPlayMode: mode)
  end

  def set_crossfade_mode(ip, enabled) do
    SOAP.call(ip, :av_transport, "SetCrossfadeMode",
      InstanceID: 0,
      CrossfadeMode: if(enabled, do: 1, else: 0)
    )
  end

  def configure_sleep_timer(ip, duration) do
    SOAP.call(ip, :av_transport, "ConfigureSleepTimer",
      InstanceID: 0,
      NewSleepTimerDuration: duration
    )
  end

  def become_standalone(ip) do
    SOAP.call(ip, :av_transport, "BecomeCoordinatorOfStandaloneGroup", InstanceID: 0, CurrentSpeed: 1)
  end
end
