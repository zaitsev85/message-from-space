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
