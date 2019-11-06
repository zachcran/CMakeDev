*******************
Documenting CMakePP
*******************

For the most part documentation in the CMakePP project falls into one of two
categories: API or narrative. The following sections describe the conventions
associated with these types. Many of the conventions rely on reStructuredText
(reST) so the reader may find
`this <http://www.sphinx-doc.org/en/master/usage/restructuredtext/basics.html>`_
reST primer to be of use.

.. note::

   I presume there's actually a real computer science term for "narrative
   documentation"; however, my Googl-ing did not manage to find it so I'm using
   "narrative documentation" as a placeholder for it. If you know the real term
   please open an issue on the CMakeDev repo so that the documentation can be
   updated.

API Documentation
=================

API documentation tells you how to use a function, what a variable is for, or
what a class models. Maintaining good API documentation is a key aspect of
ensuring CMakePP is user-friendly. API documentation should not be used for
prolonged discussions of the inner workings of a function or algorithm (such
things should be documented, but fall under narrative documentation). For the
most part source code associated with CMakePP is written in one of two
languages, Python or CMake, and the following subsections describe the
conventions for documenting APIs in each of those languages in detail.

Python
------

Documenting Python code is done following the usual reST standards laid out in
`Python's developer guide <https://devguide.python.org/documenting/>`_. The main
points are:

- No more than 80 characters on a line
- Indents are 3 spaces, not 4, and not tabs

CMake
-----

CMake documentation uses the ``CMakeDoc`` tool developed by the CMakePP project.
Conventions for documenting CMake code are forthcoming once ``CMakeDoc`` is
further along.

Narrative Documentation
=======================

Narrative documentation is like the page you are currently reading. It is only
loosely tied to a particular piece of code. Narrative documentation is meant for
providing overviews, background information, implementation details, etc.
Narrative documentation is built with Sphinx and is written using
Sphinx-flavored reStructuredText. Consequentially many of the reST conventions
from the API Documentation section carry over.

Compared to writing reST API documentation the biggest difference when writing
narrative documentation is that narrative documentation is typically partitioned
into parts, chapters, sections, etc. While reST doesn't particularly care what
characters you use to distinguish between headings for parts, chapters,
sections, etc. it is very common practice (stemming from Python's documentation
conventions) to obey:

- ``#`` with overline for part headings

  - We also use this for the package name on the main ``index.rst``

- ``*`` with overline for chapter headings
- ``=`` for sections
- ``-`` for subsections
- ``^`` for subsubsections
- ``"`` for paragraphs
- and you should seriously reevaluate your documentation if you need anything
  beyond that...

The distinction between what constitutes a part, chapter, etc. is a bit fuzzy,
but the general idea is that as you nest titles you rotate through the various
characters. Typically what this means is that you'll use ``#`` for titles on
``index.rst`` pages, ``*`` for titles of pages included from ``index.rst``
pages, and ``=``, ``-``, and ``^`` respectively for sections, subsections, and
subsections in the page included from the ``index.rst`` file.
