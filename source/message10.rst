#10. Integer Division
=====================

.. note::

   If you have any ideas or enhancements for this page, please `edit it on GitHub`_!

Following documentation is a cooperative result combined from our `Discord chat`_ and numerous pull requests.
Thanks to everyone who helped!


Image
-----

This image was produced from the tenth radio transmission using :doc:`previously contributed code <radio-transmission-recording>`.

.. image:: message10.png
   :width: 180px

This partly annotated version of the image was made using :ref:`code from message #3 <message3-code>`.

.. image:: message10-annotated.svg
   :width: 180px


Interpretation
--------------

The new operator is consistent with integer division which rounds toward zero.


Decoded
-------

.. literalinclude:: message10-decoded.txt


Code
----

The :ref:`Haskell code <message3-code>` has been revised to decode the integer division operator.

.. literalinclude:: annotate10.hs.diff
   :language: diff

Example output:

.. image:: message10-annotated-full.svg
   :width: 180px


.. _edit it on GitHub: https://github.com/zaitsev85/message-from-space/blob/master/source/message10.rst
.. _Discord chat: https://discord.gg/xvMJbas
