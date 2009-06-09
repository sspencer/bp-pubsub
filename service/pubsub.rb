require "singleton"
require "pp"

def dbg(o)
  msg = o.class.name == "String" ? o : o.pretty_inspect
	bp_log("info", "PUBSUB: #{msg}")
 # File.open("/tmp/dbg.txt", 'a') { |f| f.puts(msg) }
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
	        dbg("calling update")
	        i.update(*arg)
        rescue
          dbg("update failed")
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
    # one service instance can have multiple subscribers 
    # (could be subscribing to different topics)
    @subscribers = {}
    
    # create a unique id so subscribers can be removed
    @@count = 0
  end  
  
  def addSubscriber(bp, args)
    # create unique id
    @@count += 1
    id = "cb_#{@@count}" 

    # hash of all subscribers
    @subscribers[id] = {"topic" => args["topic"], "cb" => args["subscriber"]}

    # become an observer
    if (@subscribers.count == 1)
      PSData.instance.add_observer(self)
    end
    
    # Remember - bp.complete() invalidates all callbacks, so we can't return anything here.

  end

  def publish(bp, args)
    # publish an event
    # topic can be null here
    PSData.instance.publish(args["topic"], args["data"])
    bp.complete(true)
  end

  def update(topic, data)
    @subscribers.each_key do |key|
      val = @subscribers[key]
      tp = val["topic"]
      cb = val["cb"]
      # 1: if subscriber has no topic, invoke callback
      # 2: if subscriber topic == published topic, invoke callback
      if (tp.nil? || tp == topic)
        begin
#          dbg("invoking #{cb.pretty_inspect}")
          cb.invoke(data)
        rescue
#          dbg("invoke failed!")
        end
      end
    end 
  end #update

end  
  
  
rubyCoreletDefinition = {  
  'class' => "PubSub",  
  'name' => "PublishSubscribe",  
  'major_version' => 0,  
  'minor_version' => 0,  
  'micro_version' => 5,  
  'documentation' => 'A Publish Subscribe that works for all BrowserPlus clients on localhost.  " + 
    "Allows you to subscribe to all messages, or just messages with a specified topic.',  
  'functions' =>  
  [  
    {  
      'name' => 'addSubscriber',  
      'documentation' => "Subscribe to the pubsub mechanism.",
      'arguments' => [  
        {  
          'name' => 'subscriber',
          'type' => 'callback',  
          'documentation' => 'Method that is notified of publish event.',  
          'required' => true  
        },
        {
          'name' => 'topic',
          'type' => 'string',
          'documentation' => 'Optional string that describes data topic.',
          'required' => false
        }
      ]
    },
    {
      'name' => 'publish',
      'documentation' => 'Publish a message.',
      'arguments' => [
        {
          'name' => 'data',
          'type' => 'map',
          'documentation' => 'The JSON data object that is passed to all interested subscribers.',
          'required' => true
        },
        {
          'name' => 'topic',
          'type' => 'string',
          'documentation' => 'Optional string that describes data topic.',
          'required' => false
        }
      ]
    }
  ]   
}