#6. Predecessor
===============

.. note::

   If you have any ideas or enhancements for this page, please `edit it on GitHub`_!

Following documentation is a cooperative result combined from our `Discord chat`_ and numerous pull requests.
Thanks to everyone who helped!


Image
-----

This image was produced from the sixth radio transmission using :doc:`previously contributed code <radio-transmission-recording>`.

.. image:: message6.png
   :width: 156px

This partly annotated version of the image was made using :ref:`code from message #3 <message3-code>`.

.. image:: message6-annotated.svg
   :width: 156px


Interpretation
--------------

Just like in :doc:`message5`, there are two unknown symbols in this message, together they represent a decrement operation.

The three-pixel symbol is identical to increment operation, and the other complicated one looks similar to increment,
but rejects our theory about internal structure of the symbol, so it's just an arbitrary patterns.


Decoded
-------

.. literalinclude:: message6-decoded.txt


Code
----

Revised version of the Haskell code that supports the ``dec`` glyph is published on the :ref:`message #3 page <message3-code>`.

Contributed by Discord users @pink_snow and @fryguybob.

Example output:

.. image:: message6-annotated-full.svg
   :width: 156px


.. _edit it on GitHub: https://github.com/zaitsev85/message-from-space/blob/master/source/message6.rst
.. _Discord chat: https://discord.gg/xvMJbas
