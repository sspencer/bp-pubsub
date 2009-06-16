# Publish Subscribe

PublishSubscribe is a proof-of-concept [BrowserPlus](http://browserplus.yahoo.com/) service based on HTML5's [Cross Document Messaging](http://www.whatwg.org/specs/web-apps/current-work/#crossDocumentMessages). Web pages in different windows (different browsers even) can send messages back forth. No iframe trickery or polling required. Behind the scenes, all instances of this service run in the same BrowserPlusCore and use a Ruby singleton class to communicate.

The data argument to "postMessage" takes the BrowserPlus "any" data type, meaning you can send the following objects:  (Object, Array, String, Boolean, Integer, Float, Boolean, Null).  However the 2 other BrowserPlus types, Callbacks (JavaScript functions) and FileHandles, are stripped out.  

Listeners can specify interest in all messages or only messages from a certain domain.

Basic code:

    // Condition: BrowserPlus is initialized and PublishSubscribe is required
    // See "test/index.html" for example

    // Function that receives message events
    function receiver(val) {
        // val is { data: Any, origin: "http://example.com"}
    }

    // Listen for events that originate from http://[www.]example.com
    // to receive all, use origin:"*".
    // Note, that "origin" in addListener is not part of HTML5.  
    // Added as a convenience so you don't have to check in JavaScript in
    // the receiver function.
    BrowserPlus.PublishSubscribe.addListener({
        receiver: receiver, 
        origin:"http://example.org"
     }, function() {});

    // Send a message to ALL ("*")
    // targetOrigin could be restricted to "http://example.org"
    BrowserPlus.PublishSubscribe.postMessage({
		data: {whatever:"you", want:2, send:"!"},
		targetOrigin: "*"
	}, function(){});


## Installation

1. Get a recent copy of BrowserPlus (2.3.1) and the [SDK](http://browserplus.yahoo.com/developer/service/sdk/)
2. Clone this project
3. In bp-pubsub/service, run `sdk/bin/ServiceInstaller -f .` The Ruby service must already be installed (if not, run the [photodrop](http://browserplus.yahoo.com/demos/photodrop/) demo)
4. Open bp-pubsub/test/index.html in one or more browsers.  
5. Type a message and hit send.
6. Security implications??

