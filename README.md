# Legolas

Legolas is a process message interceptor for debug purposes, under the hood
it uses `dbg` to trace calls over a single process. All received messages to the process
are intercepted and sent to the designed collectors processes.

## Adding targets

In order to start, first add a target process (pid) to intercept messages.

    iex(1)> Legolas.add_target self
    :ok

The above code will intercept all messages sent to the `self` process.

## Adding collectors

A collector is a process (pid) that will receive all messages intercepted in the target processes.

    iex(2)> Legolas.add_collector self

In the above code `self` will receive all messages sent to targets processes.

## Legolas in action

Now send a message to the target process and check how the collectors will receive the same message.

@TODO: We need to support to handle multiple pattern matching for messages, for now Legolas supports to intercept
messages a single Phoenix Socket Message

When intercept a new message, the collector process receive the message same as target process and emits a log.