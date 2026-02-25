# Sonos UPnP Protocol Reference

Local communication reference for Sonos speakers. Source: https://sonos.svrooij.io

## Communication Methods

| Method | Port | Purpose |
|--------|------|---------|
| SOAP | 1400 | Service calls + event subscriptions |
| HTTP | 1400 | Device status, diagnostics, service descriptions |
| UDP/SSDP | 1900 | Speaker discovery via multicast |
| HTTPS | 1443 | Secure REST (not documented here) |

## SSDP Discovery

```
M-SEARCH * HTTP/1.1
HOST: 239.255.255.250:1900
MAN: ssdp:discover
MX: 1
ST: urn:schemas-upnp-org:device:ZonePlayer:1
```

Multicast to `239.255.255.250` and `255.255.255.255`. All speakers on the network respond.

## SOAP Protocol

### Request Format

```
POST {control_url}
Host: {ip}:1400
soapaction: "urn:schemas-upnp-org:service:{ServiceType}#{ActionName}"
Content-Type: text/xml; charset="utf-8"
```

```xml
<?xml version="1.0" encoding="utf-8"?>
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"
  s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
  <s:Body>
    <u:{ActionName} xmlns:u="urn:schemas-upnp-org:service:{ServiceType}">
      <ParamName>value</ParamName>
    </u:{ActionName}>
  </s:Body>
</s:Envelope>
```

### Success Response (HTTP 200)

```xml
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"
  s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
  <s:Body>
    <u:{ActionName}Response xmlns:u="urn:schemas-upnp-org:service:{ServiceType}">
      <!-- response fields -->
    </u:{ActionName}Response>
  </s:Body>
</s:Envelope>
```

### Error Response (HTTP 500)

```xml
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"
  s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
  <s:Body>
    <s:Fault>
      <faultcode>s:Client</faultcode>
      <faultstring>UPnPError</faultstring>
      <detail>
        <UPnPError xmlns="urn:schemas-upnp-org:control-1-0">
          <errorCode>800</errorCode>
        </UPnPError>
      </detail>
    </s:Fault>
  </s:Body>
</s:Envelope>
```

**Note**: Sonos uses `1` for true and `0` for false. Some actions return encoded XML strings requiring decoding before parsing.

### Event Subscription

```
SUBSCRIBE {event_url}
Host: {ip}:1400
callback: <http://your-callback-url>
NT: upnp:event
Timeout: Second-3600
```

## HTTP Diagnostic Endpoints

All on port 1400 via HTTP GET.

| Endpoint | Returns | Purpose |
|----------|---------|---------|
| `/status/info` | JSON | Player ID, serial number, group ID, capabilities, versions |
| `/status` | HTML | Connection information, links to sub-pages |
| `/status/batterystatus` | JSON | Battery status (portable devices) |
| `/status/ifconfig` | Text | Network interface stats, packet drops |
| `/status/proc/ath_rincon/status` | Text | WiFi driver diagnostics, HT channel in MHz |
| `/support/review` | HTML | Network matrix — WiFi signal strength between all speakers |
| `/xml/device_description.xml` | XML | UPnP service descriptions |
| `/region.htm` | HTML | WiFi region selection |
| `/reboot` | — | Restart device |

### Network Matrix (`/support/review`)

Shows WiFi signal strength between each Sonos device. Color indicators: Red = weak, Orange = moderate, Green = strong. Measures SNR (Signal-to-Noise Ratio) in dB:
- 45 dB+ = Excellent
- 25 dB or below = Weak

**Warning**: Accessing this endpoint can cause voice-enabled speakers to cut out for 10-15 seconds during diagnostic data gathering.

---

## SOAP Services

### AVTransport

- **Control URL**: `/MediaRenderer/AVTransport/Control`
- **Service Type**: `urn:schemas-upnp-org:service:AVTransport:1`

#### Playback Control

| Action | Inputs | Outputs | Notes |
|--------|--------|---------|-------|
| Play | InstanceID, Speed | — | Speed typically 1 |
| Pause | InstanceID | — | |
| Stop | InstanceID | — | |
| Next | InstanceID | — | Check GetCurrentTransportActions first |
| Previous | InstanceID | — | Check GetCurrentTransportActions first |
| Seek | InstanceID, Unit (TRACK_NR/REL_TIME/TIME_DELTA), Target | — | Error 701 if unsupported |

#### Transport URI

| Action | Inputs | Outputs | Notes |
|--------|--------|---------|-------|
| SetAVTransportURI | InstanceID, CurrentURI, CurrentURIMetaData | — | URI `x-rincon:{UUID}` groups with that player |
| SetNextAVTransportURI | InstanceID, NextURI, NextURIMetaData | — | |

#### Information

| Action | Inputs | Outputs | Notes |
|--------|--------|---------|-------|
| GetTransportInfo | InstanceID | CurrentTransportState, CurrentTransportStatus, CurrentSpeed | States: STOPPED, PLAYING, PAUSED_PLAYBACK, TRANSITIONING. Non-coordinator always returns PLAYING |
| GetPositionInfo | InstanceID | Track, TrackDuration, TrackMetaData, TrackURI, RelTime, AbsTime, RelCount, AbsCount | |
| GetMediaInfo | InstanceID | NrTracks, MediaDuration, CurrentURI, CurrentURIMetaData, NextURI, NextURIMetaData, PlayMedium, RecordMedium, WriteStatus | PlayMedium: NONE or NETWORK |
| GetCurrentTransportActions | InstanceID | Actions | Comma-separated. Non-coordinator returns only Start, Stop |
| GetTransportSettings | InstanceID | PlayMode, RecQualityMode | |
| GetDeviceCapabilities | InstanceID | PlayMedia, RecMedia, RecQualityModes | |

#### Playback Settings

| Action | Inputs | Outputs | Notes |
|--------|--------|---------|-------|
| SetPlayMode | InstanceID, NewPlayMode | — | NORMAL, REPEAT_ALL, REPEAT_ONE, SHUFFLE_NOREPEAT, SHUFFLE, SHUFFLE_REPEAT_ONE. Error 712 if not coordinator |
| GetCrossfadeMode | InstanceID | CrossfadeMode | Non-coordinator may return incorrect value |
| SetCrossfadeMode | InstanceID, CrossfadeMode | — | Error 800 if not coordinator |

#### Queue Management

| Action | Inputs | Outputs | Notes |
|--------|--------|---------|-------|
| AddURIToQueue | InstanceID, EnqueuedURI, EnqueuedURIMetaData, DesiredFirstTrackNumberEnqueued, EnqueueAsNext | FirstTrackNumberEnqueued, NumTracksAdded, NewQueueLength | |
| AddMultipleURIsToQueue | InstanceID, UpdateID, NumberOfURIs, EnqueuedURIs, EnqueuedURIsMetaData, ContainerURI, ContainerMetaData, DesiredFirstTrackNumberEnqueued, EnqueueAsNext | FirstTrackNumberEnqueued, NumTracksAdded, NewQueueLength, NewUpdateID | |
| RemoveAllTracksFromQueue | InstanceID | — | Error 804 if empty, 800 if not coordinator |
| RemoveTrackFromQueue | InstanceID, ObjectID, UpdateID | — | |
| RemoveTrackRangeFromQueue | InstanceID, UpdateID, StartingIndex, NumberOfTracks | NewUpdateID | StartingIndex is 1-based |
| ReorderTracksInQueue | InstanceID, StartingIndex, NumberOfTracks, InsertBefore, UpdateID | — | |
| SaveQueue | InstanceID, Title, ObjectID | AssignedObjectID | Error 800 if not coordinator |
| BackupQueue | InstanceID | — | |

#### Sleep Timer

| Action | Inputs | Outputs | Notes |
|--------|--------|---------|-------|
| ConfigureSleepTimer | InstanceID, NewSleepTimerDuration | — | hh:mm:ss or empty to cancel. Error 800 if not coordinator |
| GetRemainingSleepTimerDuration | InstanceID | RemainingSleepTimerDuration, CurrentSleepTimerGeneration | |

#### Group Coordination

| Action | Inputs | Outputs | Notes |
|--------|--------|---------|-------|
| BecomeCoordinatorOfStandaloneGroup | InstanceID | DelegatedGroupCoordinatorID, NewGroupID | Leave group, become standalone |
| DelegateGroupCoordinationTo | InstanceID, NewCoordinator, RejoinGroup | — | Send to current coordinator only |
| BecomeGroupCoordinator | InstanceID, CurrentCoordinator, CurrentGroupID, OtherMembers, TransportSettings, CurrentURI, CurrentURIMetaData, SleepTimerState, AlarmState, StreamRestartState, CurrentQueueTrackList, CurrentVLIState | — | |
| BecomeGroupCoordinatorAndSource | InstanceID, CurrentCoordinator, CurrentGroupID, OtherMembers, CurrentURI, CurrentURIMetaData, SleepTimerState, AlarmState, StreamRestartState, CurrentAVTTrackList, CurrentQueueTrackList, CurrentSourceState, ResumePlayback | — | |
| ChangeCoordinator | InstanceID, CurrentCoordinator, NewCoordinator, NewTransportSettings, CurrentAVTransportURI, RestartSink | — | |

#### Alarm

| Action | Inputs | Outputs | Notes |
|--------|--------|---------|-------|
| RunAlarm | InstanceID, AlarmID, LoggedStartTime, Duration, ProgramURI, ProgramMetaData, PlayMode, Volume, IncludeLinkedZones | — | |
| SnoozeAlarm | InstanceID, Duration | — | hh:mm:ss format |
| GetRunningAlarmProperties | InstanceID | AlarmID, GroupID, LoggedStartTime | |

#### Event Variables

Transport state: TransportState, TransportStatus, TransportPlaySpeed, CurrentTransportActions
Track: CurrentTrack, CurrentTrackDuration, CurrentTrackMetaData, CurrentTrackURI, NextTrackURI, NextTrackMetaData, NumberOfTracks
Position: RelativeTimePosition, AbsoluteTimePosition
Queue: AVTransportURI, AVTransportURIMetaData, CurrentMediaDuration, QueueUpdateID
Settings: CurrentPlayMode, CurrentCrossfadeMode
**Errors: TransportErrorDescription, TransportErrorHttpCode, TransportErrorHttpHeaders, TransportErrorURI**
Timer: SleepTimerGeneration, SnoozeRunning, AlarmRunning, AlarmIDRunning

#### Custom Error Codes

| Code | Description |
|------|-------------|
| 701 | Transition not available / seek not supported |
| 702 | No content |
| 703 | Read error |
| 704 | Format not supported |
| 711 | Illegal seek target |
| 712 | Play mode not supported (not coordinator) |
| 737 | No DNS configured |
| 738 | Bad domain |
| 739 | Server error |
| 800 | Command not supported or not a coordinator |

---

### RenderingControl

- **Control URL**: `/MediaRenderer/RenderingControl/Control`
- **Service Type**: `urn:schemas-upnp-org:service:RenderingControl:1`

| Action | Inputs | Outputs | Notes |
|--------|--------|---------|-------|
| GetVolume | InstanceID, Channel (Master/LF/RF) | CurrentVolume (0-100) | |
| SetVolume | InstanceID, Channel, DesiredVolume | — | |
| GetVolumeDB | InstanceID, Channel | CurrentVolume (dB) | |
| SetVolumeDB | InstanceID, Channel, DesiredVolume | — | |
| GetVolumeDBRange | InstanceID, Channel | MinValue, MaxValue | |
| GetMute | InstanceID, Channel | CurrentMute | |
| SetMute | InstanceID, Channel, DesiredMute | — | |
| GetBass | InstanceID | CurrentBass (-10 to 10) | |
| SetBass | InstanceID, DesiredBass | — | |
| GetTreble | InstanceID | CurrentTreble (-10 to 10) | |
| SetTreble | InstanceID, DesiredTreble | — | |
| GetLoudness | InstanceID, Channel | CurrentLoudness | |
| SetLoudness | InstanceID, Channel, DesiredLoudness | — | |
| GetEQ | InstanceID, EQType | CurrentValue | EQType: DialogLevel, NightMode, SubGain, SurroundEnable, SurroundLevel, SurroundMode, HeightChannelLevel, SpeechEnhanceEnabled, MusicSurroundLevel |
| SetEQ | InstanceID, EQType, DesiredValue | — | |
| GetHeadphoneConnected | InstanceID | CurrentHeadphoneConnected | |
| GetRoomCalibrationStatus | InstanceID | RoomCalibrationEnabled, RoomCalibrationAvailable | |
| SetRoomCalibrationStatus | InstanceID, RoomCalibrationEnabled | — | |
| SetRoomCalibrationX | InstanceID, CalibrationID, Coefficients, CalibrationMode | — | |
| RampToVolume | InstanceID, Channel, RampType, DesiredVolume, ResetVolumeAfter, ProgramURI | RampTime | RampType: SLEEP_TIMER_RAMP_TYPE, ALARM_RAMP_TYPE, AUTOPLAY_RAMP_TYPE |
| RestoreVolumePriorToRamp | InstanceID, Channel | — | |
| ResetBasicEQ | InstanceID | Bass, Treble, Loudness, LeftVolume, RightVolume | |
| ResetExtEQ | InstanceID, EQType | — | |
| SetRelativeVolume | InstanceID, Channel, Adjustment | NewVolume | |
| GetOutputFixed | InstanceID | CurrentFixed | |
| SetOutputFixed | InstanceID, DesiredFixed | — | |
| SetChannelMap | InstanceID, ChannelMap | — | |

---

### GroupRenderingControl

- **Control URL**: `/MediaRenderer/GroupRenderingControl/Control`
- **Service Type**: `urn:schemas-upnp-org:service:GroupRenderingControl:1`

All actions should be sent to coordinator only. Error 701 if not coordinator.

| Action | Inputs | Outputs |
|--------|--------|---------|
| GetGroupVolume | InstanceID | CurrentVolume |
| SetGroupVolume | InstanceID, DesiredVolume | — |
| SetRelativeGroupVolume | InstanceID, Adjustment | NewVolume |
| GetGroupMute | InstanceID | CurrentMute |
| SetGroupMute | InstanceID, DesiredMute | — |
| SnapshotGroupVolume | InstanceID | — |

---

### DeviceProperties

- **Control URL**: `/DeviceProperties/Control`
- **Service Type**: `urn:schemas-upnp-org:service:DeviceProperties:1`

| Action | Inputs | Outputs | Notes |
|--------|--------|---------|-------|
| GetZoneInfo | — | SerialNumber, SoftwareVersion, DisplaySoftwareVersion, HardwareVersion, IPAddress, MACAddress, CopyrightInfo, ExtraInfo, HTAudioIn, Flags | HTAudioIn: 0=not connected, 2=stereo, 7=Dolby 2.0, 18=Dolby 5.1, 21=not listening, 22=silence |
| GetZoneAttributes | — | CurrentZoneName, CurrentIcon, CurrentConfiguration, CurrentTargetRoomName | |
| GetHouseholdID | — | CurrentHouseholdID | |
| GetLEDState | — | CurrentLEDState (On/Off) | |
| SetLEDState | DesiredLEDState | — | |
| GetButtonState | — | State | |
| GetButtonLockState | — | CurrentButtonLockState (On/Off) | |
| SetButtonLockState | DesiredButtonLockState | — | |
| SetZoneAttributes | DesiredZoneName, DesiredIcon, DesiredConfiguration, DesiredTargetRoomName | — | |
| CreateStereoPair | ChannelMapSet | — | Right speaker becomes hidden |
| SeparateStereoPair | ChannelMapSet | — | |
| AddHTSatellite | HTSatChanMapSet | — | Format: `RINCON_xxx:LF,RF;RINCON_yyy:SW` |
| RemoveHTSatellite | SatRoomUUID | — | |
| AddBondedZones | ChannelMapSet | — | |
| RemoveBondedZones | ChannelMapSet, KeepGrouped | — | |
| EnterConfigMode | Mode, Options | State | |
| ExitConfigMode | Options | — | |
| RoomDetectionStartChirping | Channel, DurationMilliseconds, ChirpIfPlayingSwappableAudio | PlayId | |
| RoomDetectionStopChirping | PlayId | — | |
| GetAutoplayVolume | Source | CurrentVolume | |
| SetAutoplayVolume | Volume, Source | — | |
| GetAutoplayLinkedZones | Source | IncludeLinkedZones | |
| SetAutoplayLinkedZones | IncludeLinkedZones, Source | — | |
| GetAutoplayRoomUUID | Source | RoomUUID | |
| SetAutoplayRoomUUID | RoomUUID, Source | — | |
| GetUseAutoplayVolume | Source | UseVolume | |
| SetUseAutoplayVolume | UseVolume, Source | — | |

---

### ZoneGroupTopology

- **Control URL**: `/ZoneGroupTopology/Control`
- **Service Type**: `urn:schemas-upnp-org:service:ZoneGroupTopology:1`

| Action | Inputs | Outputs | Notes |
|--------|--------|---------|-------|
| GetZoneGroupState | — | ZoneGroupState (XML) | All groups, members, coordinators |
| GetZoneGroupAttributes | — | CurrentZoneGroupName, CurrentZoneGroupID, CurrentZonePlayerUUIDsInGroup, CurrentMuseHouseholdId | |
| BeginSoftwareUpdate | UpdateURL, Flags, ExtraOptions | — | |
| CheckForUpdate | UpdateType (All/Software), CachedOnly, Version | UpdateItem | |
| RegisterMobileDevice | MobileDeviceName, MobileDeviceUDN, MobileIPAndPort | — | |
| ReportAlarmStartedRunning | — | — | |
| ReportUnresponsiveDevice | DeviceUUID, DesiredAction | — | DesiredAction: Remove, TopologyMonitorProbe, VerifyThenRemoveSystemwide |
| SubmitDiagnostics | IncludeControllers, Type | DiagnosticID | Submits to Sonos servers |

Event Variables: ZoneGroupState, ZoneGroupName, ZoneGroupID, ZonePlayerUUIDsInGroup, MuseHouseholdId, AlarmRunSequence, AvailableSoftwareUpdate, NetsettingsUpdateID, AreasUpdateID, SourceAreasUpdateID, ThirdPartyMediaServersX

---

### ContentDirectory

- **Control URL**: `/MediaServer/ContentDirectory/Control`
- **Service Type**: `urn:schemas-upnp-org:service:ContentDirectory:1`

| Action | Inputs | Outputs | Notes |
|--------|--------|---------|-------|
| Browse | ObjectID, BrowseFlag, Filter, StartingIndex, RequestedCount, SortCriteria | Result (DIDL-Lite XML), NumberReturned, TotalMatches, UpdateID | ObjectID prefixes: A:ARTIST, A:ALBUM, FV:2 (favorites), Q: (queue), R:0/0 (radio), S: (shares), SQ: (saved queues). Max 1000 items |
| CreateObject | ContainerID, Elements | ObjectID, Result | |
| DestroyObject | ObjectID | — | |
| FindPrefix | ObjectID, Prefix | StartingIndex, UpdateID | |
| GetAlbumArtistDisplayOption | — | AlbumArtistDisplayOption (WMP/ITUNES/NONE) | |
| GetAllPrefixLocations | ObjectID | TotalPrefixes, PrefixAndIndexCSV, UpdateID | |
| GetBrowseable | — | IsBrowseable | |
| GetLastIndexChange | — | LastIndexChange | |
| GetSearchCapabilities | — | SearchCaps | |
| GetShareIndexInProgress | — | IsIndexing | |
| GetSortCapabilities | — | SortCaps | |
| GetSystemUpdateID | — | Id | |
| RefreshShareIndex | AlbumArtistDisplayOption | — | |
| SetBrowseable | Browseable | — | |
| UpdateObject | ObjectID, CurrentTagValue, NewTagValue | — | |

---

### ConnectionManager

- **Control URL**: `/MediaRenderer/ConnectionManager/Control`
- **Service Type**: `urn:schemas-upnp-org:service:ConnectionManager:1`

| Action | Inputs | Outputs | Notes |
|--------|--------|---------|-------|
| GetCurrentConnectionIDs | — | ConnectionIDs | |
| GetCurrentConnectionInfo | ConnectionID | RcsID, AVTransportID, ProtocolInfo, PeerConnectionManager, PeerConnectionID, Direction (Input/Output), Status | Status: OK, ContentFormatMismatch, InsufficientBandwidth, UnreliableChannel, Unknown |
| GetProtocolInfo | — | Source, Sink | |

---

### SystemProperties

- **Control URL**: `/SystemProperties/Control`
- **Service Type**: `urn:schemas-upnp-org:service:SystemProperties:1`

| Action | Inputs | Outputs | Notes |
|--------|--------|---------|-------|
| GetString | VariableName | StringValue | Error if variable doesn't exist. All speakers return identical data |
| SetString | VariableName, StringValue | — | Saved system-wide |
| Remove | VariableName | — | |
| GetRDM | — | RDMValue | |
| EnableRDM | RDMValue | — | |
| GetWebCode | AccountType | WebCode | |
| AddAccountX | AccountType, AccountID, AccountPassword | AccountUDN | |
| AddOAuthAccountX | AccountType, AccountToken, AccountKey, OAuthDeviceID, AuthorizationCode, RedirectURI, UserIdHashCode, AccountTier | AccountUDN, AccountNickname | |
| EditAccountMd | AccountType, AccountID, NewAccountMd | — | |
| EditAccountPasswordX | AccountType, AccountID, NewAccountPassword | — | |
| RemoveAccount | AccountType, AccountID | — | |
| ReplaceAccountX | AccountUDN, NewAccountID, NewAccountPassword, AccountToken, AccountKey, OAuthDeviceID | NewAccountUDN | |
| SetAccountNicknameX | AccountUDN, AccountNickname | — | |
| RefreshAccountCredentialsX | AccountType, AccountUID, AccountToken, AccountKey | — | |
| DoPostUpdateTasks | — | — | |

---

### AlarmClock

- **Control URL**: `/AlarmClock/Control`
- **Service Type**: `urn:schemas-upnp-org:service:AlarmClock:1`

| Action | Inputs | Outputs | Notes |
|--------|--------|---------|-------|
| CreateAlarm | StartLocalTime, Duration, Recurrence, Enabled, RoomUUID, ProgramURI, ProgramMetaData, PlayMode, Volume, IncludeLinkedZones | AssignedID | Recurrence: ONCE, WEEKDAYS, WEEKENDS, DAILY |
| UpdateAlarm | ID, StartLocalTime, Duration, Recurrence, Enabled, RoomUUID, ProgramURI, ProgramMetaData, PlayMode, Volume, IncludeLinkedZones | — | All params required |
| DestroyAlarm | ID | — | |
| ListAlarms | — | CurrentAlarmList (XML), CurrentAlarmListVersion | |
| GetTimeNow | — | CurrentUTCTime, CurrentLocalTime, CurrentTimeZone, CurrentTimeGeneration | |
| GetTimeServer | — | CurrentTimeServer | |
| SetTimeServer | DesiredTimeServer | — | |
| GetTimeZone | — | Index, AutoAdjustDst | |
| SetTimeZone | Index, AutoAdjustDst | — | |
| GetTimeZoneAndRule | — | Index, AutoAdjustDst, CurrentTimeZone | |
| GetTimeZoneRule | Index | TimeZone | |
| SetTimeNow | DesiredTime, TimeZoneForDesiredTime | — | |
| GetFormat | — | CurrentTimeFormat, CurrentDateFormat | |
| SetFormat | DesiredTimeFormat, DesiredDateFormat | — | |
| GetDailyIndexRefreshTime | — | CurrentDailyIndexRefreshTime | |
| SetDailyIndexRefreshTime | DesiredDailyIndexRefreshTime | — | |
| GetHouseholdTimeAtStamp | TimeStamp | HouseholdUTCTime | |

Error 801: Duplicate alarm time.

---

### GroupManagement

- **Control URL**: `/GroupManagement/Control`
- **Service Type**: `urn:schemas-upnp-org:service:GroupManagement:1`

| Action | Inputs | Outputs | Notes |
|--------|--------|---------|-------|
| AddMember | MemberID, BootSeq | CurrentTransportSettings, CurrentURI, GroupUUIDJoined, ResetVolumeAfter, VolumeAVTransportURI | |
| RemoveMember | MemberID | — | |
| ReportTrackBufferingResult | MemberID, ResultCode | — | |
| SetSourceAreaIds | DesiredSourceAreaIds | — | |

Event Variables: GroupCoordinatorIsLocal, LocalGroupUUID, ResetVolumeAfter, VirtualLineInGroupID, VolumeAVTransportURI

---

### AudioIn

- **Control URL**: `/AudioIn/Control`
- **Service Type**: `urn:schemas-upnp-org:service:AudioIn:1`
- **Available on**: Amp (S16), Era 100 (S39), Play:5 (S6) only

| Action | Inputs | Outputs |
|--------|--------|---------|
| GetAudioInputAttributes | — | CurrentName, CurrentIcon |
| GetLineInLevel | — | CurrentLeftLineInLevel, CurrentRightLineInLevel |
| SelectAudio | ObjectID | — |
| SetAudioInputAttributes | DesiredName, DesiredIcon | — |
| SetLineInLevel | DesiredLeftLineInLevel, DesiredRightLineInLevel | — |
| StartTransmissionToGroup | CoordinatorID | CurrentTransportSettings |
| StopTransmissionToGroup | CoordinatorID | — |

---

### Queue

- **Control URL**: `/MediaRenderer/Queue/Control`
- **Service Type**: `urn:schemas-sonos-com:service:Queue:1` (note: sonos-com, not upnp-org)

| Action | Inputs | Outputs |
|--------|--------|---------|
| AddURI | QueueID, UpdateID, EnqueuedURI, EnqueuedURIMetaData, DesiredFirstTrackNumberEnqueued, EnqueueAsNext | FirstTrackNumberEnqueued, NumTracksAdded, NewQueueLength, NewUpdateID |
| AddMultipleURIs | QueueID, UpdateID, ContainerURI, ContainerMetaData, DesiredFirstTrackNumberEnqueued, EnqueueAsNext, NumberOfURIs, EnqueuedURIsAndMetaData | FirstTrackNumberEnqueued, NumTracksAdded, NewQueueLength, NewUpdateID |
| AttachQueue | QueueOwnerID | QueueID, QueueOwnerContext |
| Backup | — | — |
| Browse | QueueID, StartingIndex, RequestedCount | Result, NumberReturned, TotalMatches, UpdateID |
| CreateQueue | QueueOwnerID, QueueOwnerContext, QueuePolicy | QueueID |
| RemoveAllTracks | QueueID, UpdateID | NewUpdateID |
| RemoveTrackRange | QueueID, UpdateID, StartingIndex, NumberOfTracks | NewUpdateID |
| ReorderTracks | QueueID, StartingIndex, NumberOfTracks, InsertBefore, UpdateID | NewUpdateID |
| ReplaceAllTracks | QueueID, UpdateID, ContainerURI, ContainerMetaData, CurrentTrackIndex, NewCurrentTrackIndices, NumberOfURIs, EnqueuedURIsAndMetaData | NewQueueLength, NewUpdateID |
| SaveAsSonosPlaylist | QueueID, Title, ObjectID | AssignedObjectID |

---

### VirtualLineIn

- **Control URL**: `/MediaRenderer/VirtualLineIn/Control`
- **Service Type**: `urn:schemas-upnp-org:service:VirtualLineIn:1`

| Action | Inputs | Outputs |
|--------|--------|---------|
| Play | InstanceID, Speed | — |
| Pause | InstanceID | — |
| Stop | InstanceID | — |
| Next | InstanceID | — |
| Previous | InstanceID | — |
| SetVolume | InstanceID, DesiredVolume | — |
| StartTransmission | InstanceID, CoordinatorID | CurrentTransportSettings |
| StopTransmission | InstanceID, CoordinatorID | — |

---

### HTControl

- **Control URL**: `/HTControl/Control`
- **Service Type**: `urn:schemas-upnp-org:service:HTControl:1`
- **Available on**: Beam (S14), Amp (S16), Ray (S36), Playbar (S9) only

| Action | Inputs | Outputs |
|--------|--------|---------|
| CommitLearnedIRCodes | Name | — |
| GetIRRepeaterState | — | CurrentIRRepeaterState (On/Off/Disabled) |
| SetIRRepeaterState | DesiredIRRepeaterState | — |
| GetLEDFeedbackState | — | LEDFeedbackState (On/Off) |
| SetLEDFeedbackState | LEDFeedbackState | — |
| IdentifyIRRemote | Timeout | — |
| IsRemoteConfigured | — | RemoteConfigured |
| LearnIRCode | IRCode, Timeout | — |

---

### MusicServices

- **Control URL**: `/MusicServices/Control`
- **Service Type**: `urn:schemas-upnp-org:service:MusicServices:1`

| Action | Inputs | Outputs |
|--------|--------|---------|
| GetSessionId | ServiceId, Username | SessionId |
| ListAvailableServices | — | AvailableServiceDescriptorList, AvailableServiceTypeList, AvailableServiceListVersion |
| UpdateAvailableServices | — | — |

---

### QPlay

- **Control URL**: `/QPlay/Control` (assumed)
- **Service Type**: `urn:schemas-upnp-org:service:QPlay:1` (assumed)

Tencent QPlay integration service. Limited documentation available.
