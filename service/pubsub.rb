require "socket"
require "singleton"
require "observer"
require "pp"

def dbg(o)
	#bp_log("info", (o.class.name == "String") ? o : o.pretty_inspect)
 # File.open("/tmp/dbg.txt", 'a') { |f| f.puts((o.class.name == "String") ? o : o.pretty_inspect) }
end

class PSData
  include Observable
  
  def publish(topic, data)
    # MUST call changed here, otherwise nothing is sent
    changed 
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
    @@IDBASE = 10_000_000
  end  
  
  def addSubscriber(bp, args)
    # create unique id
    @@count += 1
    rnd = rand(@@IDBASE) + @@IDBASE
    id = "cb_#{@@count}_#{rnd}" 

    # hash of all subscribers
    @subscribers[id] = {"topic" => args["topic"], "cb" => args["subscriber"]}

    # become an observer
    if (@subscribers.count == 1)
      PSData.instance.add_observer(self)
    end
    
    # send back unique id
    bp.complete(id)
  end

  def removeSubscriber(bp, args)
    # save result of delete
    r = @subscribers.delete(args["id"])

    # remove ourselves as an observer if we have no more subscribers
    if (@subscribers.count == 0)
      PSData.instance.delete_observer(self)
    end
    
    # return true if subscriber was deleted
    bp.complete(r == 1)
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
        cb.invoke(data)
      end
    end
  end
end  
  
  
rubyCoreletDefinition = {  
  'class' => "PubSub",  
  'name' => "PublishSubscribe",  
  'major_version' => 0,  
  'minor_version' => 0,  
  'micro_version' => 3,  
  'documentation' => 'A Publish Subscribe that works for all BrowserPlus clients on localhost.  " + 
    "Allows you to subscribe to all messages, or just messages with a specified topic.',  
  'functions' =>  
  [  
    {  
      'name' => 'addSubscriber',  
      'documentation' => "Subscribe to the pubsub mechanism.  The ID of the subscriber(string) is returned so you can removeSubscriber later.",
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
      'name' => 'removeSubscriber',
      'documentation' => 'Remove a subscriber.  Returns true if subscirber with that ID is removed.',
      'arguments' => [
        {
          'name' => 'id',
          'type' => 'string',
          'documentation' => 'The ID returned from addSubscriber.',
          'required' => true
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