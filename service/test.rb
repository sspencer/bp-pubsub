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
    puts "CALLBACK(#{@obj}): #{val.pretty_inspect}"
  end
end
 
puts "==== START ===="

bp = BPProxy.new

p1 = PubSub.new({"uri"=>"http://www.example.com/one/two/three.html"})
p2 = PubSub.new({"uri"=>"http://test.com/widget/index.html"})
p3 = PubSub.new({"uri"=>"http://hello.there.com/nice.php"})
c1 = Callback.new("callback_1")
c2 = Callback.new("callback_2")
c3 = Callback.new("callback_3")

p1.addListener(bp, {'receiver' => c1, 'origin' => "http://www.example.com"})
p2.addListener(bp, {'receiver' => c2, 'origin' => "http://www.test.com"})
p3.addListener(bp, {'receiver' => c3, 'origin' => "*"})

p1.postMessage(bp, 'data' => 'data from example.com')
p2.postMessage(bp, 'data' => 'data from test.com')
p3.postMessage(bp, 'data' => 'data from there.com')

puts "==== DONE ===="
