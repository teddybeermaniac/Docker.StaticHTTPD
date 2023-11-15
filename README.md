# Docker.StaticHTTPD
A tiny Docker image for serving static content, or simple CGI scripts using BusyBox's HTTPD, ash, curl, and jq.

## Usage
Add static files to the `/app` directory, and/or CGI scripts to the `/app/cgi-bin` directory.\
In case when there's no path in the request `/app/index.html` will be returned, or `/app/cgi-bin/index.cgi` will be run.
```
docker run -d -p 8080:8080 -v ./index.html:/app/index.html:ro ghcr.io/teddybeermaniac/docker.statichttpd:latest
```

## Available commands
* \[
* \[\[
* ash
* awk
* base64
* basename
* busybox
* cat
* [curl]
* cut
* date
* dirname
* env
* expr
* false
* find
* fold
* grep
* head
* [jq]
* ls
* rev
* sed
* seq
* sh
* shuf
* sort
* tac
* tail
* timeout
* tr
* true
* uniq
* wc
* xargs
* yes

[curl]: https://github.com/curl/curl
[jq]: https://jqlang.github.io/jq
