# Providing an integrated view of your timeline when playing HLS interstitials

Go beyond simple ad insertion with point and fill occupancy HLS interstitials.

## Overview

- Note: This sample code project is associated with WWDC24 session 10114: [Enhance ad experiences with HLS Interstitials](https://developer.apple.com/wwdc24/10114/)

## Configure the sample code project

Using the examples under the Live stream examples section of the app requires running a local test stream. The project includes a Go script that starts a local web server that hosts this example stream. You must have [Go](https://go.dev/doc/install) installed to run this script.

Open a Terminal window, change to the `/Source/LiveStreamExample/` directory, and run the following command to start the stream:

```
go run liveStreamGenerator.go --http :8443 segment0.mp4 segment1.mp4 segment2.mp4 segment3.mp4
```

When the stream starts, copy its URL, which is in the following format: `http://<hostname>:8443/media.m3u8`. In the Xcode project, open the `Menu.json` file, and replace the placeholder URLs (http://livestreamserver.url:8443/media.m3u8) with your local stream URL. Relaunch the app to view the live stream examples.

