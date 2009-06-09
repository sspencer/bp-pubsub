# Publish Subscribe

PublishSubscribe is a proof-of-concept [BrowserPlus](http://browserplus.yahoo.com)
service that creates a pubsub mechanism on localhost. All instances of this service
running in the same BrowserPlusCore will be able to communicate with one another by
passing JSON data objects. A service may register to receive only certain topics or
everything. What this means is that different web pages in different browsers (all on
same machine) should be able to pass messages back and forth.

**NOTE** Unfortunately, this is not quite working.  The "update" method in pubsub.rb 
is not calling back into JavaScript.

## Installation

1. Get a recent copy of BrowserPlus (2.3.1) and the [SDK](http://browserplus.yahoo.com/developer/service/sdk/).
2. Clone this project.
3. In bp-pubsub/service, run sdk/bin/ServiceInstaller -f .
4. Open bp-pubsub/test/index.html in one or more browsers.
5. Type a message and hit send.  Not working yet, though.  
