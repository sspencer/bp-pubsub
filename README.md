# Publish Subscribe

PublishSubscribe is a proof-of-concept [BrowserPlus](http://browserplus.yahoo.com/)
service that creates a pubsub mechanism on localhost. All instances of this service
running in the same BrowserPlusCore will be able to communicate with one another by
passing JSON data objects. A service may register to receive only certain topics or
everything. What this means is that different web pages in different browsers (all on
same machine) can pass messages back and forth.

## Installation

1. Get a recent copy of BrowserPlus (2.3.1) and the [SDK](http://browserplus.yahoo.com/developer/service/sdk/)
2. Clone this project
3. In bp-pubsub/service, run `sdk/bin/ServiceInstaller -f .` The Ruby service must already be installed (if not, run the [photodrop](http://browserplus.yahoo.com/demos/photodrop/) demo)
4. Open bp-pubsub/test/index.html in one or more browsers.  
5. Type a message and hit send.
6. Security implications??

