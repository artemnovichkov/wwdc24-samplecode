/*
	File:				liveStreamGenerator.go

	Description:	    Generates a continuous live stream by replaying the same segments over and over.
						Playlist is written to the filesystem.					
*/


/*
    Usage:
		$ go run liveStreamGenerator.go --http :[port] --timeScale [scale] --segmentDuration [segmentDur] --windowDuration [windowDur] segment1.mp4 segment2.mp4 ...
		port is TCP port number on which http server runs
		scale is the media timescale, expressed in units per second. Should match moovscope output for track.
		segmentDur is the media duration of every segment in the given timescale
		windowDur is the duration of the live playlist window in the given timescale
		segment1.mp4 segment2.mp4 ... is a list of continuous segments that will form the stream

    Assumptions:
		- Subsequent non-parameter arguments are paths to continuous segments, in order
		- Each segment has exactly the same duration
*/

package main

import (
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"bytes"
	"strings"
	"strconv"
	"encoding/binary"
	"errors"
	"time"
)

// Constants used by script
const (
	mediaPlaylistName	= "media.m3u8"  // Main entry point to media playlist
	mediaPlaylistExt	= ".m3u8"		// Consolidated media playlist
	indexFileName		= "index-file"	// Index file name
	offsetQParam		= "offset"		// Only present in segment URLs
	serverVersionString	= "ll-hls/golang/0.1"
)

// Values used for logging
type LogValues struct {
	StartTime     	time.Time
	Client        	string
	Method        	string
	Protocol      	string
	RequestURI    	string
	Scheme        	string
	HostHdr       	string
	BlockDuration 	time.Duration			// Duration spent blocked waiting for the resource to become available
	TotalDuration 	time.Duration			// Total duration from the start of receiving request until data is off to the NIC
	Size          	uint64
	StatusCode    	int
}

// Global variables
var timeZeroOfStream    time.Time			// Time zero of stream
var totalNumSegments  	int					// Total number of segments provided
var indexFilePath   	string				// Path to index file (containing m3u8 playlist)
var segmentBytes 		[][]byte			// Byte arrays of segments

// Command line parameters
var httpAddr   			string
var timeScale        	= 1000					// Time scale to use
var segmentDuration     = 2 * timeScale		// Segment duration time expressed in timeScale
var windowDuration      = 30 * timeScale   	// Live window time expressed in timeScale

// Entry point of script
func main() {
	var segments 			[]string
	var windowDurationSecs 	int

	// Get start time of stream
	timeZeroOfStream = time.Now()
	fmt.Println("Stream began at: ", timeZeroOfStream)

	// Parse command-line arguments
	flag.StringVar(&httpAddr, "http", ":8443", "Listen address")
	flag.IntVar(&timeScale, "timeScale", 1000, "Timescale for segmentDuration and windowDuration")
	flag.IntVar(&segmentDuration, "segmentDuration", 2000, "Segment duration in timeScale")
	flag.IntVar(&windowDurationSecs, "windowDuration", 30, "Live window duration (s)")
	flag.Parse()
	
	// Initialize variables
	windowDuration = windowDurationSecs * timeScale;
	segments = flag.Args()
	totalNumSegments = len(segments)
	segmentBytes = make([][]byte, totalNumSegments)	// Initialize empty byte array with total number of segments

	// Create index file
	indexFile, err := os.Create(indexFileName)
	if err != nil {
		log.Fatal(err)
	}
	indexFilePath = indexFile.Name()
	fmt.Println("Index file created: ", indexFilePath)
	indexFile.Close()

	// Loop through all segments
	for i := 0; i < totalNumSegments; i++ {
		var err		error
		var content []byte
		fmt.Println("Reading segment: ", segments[i])
		content, err = ioutil.ReadFile(segments[i])
		if err != nil {
			fmt.Println("Error reading: ", segments[i], " error ", err)
			return
		}

		// Save segments to byte array
		segmentBytes[i] = append(segmentBytes[i], content...)
	}
	
	// Write m3u8 playlist to index file
	go writeIndexLoop(indexFilePath)

	// Start the HTTP server
	http.HandleFunc("/", handler)
	hostname, _ := os.Hostname()
	log.Printf("Stream available at http://%s%s/%s\n\n", hostname, httpAddr, mediaPlaylistName)
	log.Fatalln(http.ListenAndServe(httpAddr, nil))
	fmt.Println("\n")
}

// Get the segment offset from the sequence number
func segmentOffsetFromSequenceNum(sequenceNumber int) int {
	return sequenceNumber % totalNumSegments
}

// Get the segment time duration
func segmentAsDuration() time.Duration {
	return time.Duration(segmentDuration) * time.Second / time.Duration(timeScale);
}

// Get the sequence number that should be playing at the current time
func sequenceNumberFromTime(theTime time.Time) int {
	var durationFromZero = theTime.Sub(timeZeroOfStream)
	return int(durationFromZero / segmentAsDuration())
}

// Get playlist contents to write to index file
func getIndexFile(lastSequenceNum int) string {

	var contents string = "#EXTM3U\n"
	var segmentDuration float64 = float64(segmentDuration) / float64(timeScale)		// Segment time in seconds
	var windowSequenceCount = ( windowDuration / timeScale ) / int(segmentDuration)		// Number of segments to show in playlist
	var firstSequenceNum int = lastSequenceNum - windowSequenceCount				// Media sequence number of start with
	
	if firstSequenceNum < 0 {
		firstSequenceNum = 0
	}

	fmt.Println("Writing index file gen ", lastSequenceNum, " starting at ", float64(firstSequenceNum) * segmentDuration)

	// Create media playlist
	contents += "#EXT-X-VERSION:9\n"
	contents += fmt.Sprintf("#EXT-X-TARGETDURATION:%d\n", int(segmentDuration + 1.0))
	contents += fmt.Sprintf("#EXT-X-MEDIA-SEQUENCE:%d\n", firstSequenceNum)
	
	// Append segments
	for sequenceNumber := firstSequenceNum; sequenceNumber <= lastSequenceNum; sequenceNumber++ {
		var segmentOffset = segmentOffsetFromSequenceNum(sequenceNumber)

		// Append out the program date time once per segment offset cycle
		if (segmentOffsetFromSequenceNum(sequenceNumber) == 0) {
			layout := "2006-01-02T15:04:05.000Z"
			var durationUpToSegment = time.Duration(segmentDuration * float64(sequenceNumber) * float64(time.Second))
			var segmentTime = timeZeroOfStream.Add(durationUpToSegment)
			contents += fmt.Sprintf("#EXT-X-PROGRAM-DATE-TIME:%s\n", segmentTime.UTC().Format(layout))
		}

		// Append segment with media sequence value and segment offset
		contents += fmt.Sprintf("#EXTINF: %f,\n", segmentDuration)
		contents += fmt.Sprintf("segment%d.mp4?%s=%d\n", 
									sequenceNumber,
									offsetQParam, segmentOffset)
	}

	return contents
}

// Write playlist to index file
func writeIndexFile(path string, lastSequenceNum int) {
	// Create index file
	file, err := os.Create(indexFileName)
	if err != nil {
		log.Fatal(err)
	}
	
	defer file.Close()

	// Get index file contents and write to file
	var indexFileBytes = getIndexFile(lastSequenceNum)
	file.WriteString(indexFileBytes)
}

// Continuously write to index file with playlist updates
func writeIndexLoop(indexFilePath string) {
	for {
		var now = time.Now()
		var lastSequenceNum = sequenceNumberFromTime(now)

		// Write to index file
		writeIndexFile(indexFilePath, lastSequenceNum)

		// Update with every segment
		time.Sleep(time.Until(now.Add(segmentAsDuration())))
	}
}

// Add integer to a big endian value
func addToBigEndian(bigEndianUInt64 []byte, num int)  []byte {
	// Take a big endian uint64 as a byte array, add num to it, and return it as a big-endian [4]byte
	var orig = binary.BigEndian.Uint64(bigEndianUInt64)
	result := make([]byte, 8)  // sizeof uint64
	binary.BigEndian.PutUint64(result[0:], orig + uint64(num))
	return result
}

// Insert timestamp into fragment
func pokeTimeIntoFragment(fragment []byte, sequenceNum int) []byte {
	// Within each segment is one (or more) tfdt box that contains the proper offset 
	// of samples within that run for that sequence.
	// The sequence number times the segment's duration is the time offset of the virtual sequence.
	// By adding that offset to the tfdt of the segment, we give that segment the correct offset position
	// with virtual sequence
	var sequenceOffset = sequenceNum * segmentDuration
	var tfdtPrefix = []byte{'t', 'f', 'd', 't', 1, 0, 0, 0}
	var updatedFragment = []byte{}
	var remainder = fragment
	
	// Find tfdt box and insert the time offset
	for len(remainder) > 0 {
		var before, after, found = bytes.Cut(remainder, tfdtPrefix)
		if found {
			updatedFragment = append(updatedFragment, before...)
			updatedFragment = append(updatedFragment, tfdtPrefix...)
			var timestampAsBytes = after[0:8]
			var newTimeStamp = addToBigEndian(timestampAsBytes, sequenceOffset)
			updatedFragment = append(updatedFragment, newTimeStamp...)
			remainder = after[8:]
		} else {
			break
		}
	}

	updatedFragment = append(updatedFragment, remainder...)

	return updatedFragment
}

// HTTP server logging
func logLine(l LogValues) {
	// Print log
	fmt.Printf("%s %s %s %s %s %s %s %d %d %s\n",
		l.StartTime.Format("15:04:05.000-07:00"), l.Protocol, l.Method, l.Scheme, l.RequestURI, l.BlockDuration, l.TotalDuration, l.Size, l.StatusCode, http.StatusText(int(l.StatusCode)))
}

// Send error response
func sendError(w http.ResponseWriter, r *http.Request, err error, status int, l LogValues) {
	l.StatusCode = status
	if l.TotalDuration == 0 {
		l.TotalDuration = time.Since(l.StartTime)
	}
	log.Println(err)
	logLine(l)
	w.WriteHeader(int(status))
}

// Handles all https requests to this server:
// - media playlists
// - segments
func handler(w http.ResponseWriter, r *http.Request) {
	// Log the request protocol
	start := time.Now()
	defer r.Body.Close()
	logV := LogValues{StartTime: start, Client: r.RemoteAddr, Method: r.Method, Scheme: r.URL.Scheme, Protocol: r.Proto, RequestURI: r.URL.RequestURI(), HostHdr: r.Host}

	path := r.URL.EscapedPath()[1:]
	offsetParam := r.FormValue(offsetQParam)

	// Handle requests from client
	if strings.HasSuffix(path, mediaPlaylistExt) {
		// Handle request for media playlist serves the index file

		w.Header().Set("Content-Type", "application/vnd.apple.mpegurl")
		w.Header().Set("Server", serverVersionString)
		http.ServeFile(w, r, indexFilePath)
	} else if offsetParam != ""  {		
		// Handle request for segment
		var content = []byte{}
		pathBase := strings.Split(path, ".")[0]
		sequenceNum, _ := strconv.Atoi(pathBase[len("segment"):])

		offset, _ := strconv.Atoi(offsetParam)
		content = pokeTimeIntoFragment(segmentBytes[offset], sequenceNum)

		// Set content headers
		w.Header().Set("Content-Type", "video/mp4")
		w.Header().Set("Cache-Control", "max-age=300")
		w.Header().Set("Content-Length", fmt.Sprintf("%d", len(content)))
		w.Header().Set("Server", serverVersionString)
		w.WriteHeader(http.StatusOK)
		fmt.Fprint(w, string(content))
		logV.Size = uint64(len(content))
	} else {
		// Handle error
		fmt.Println("Cannot handle: ", r)
		sendError(w, r, errors.New("Cannot handle HTTP request"), http.StatusInternalServerError, logV)
		return
	}

	logV.StatusCode = http.StatusOK
	logV.TotalDuration = time.Since(start)
	logLine(logV)

	return
}
