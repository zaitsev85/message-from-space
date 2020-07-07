Message #4
==========

.. note::

   If you have any ideas or enhancements for this page, please `edit it on GitHub`_!

Following documentation is a cooperative result combined from our `Discord chat`_ and numerous pull requests.
Thanks to everyone who helped!


Image
-----

This image was produced from the fourth radio transmission using :doc:`previously contributed code <radio-transmission-recording>`.

.. image:: message4.png
   :width: 100px

This partly annotated version of the image was made using :ref:`code from message #2 <message2-code>`.

.. image:: message4-annotated.svg
   :width: 100px


Interpretation
--------------

The new glyph is probably an equality sign, but there is not enough information be sure.
Can be a less-than sign, any operation that preserves its operand, etc.


Decoded
-------

::

   =
   0 = 0
   1 = 1
   2 = 2
   3 = 3
   ...
   10 = 10
   11 = 11
   ...
   -1 = -1
   -2 = -2
   ...


Code
----

Revised version of the Haskell code that supports the equality sign is published on the :ref:`message #3 page <message3-code>`.

Contributed by Discord user @pink_snow.

Example output:

.. image:: message4-annotated-full.svg
   :width: 100px


.. _edit it on GitHub: https://github.com/zaitsev85/message-from-space/blob/master/source/message4.rst
.. _Discord chat: https://discord.gg/xvMJbas
