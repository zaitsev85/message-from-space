Message #6
==========

.. note::

   If you have any ideas or enhancements for this page, please `edit it on GitHub`_!


Image
-----

This image was produced from the sixth radio transmission using :doc:`previously contributed code <radio-transmission-recording>`.

.. image:: message6.png
   :width: 100px

This partly annotated version of the image was made using :ref:`code from message #3 <message3-code>`.

.. image:: message6-annotated.svg
   :width: 100px


Interpretation
--------------

Just like in Message #5, there are two unknown symbols in this message, together they represent a decrement operation.

The three-pixel symbol is identical to increment operation, and the other complicated one looks similar to increment,
but rejects our theory about internal structure of the symbol, so it's just an arbitrary patterns.


Decoded
-------

::

  (+)
  id id (+) 1 2 == 3
  id id (+) 2 1 == 3
  id id (+) 0 1 == 1
  id id (+) 2 3 == 5
  id id (+) 3 5 == 8


Code
----

.. todo::

   Revise the :ref:`Haskell code <message3-code>` to support new glyphs from the sixth message.


Once again, I encourage you to join our `chat server`_ to combine efforts and crack this message.

.. _edit it on GitHub: https://github.com/zaitsev85/message-from-space/blob/master/source/message6.rst
.. _chat server: https://discord.gg/xvMJbas
