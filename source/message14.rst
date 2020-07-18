#14. Demodulate
===============

.. include:: note.rst

.. _edit it on GitHub: https://github.com/zaitsev85/message-from-space/blob/master/source/message14.rst


Image
-----

This image was produced from the fourteenth radio transmission using :doc:`previously contributed code <radio-transmission-recording>`.

.. image:: message14.png
   :width: 188px

This partly annotated version of the image was made using :ref:`code from message #3 <message3-code>`.

.. image:: message14-annotated.svg
   :width: 188px


Interpretation
--------------

This appears to define an inverse operator to that from :doc:`message13`, demonstrating that ``:341`` (``dem``) is the inverse of ``:170`` (``mod``), and vice versa. This suggests that ``:341``, when applied to a linear-encoded number, will create a grid-encoded number.

The behaviour of ``mod`` when applied to a linear number, or ``dem`` when applied to a grid number, is *not* defined.


Decoded
-------

.. literalinclude:: message14-decoded.txt


Code
----

The :ref:`Haskell code <message3-code>` has been revised to decode new glyphs.

Example output:

.. image:: message14-annotated-full.svg
   :width: 188px
