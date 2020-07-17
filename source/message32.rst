#32. Plotting
========

.. include:: note-discord.rst

.. _edit it on GitHub: https://github.com/zaitsev85/message-from-space/blob/master/source/message32.rst


Image
-----

This image was produced from the thirty-second radio transmission using :doc:`previously contributed code <radio-transmission-recording>`.

.. image:: message32.png
   :width: 816px


Interpretation
--------------

The application of the square symbol to an arrow-enclosed sequence of plot commands results in an image being displayed.

Line 1: do nothing (plot command list is empty)
Line 2: the plot command takes two arguments. When these arguments are both 1, display a single dot one pixel in (in both directions) from the top left of the screen.
Line 3: the last argument describes vertical displacement. When the first argument is 1, and the second argument is 2, display a single dot two pixels down and one across from the top left of the screen.
Line 4: demonstrates a pixel at (2 across, 5 down)
Line 5: multiple plotting commands are separated by a bar. This puts one pixel at (1, 2) and one at (3, 1)
Line 6: this is a plotting command sequence that displays five pixels in a shape representing the grid number 2.

.. include:: message32-condensed.txt


Decoded
-------

.. literalinclude:: message32-decoded.txt
