require 'json'
require 'bunny'
class Chat

  # Displays a nicely formatted messages
  def display_message(user, message)
    puts "#{user}: #{message}"
  end

  # Class constructor where all primary actons are baing called
  def initialize
    print "Type in your name: "
    # Get user name
    @current_user = gets.strip
    # Display invitation using user name
    puts "Hi #{@current_user}, you just joined a chat room! Type your message in and press enter."

    # Initalize Bunny and start connection
    conn = Bunny.new
    conn.start

    # Create channel
    @channel = conn.create_channel

    # Declare a fanout exchange
    @exchange = @channel.fanout("super.chat")

    listen_for_messages
  end

  # Intercepts messages and calls display method
  def listen_for_messages
    queue = @channel.queue("")

    # Go through all messages in the queue and display them
    queue.bind(@exchange).subscribe do |delivery_info, metadata, payload|
      data = JSON.parse(payload)
      display_message(data['user'], data['message'])
    end
  end

  # Publishes messages to the queue
  def publish_message(user, message)
    # Create ordered data to be easily processed
    data = JSON.generate({ user: user, message: message })
    # Publish message to the exchange channel
    @exchange.publish(data)
  end

  # Gets input from user and calls publish method then loops over using recursion
  def wait_for_message
    # Get user input
    message = gets.strip
    # Publish message
    publish_message(@current_user, message)
    # Call self
    wait_for_message
  end

end

chat = Chat.new
# Init user first message input
chat.wait_for_message
