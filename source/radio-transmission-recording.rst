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

-----------
Code
-----------

This Rust code (courtesy aaaa1 at Discord chat) generates decoded image from WAV file.

.. code-block:: rust

   // [dependencies]
   // png = "0.16"
   // hound = "3.4"

   fn main() {
       let r = hound::WavReader::open("radio-transmission-recording.wav").unwrap();
       let spec = r.spec();
       let samples: Vec<i16> = r.into_samples().map(Result::unwrap).collect();

       let freq = 600;
       let step = 2.0 * std::f32::consts::PI * freq as f32 / spec.sample_rate as f32;
       let xys: Vec<(f32, f32)> = samples.iter().copied().enumerate().map(|(i, s)| {
           let s = s as f32;
           let a = i as f32 * step;
           (a.cos() * s, a.sin() * s)
       }).collect();

       let mut axyz = vec![(0.0, 0.0)];
       for (x, y) in xys {
           let last = *axyz.last().unwrap();
           axyz.push((last.0 + x, last.1 + y));
       }

       let mut ds: Vec<f32> = axyz.iter().zip(axyz.iter().skip(1000)).map(|(xy1, xy2)| {
           let dx = xy1.0 - xy2.0;
           let dy = xy1.1 - xy2.1;
           dx * dx + dy * dy
       }).collect();
       let max = *ds.iter().max_by(|x, y| x.partial_cmp(y).unwrap()).unwrap();
       ds.iter_mut().for_each(|x| *x /= max);

       let width = 100usize;
       let height = 195usize;

       let w = std::fs::File::create("res.png").unwrap();
       let w = std::io::BufWriter::new(w);
       let mut encoder = png::Encoder::new(w, width as u32, height as u32);
       encoder.set_color(png::ColorType::Grayscale);
       encoder.set_depth(png::BitDepth::Eight);
       let mut w = encoder.write_header().unwrap();

       let mut data = vec![0u8; width * height];
       for (i, cell) in data.iter_mut().enumerate() {
           let x = i % width;
           let y = i / width / 4;
           *cell = (ds.get((x + y * width) * 529 + 132400).copied().unwrap_or(0.0) * 255.0) as u8;
       }
       w.write_image_data(&data).unwrap();
   }

.. image:: rust-generated-decoded-image.png
   :target: _images/rust-generated-decoded-image.png
