defmodule Sonosex.UPnP.ContentDirectory do
  alias Sonosex.SOAP

  def browse(ip, object_id \\ "Q:0", start \\ 0, count \\ 100) do
    SOAP.call(ip, :content_directory, "Browse",
      ObjectID: object_id,
      BrowseFlag: "BrowseDirectChildren",
      Filter: "*",
      StartingIndex: start,
      RequestedCount: count,
      SortCriteria: ""
    )
  end
end
