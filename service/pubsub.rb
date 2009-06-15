require "singleton"
require "pp"
require 'uri'

def dbg(o)
  #msg = o.class.name == "String" ? o : o.pretty_inspect
	#bp_log("info", "PUBSUB: #{msg}")
  #File.open("/tmp/dbg.txt", 'a') { |f| f.puts(msg) }
end


class PSData
  def add_observer(observer)
    @observer_peers = [] unless defined? @observer_peers
    unless observer.respond_to? :update
      raise NoMethodError, "observer needs to respond to 'update'" 
    end
    @observer_peers.push observer
  end

  #
  # If this object's changed state is +true+, invoke the update method in each
  # currently associated observer in turn, passing it the given arguments. The
  # changed state is then set to +false+.
  #
  def notify_observers(*arg)
    if defined? @observer_peers
	    for i in @observer_peers.dup
	      begin
	        i.update(*arg)
        rescue
          @observer_peers.delete i
        end
	    end
    end
  end

  def publish(topic, data)
    notify_observers(topic, data)
  end

  include Singleton

end


class PubSub
  def initialize(context)  
    uri = URI.parse(context['uri'])

    if uri.scheme == "file"
      domain = ""
    else
      path_comps = uri.host.scan(/[^.]+/) # separate domain between dots ... yahoo.com into [yahoo com]
      path_comps.unshift("www") if path_comps.length == 2 # make 'yahoo.com' into 'www.yahoo.com'
      domain = path_comps.join(".")
    end

    @origin = "#{uri.scheme}://#{domain}"

    # one service instance can have multiple subscribers 
    # (could be subscribing to different topics)
    @subscribers = {}
    
    # create a unique id so subscribers can be removed
    @@count = 0

    # unqiue object to signal data types that shouldn't be transfered through postMessage
    @@DontCopy = Object.new
  end  
  

  def addListener(bp, args)
    # create unique id
    @@count += 1
    id = "cb_#{@@count}" 

    # hash of all subscribers
    @subscribers[id] = {"origin" => args["origin"] || "*", "receiver" => args["receiver"]}

    # become an observer
    if (@subscribers.count == 1)
      PSData.instance.add_observer(self)
    end
  end

  # Copies data object allowing only following types:
  #   Hash, Array, String, Fixnum, Float, TrueClass, FalseClass
  # Meaning that it strips out
  #   Pathname and BPCallback
  def dupData(data)
    case data
    when Hash
      v = {}
      data.each do |key, value|
        dv = dupData(value)
        v[key] = dv if (dv != @@DontCopy)
      end
    when Array
      v = []
      data.each do |value|
        dv = dupData(value)
        v.push(dv) if (dv != @@DontCopy)
      end
    when String, Fixnum, Float, TrueClass, FalseClass, NilClass
      v = data
    else
      v = @@DontCopy
    end

    v
  end

  def postMessage(bp, args)
    data = dupData(args["data"])
    if (data == @@DontCopy)
      bp.error("DataTransferError", "Objects of that type cannot be sent through postMessage")
    else
      PSData.instance.publish(data, @origin)
      bp.complete(true)
    end
  end


  def update(data, domain)
    @subscribers.dup.each_key do |key|
      origin = @subscribers[key]["origin"]
      receiver = @subscribers[key]["receiver"]

      if (origin == "*" || origin == domain)
        @subscribers[key]["receiver"].invoke({"data"=> data, "origin" => domain})
      end #if 

    end #each_key
  end #def

end #class
  
  
rubyCoreletDefinition = {  
  'class' => "PubSub",  
  'name' => "PublishSubscribe",  
  'major_version' => 0,  
  'minor_version' => 2,  
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
            'from.  Defaults to all ("*").',
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
        }
      ]
    }
  ]   
}
