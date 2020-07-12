#! /usr/bin/env nix-shell
#! nix-shell -i python -p "python38.withPackages(ps: with ps; [ pillow inflect jinja2 ])"

import inflect
import os
import subprocess
import sys
from jinja2 import Template
from PIL import Image


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print('please provide new message number')
        exit(1)

    message_number = int(sys.argv[1])
    os.chdir(os.path.join(os.path.dirname(__file__), 'source'))

    if not os.path.isfile('message%d.png' % message_number):
        print('image file not found')
        exit(1)

    # render annotated SVG and textual representation
    subprocess.call([
        './annotate.hs',
        'message%d.png' % message_number,
        'message%d-annotated.svg' % message_number,
        'message%d-decoded.txt' % message_number,
    ])

    # render the main documentation page
    with open('../add-new-message.j2') as t:
        template = Template(t.read())

    inflector = inflect.engine()
    img = Image.open('message%d.png' % message_number)
    
    with open('message%d.rst' % message_number, 'w') as m:
        m.write(template.render(
            message_number=message_number,
            message_number_words=inflector.number_to_words(inflector.ordinal(message_number)),
            image_width=img.size[0]
        ))

    # add new page to TOC
    with open('index.rst') as index:
        index_contents = index.readlines()

    with open('index.rst', 'w') as index:
        for line in index_contents:
            if 'appendix' in line:
                line = ('   message%d\n' % message_number) + line
            index.write(line)
