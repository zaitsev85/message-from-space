Radio Transmission Recording
============================

:download:`Download <radio-transmission-recording.wav>` radio transmission recording.
It was originally received at ~5 GHz and scaled down to ~500 Hz to make signal audible for humans.

// TODO: what does it mean? If you have any idea, please `edit this page on GitHub`_!

-----------
Spectrogram
-----------

Spectrogram of the recording (`notebook`_):

.. image:: radio-transmission-recording.png
   :target: _images/radio-transmission-recording.png

.. _notebook: https://gist.github.com/nya3jp/5094571c5905783327f35e8df207c8ad#file-spectrogram-ipynb

-----------
Image
-----------

Decoded image of the recording (`img_source_pgm`_):

.. image:: decoded_greyscale2_scaledup.png
   :target: _images/decoded_greyscale2_scaledup.png
   :class: with-shadow

-----------------
Possible decoding
-----------------

Probably the symbols on the left represent digits and the number of elements on the right are the unary representation of this digit.

Suppose that pixels in left symbols are enumerated as such:
::
   123
   456
   789

Pixels 1, 2 and 4 are always the same: 0 1 1, correspondingly.

Pixel 5 flips with every symbol. Pixel 6 flips every two symbols. Pixel 8 flips every four symbols. Pixel 9 probably flips every 8 symbols, but data is not enough to judge.

.. _img_source_pgm: https://github.com/elventian/message-from-space/blob/master/source/decoded_greyscale2.pgm

.. _edit this page on GitHub: https://github.com/zaitsev85/message-from-space/blob/master/source/radio-transmission-recording.rst
