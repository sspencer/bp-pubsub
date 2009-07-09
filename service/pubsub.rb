require "singleton"
require "pp"
require 'uri'

#
# Simplified Observable module - notify observers of changed data.
#
class PSObservable
  
  # observer has to respond to "update"
  def add_observer(observer)
    @observer_peers = [] unless defined? @observer_peers
    unless observer.respond_to? :update
      raise NoMethodError, "observer needs to respond to 'update'" 
    end
    @observer_peers.push observer
  end

  # notify observers, removing observer from list immediately upon failure
  def notify_observers(*arg)
    if defined? @observer_peers
	    for i in @observer_peers.dup
	      begin
	        i.update(*arg)
        rescue
          # observer went away (browser window closed), so delete it
          @observer_peers.delete i
        end
	    end
    end
  end

  include Singleton
end

# Visible to BrowserPlus
#   addListener
#   postMessage
class PubSub

  # Creation triggered through BrowserPlus
  def initialize(context)  
    uri = URI.parse(context['uri'])

    if uri.scheme == "file"
      domain = ""
    else
      path_comps = uri.host.scan(/[^.]+/) # separate domain between dots ... example.com into [example com]
      path_comps.unshift("www") if path_comps.length == 2 # make 'example.com' into 'www.example.com'
      domain = path_comps.join(".")
    end

    # origin is "http://www.example.com" or "file://"
    @origin = "#{uri.scheme}://#{domain}"

    # one service instance can have multiple subscribers 
    @subscribers = []
    
    # unique object to signal data types that shouldn't be transfered through postMessage
    @@DontCopy = Object.new
  end  
  
  
  # Log through BrowserPlus and text file if you need to
  def dbg(o)
    msg = o.class.name == "String" ? o : o.pretty_inspect
    msg = "#{self}: #{msg}"
	  bp_log("info", "PUBSUB: #{msg}")
    File.open("/tmp/dbg.txt", 'a') { |f| f.puts(msg) }
  end


  # Copies data object allowing only following types:
  #     Hash, Array, String, Fixnum, Float, TrueClass, FalseClass
  # (Meaning that "Pathname" and "BPCallback" are stripped out)
  def sanitize(data)
    case data
    when Hash
      v = {}
      data.each do |key, value|
        dv = sanitize(value)
        v[key] = dv if (dv != @@DontCopy)
      end
    when Array
      v = []
      data.each do |value|
        dv = sanitize(value)
        v.push(dv) if (dv != @@DontCopy)
      end
    when String, Fixnum, Float, TrueClass, FalseClass, NilClass
      v = data
    else
      v = @@DontCopy
    end

    return v
  end


  # Called via PSObservable
  def update(data, msgOrigin, msgTarget)
    # data - message to send
    # msgOrigin - where message is from
    # msgTarget - where message should be sent (could be '*')
    # @origin - where this client lives

    # if message is to all or to *this* client's origin
    if (msgTarget == '*' || msgTarget == @origin)
      # for each subscriber on *this* client
      @subscribers.dup.each do |s|
        # bonus (not HTML5) - allow client to filter here and not in JavaScript
        if (s["filter"] == "*" || s["filter"] == msgOrigin)
          s["callback"].invoke({"data"=> data, "origin" => msgOrigin})
        end #if 
      end #each_key
    end #if
  end #def


  # Visible to JavaScript - register as a listener
  def addListener(bp, args)
    @subscribers.push({"filter" => args["origin"] || "*", "callback" => args["receiver"]})

    # become an observer
    PSObservable.instance.add_observer(self) if (@subscribers.count == 1)
    
    # NEVER CALL bp.complete or callback will become invalid
  end


  # Visible to JavaScript - send a message
  def postMessage(bp, args)
    target = args["targetOrigin"] # where message should be sent
    data = sanitize(args["data"])  # sanitize data

    if (data == @@DontCopy)
      bp.error("DataTransferError", "Objects of that type cannot be sent through postMessage")
    else
      PSObservable.instance.notify_observers(data, @origin, target)
      bp.complete(true)
    end
  end

end #class
  
  
rubyCoreletDefinition = {  
  'class' => "PubSub",  
  'name' => "PublishSubscribe",  
  'major_version' => 0,  
  'minor_version' => 3,  
  'micro_version' => 1,  
  'documentation' => 'A cross document message service that allows JavaScript to send and receive messages between ' + 
    'web pages within one or more browsers (cross document + cross process).',
  'functions' =>  
  [  
    {  
      'name' => 'addListener',  
      'documentation' => "Subscribe to the pubsub mechanism.",
      'arguments' => [  
        {  
          'name' => 'receiver',
          'type' => 'callback',  
          'documentation' => 'JavaScript function that is notified of a message.  The value passed to the callback ' + 
            'contains {data:(Any), origin:(String)}',
          'required' => true  
        },
        {
          'name' => 'origin',
          'type' => 'string',
          'documentation' => 'Optional string that specifies the domain ("http://example.com") to accept messages ' + 
            'from.  Defaults to all ("*").  This is not part of the HTML5 spec but allows automatic filtering of ' + 
            'events so JavaScript listener does not have to manually check event.origin.',
          'required' => false
        }
      ]
    },
    {
      'name' => 'postMessage',
      'documentation' => 'Post a message.  The message posted is associated with the domain of the sender.  ' + 
        'Receivers may elect to filter messages based on the domain.',
      'arguments' => [
        {
          'name' => 'data',
          'type' => 'any',
          'documentation' => 'The data object (Object, Array, String, Boolean, Integer, Float, Boolean, Null) that ' + 
            'is posted to all interested subscribers.  All other data types are stripped out of the passed object.',
          'required' => true
        },
        {
          'name' => 'targetOrigin',
          'type' => 'string',
          'documentation' => 'The origin specifies where to send the message to.  Options are either an URI like ' + 
            '"http://example.org" or "*" to pass it to all listeners.',
          'required' => true
        }
      ]
    }
  ]   
}
