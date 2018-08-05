# RemoteTasks

This is an example of distributed web application spawning tasks on remote nodes.

To run it, start 3 terminals and start the erlang with the following names: frontend@127.0.0.1, backend1@127.0.0.1 and backend2@127.0.0.1:

```shell
iex --name frontend@127.0.0.1 -S mix 
iex --name backend1@127.0.0.1 -S mix  
iex --name backend2@127.0.0.1 -S mix
```

You can now hit the url [http://localhost:4001/hello](http://localhost:4001/hello) and the bakcend attending the demand will print a text in the console. A simple round robin routing is implemented.

The greeting server is automatically reconnecting to the frontend in case this one restarts. The same way, it updates its list of backend servers every 5 seconds.

If no backend is known by the frontend, it returns a http status code 503.