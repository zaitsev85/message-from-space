#!/usr/bin/env python
#! nix-shell -i python -p "python38.withPackages(p:[p.pillow])"

import sys
from PIL import Image


class Img:
    def __init__(self, fname, zoom):
        self._img = Image.open(fname)
        self._pixels = self._img.load()
        self._zoom = zoom

        self.size = self._img.size[0] // zoom, self._img.size[1] // zoom

    def __getitem__(self, xy):
        xy = xy[0] * self._zoom, xy[1] * self._zoom
        try:
            c = self._pixels[xy]
        except IndexError:
            return False
        return c[0] + c[1] + c[2] > 382


class Svg:
    def __init__(self, fname, width, height):
        self._f = open(fname, "w")
        self._print(
            f'<svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="{width*8}" height="{height*8}">'
        )
        self._print(f'<rect width="{width*8}" height="{height*8}" style="fill:black"/>')

    def _print(self, *args, **kwargs):
        print(*args, **kwargs, file=self._f)

    def point(self, x, y):
        self._print(
            f'<rect x="{x*8}" y="{y*8}" width="7" height="7" style="fill:white"/>'
        )

    def annotation(self, x, y, w, h, text):
        self._print(
            f'<rect x="{x*8}" y="{y*8}" width="{w*8}" height="{h*8}" style="fill:green;opacity:0.5"/>'
        )
        style = "paint-order: stroke; fill: white; stroke: black; stroke-width: 2px; font:24px bold sans;"
        self._print(
            f'<text x="{x*8+w*4}" y="{y*8+h*4}" dominant-baseline="middle" text-anchor="middle" fill="white" style="{style}">{text}</text>'
        )

    def close(self):
        self._print("</svg>")
        self._f.close()


def decode_number(img, x, y):
    if img[x - 1, y - 1] or img[x, y - 1] or img[x - 1, y] or img[x, y]:
        return None

    # Get the size by iterating over top and left edges
    size = 0
    while True:
        items = (
            img[x + size + 1, y - 1],
            img[x + size + 1, y],
            img[x - 1, y + size + 1],
            img[x, y + size + 1],
        )
        if items == (False, True, False, True):
            size += 1
            continue
        if items == (False, False, False, False):
            break
        return None

    if size == 0:
        return None

    # Check that right and bottom edges are empty
    for i in range(size + 2):
        if img[x + size + 1, y] or img[x, y + size + 1]:
            return None

    # Decode the number
    result, d = 0, 1
    for iy in range(size):
        for ix in range(size):
            result += d * img[x + ix + 1, y + iy + 1]
            d *= 2

    return size, result


def main(in_fname, out_fname):
    img = Img(in_fname, 4)
    svg = Svg(out_fname, img.size[0], img.size[1])

    for y in range(img.size[1]):
        for x in range(img.size[0]):
            if img[x, y]:
                svg.point(x, y)

    for y in range(img.size[1]):
        for x in range(img.size[0]):
            if (n := decode_number(img, x, y)) is not None:
                svg.annotation(x - 0.5, y - 0.5, n[0] + 2, n[0] + 2, n[1])
    svg.close()


main(sys.argv[1], sys.argv[2])
