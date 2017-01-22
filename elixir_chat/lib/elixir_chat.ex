defmodule ElixirChat do

  # Gets user name and calls all primary actions
  def start do
    # Get user name
    user = IO.gets("Type in your name: ") |> String.strip
    # Display invitation using user name
    IO.puts "Hi #{user}, you just joined a chat room! Type your message in and press enter."

    # Initalize AMQP and start connection
    {:ok, conn} = AMQP.Connection.open
    # Create channel
    {:ok, channel} = AMQP.Channel.open(conn)
    # Create queue
    {:ok, queue_data } = AMQP.Queue.declare channel, ""

    # Declare a fanout exchange
    AMQP.Exchange.fanout(channel, "super.chat")
    # Bind channell to the queue
    AMQP.Queue.bind channel, queue_data.queue, "super.chat"

    # Start listening for messages
    listen_for_messages(channel, queue_data.queue)
    wait_for_message(user, channel)
  end

  # Gets input from user and calls publish method then loops over using recursion
  def wait_for_message(user, channel) do
    # Get user input
    message = IO.gets("") |> String.strip
    # Publish message
    publish_message(user, message, channel)
    # Call self
    wait_for_message(user, channel)
  end

  # Intercepts messages and calls display method
  def listen_for_messages(channel, queue_name) do
    # Go through all messages in the queue and display them
    AMQP.Queue.subscribe channel, queue_name, fn(payload, _meta) ->
      { :ok, data } = JSON.decode(payload)
      display_message(data["user"], data["message"])
    end
  end
  
  # Displays a nicely formatted messages
  def display_message(user, message) do
    IO.puts "#{user}: #{message}"
  end

  # Publishes messages to the queue
  def publish_message(user, message, channel) do
    # Create ordered data to be easily processed
    { :ok, data } = JSON.encode([user: user, message: message])
    # Publish message to the exchange channel
    AMQP.Basic.publish channel, "super.chat", "", data
  end

end

ElixirChat.start
