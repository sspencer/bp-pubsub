require "singleton"
require "pp"
require 'uri'

def dbg(o)
  msg = o.class.name == "String" ? o : o.pretty_inspect
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

    #dbg("origin=#{@origin}")

    # one service instance can have multiple subscribers 
    # (could be subscribing to different topics)
    @subscribers = {}
    
    # create a unique id so subscribers can be removed
    @@count = 0
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


  def postMessage(bp, args)
    PSData.instance.publish(args["data"], @origin)
    bp.complete(true)
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
  'micro_version' => 0,  
  'documentation' => 'A cross document message service that works between web pages on one or more browsers.',
  'functions' =>  
  [  
    {  
      'name' => 'addListener',  
      'documentation' => "Subscribe to the pubsub mechanism.",
      'arguments' => [  
        {  
          'name' => 'receiver',
          'type' => 'callback',  
          'documentation' => 'JavaScript function that is notified of a message.  The value pass to the callback contains {data:(JSON), origin,(String)}',
          'required' => true  
        },
        {
          'name' => 'origin',
          'type' => 'string',
          'documentation' => 'Optional string that specifies the domain ("http://example.com") to accept messages from.  Defaults to all ("*").',
          'required' => false
        }
      ]
    },
    {
      'name' => 'postMessage',
      'documentation' => 'Post a message.  The message posted is associated with the domain of the sender.  Receivers may elect to filter messages based on the domain.',
      'arguments' => [
        {
          'name' => 'data',
          'type' => 'any',
          'documentation' => 'The JSON data object that is passed to all interested subscribers.',
          'required' => true
        }
      ]
    }
  ]   
}
