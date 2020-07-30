Alien Proxy Protocol
====================

Alien Proxy allows you to send requests to the spacecraft in orbit using our antenna.

It's a simple HTTP server.


Base Url
--------

https://api.pegovka.space/


Send a Request to Spacecraft
----------------------------

Pass modulated string in the request body with a ``Content-Type: text/plain`` HTTP header.

Relative URL: ``/aliens/send``

Sample request:

::

   POST /aliens/send HTTP/1.1

   1101000


Possible Responses
^^^^^^^^^^^^^^^^^^

200 OK
******

You will get this response if the spacecraft responds fast enough.
 
Response body will contain modulated spacecraft response with a ``Content-Type: text/plain`` HTTP header.

Sample response:

::

   HTTP/1.1 200 OK

   1101100001110111110111101010101011100

    
302 Found
*********

You will get this response if the spacecraft doesn't respond fast enough.
     
If the spacecraft doesn't respond fast enough we return ``302 Found`` status code.
The ``Location`` response HTTP header will contain an URL where you can ask for the response again later.
In fact, this header will always contain ``/aliens/{responseId}``.
It's a long-polling protocol, so you can make a new request to this location immediately after you got it.
Many HTTP client implementations, e.g. C#'s ``HttpClient``, can follow redirects automatically, so you don't deal with this.

Sample response:

::

   HTTP/1.1 302 Found
   Location: /aliens/75960227-653C-47E3-A47A-118A46AFFD4C


Get a Response From Spacecraft
------------------------------

Use this to get a response to the request you have sent earlier,
in case the spacecraft didn't respond fast enough.

Relative URL: ``/aliens/{responseId}``

Possible responses are the same as in ``/aliens/send``.
