# Configuration file for the Sphinx documentation builder.
#
# This file only contains a selection of the most common options. For a full
# list see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Path setup --------------------------------------------------------------

# If extensions (or modules to document with autodoc) are in another directory,
# add these directories to sys.path here. If the directory is relative to the
# documentation root, use os.path.abspath to make it absolute, like shown here.
#
# import os
# import sys
# sys.path.insert(0, os.path.abspath('.'))
import os
import sphinx_rtd_theme
from PIL import Image


# -- Project information -----------------------------------------------------

project = 'Message From Space'
copyright = '2020, Ivan Zaitsev'
author = 'Ivan Zaitsev'


# -- General configuration ---------------------------------------------------

# Add any Sphinx extension module names here, as strings. They can be
# extensions coming with Sphinx (named 'sphinx.ext.*') or your custom
# ones.
extensions = [
    'sphinx_rtd_theme',
    'sphinxcontrib.images',
    'sphinxcontrib.rsvgconverter',
    'sphinx.ext.todo',
]

todo_include_todos = True
todo_link_only = True

images_config = {
    'override_image_directive': True,
}

# Add any paths that contain templates here, relative to this directory.
templates_path = ['_templates']

# List of patterns, relative to source directory, that match files and
# directories to ignore when looking for source files.
# This pattern also affects html_static_path and html_extra_path.
exclude_patterns = []


# -- Options for HTML output -------------------------------------------------

# The theme to use for HTML and HTML Help pages.  See the documentation for
# a list of builtin themes.
#
html_theme = 'sphinx_rtd_theme'

# Add any paths that contain custom static files (such as style sheets) here,
# relative to this directory. They are copied after the builtin static files,
# so a file named "default.css" will overwrite the builtin "default.css".
html_static_path = ['_static']

# Condensed version generation
def setup(app):
    dirname = os.path.dirname(__file__)

    def get_image_width(filename):
        img = Image.open(filename)
        return img.size[0]

    with open(os.path.join(dirname, 'condensed-version.rst'), 'w') as f:
        f.write('Condensed Version\n')
        f.write('=================\n\n')

        i = 1
        while os.path.isfile(os.path.join(dirname, 'message%d.png' % i)):
            with open(os.path.join(dirname, 'message%d.rst' % i)) as m:
                f.write(m.readline())
            f.write('----------\n\n')

            f.write('.. image:: message%d.png\n' % i)
            f.write('   :width: %dpx\n\n' % get_image_width(os.path.join(dirname, 'message%d.png' % i)))

            f.write('.. literalinclude:: message%d-decoded.txt\n\n\n' % i)

            i += 1
