# Test pubsub from the command line to prove to yourself that
# pubsub works in theory.  From this directory:
#   $ ruby test.rb
#
# This file is NOT required for the service to run, though it
# is copied onto the Corelets directory via ServiceInstaller.

require 'pubsub.rb'

def bp_log(level, msg)
  puts "LOG(#{level}): #{msg}"
end

class BPProxy
  def complete(val)
   # puts "COMPLETE: #{val}"
  end
  
  def error(error, verbose)
    puts "ERROR: #{error}: #{verbose}"
  end
end
 
class Callback
  def initialize(obj)
    @obj = obj
  end
  
  def invoke(val)
    puts "CALLBACK(#{@obj}): #{val}"
  end
end
 
bp = BPProxy.new
ps = PubSub.new([])
cb1 = Callback.new("cb1")
cb2 = Callback.new("cb2")


puts "---- START ----"
ps.addSubscriber(bp, {'subscriber' => cb1, 'topic' => 'test'})
ps.addSubscriber(bp, {'subscriber' => cb2})
puts "---- ADDED SUBSCRIBERS ----"
ps.publish(bp, {'topic' => 'test', 'data' => 'data#1'})
ps.publish(bp, {'topic' => 'test2', 'data' => 'data#2'})
ps.publish(bp, {'data' => 'data#3'})
sleep 1
puts "==== DONE ===="
