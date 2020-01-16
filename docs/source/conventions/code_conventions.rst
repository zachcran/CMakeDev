****************
Code Conventions
****************

This page details the coding conventions used within the CMake project. We
specifically focus on the conventions to use when writing CMake/CMakePP code as
Python code should adhere to PEP-8.

Module Setup
============

CMake/CMakePP code is written in modules. A typical CMake module file should
look like:

.. code-block:: cmake

   #
   # 1. The license boilerplate header
   #

   include_guard()  # 2

   include(a_submodule)  # 3
   include(b_submodule)

  #[[[
  #
  # 4. Documentation comment for class/function/variable
  #
  #]]
  function(my_fxn)
      # Defined the function
  endfunction()

For the most part this follows the typical conventions in Python and C/C++. The
main pieces are:

1. All module files must start with the boilerplate license of the Apache 2.0
   license. To maintain uniformity please/copy paste this verbatim from another
   file.
2. The first actual command in a CMake module should always be
   ``include_guard()``

   - ``include_guard()`` was introduced in CMake 3.10 and serves the same
     purpose as ``#pragma once`` in C/C++, namely to avoid including the same
     module more than once, even if multiple modules attempt to include it.

3. You should include all CMake modules required to use your module.

   - Modules should be listed in alphabetic order
   - It should be possible to use your module simply by including it, *i.e.*,
     users should not have to include additional modules in order for your
     module to work
   - If your module depends on a module A, which in turn depends on B, you
     should directly include B in your module only if your module uses B too.

     - Using B to interface with A does not count as your module using B.

4. After the top matter, you should include your code. All code should have API
   documentation immediately proceeding it. The API documentation should follow
   CMakePP's documentation standards.

   - You can have multiple functions, classes, etc. in the same CMake module if
     you want.
   - Generally speaking CMake/CMakePP are very verbose languages, which can
     require a great deal of comments to understand quickly. For this reason
     it is often beneficial for readability to only include a single function or
     class in a module.

Additional considerations:

- Please limit your code to 80 characters per line.

  - There are plenty of StackOverflow and blog posts on why this is a good idea.
    To summarize them:

    - Ease of reading. The human eye gets tired quicker if it has to scroll
      horizontally too much.
    - Many people often have more than one source file open at a time. Using an
      IDE with a reasonable font size, two sources file side-by-side basically
      takes up an entire monitor if they are around 80 characters per line.
    - Easier to embed code in documents, emails, etc. without additional
      formatting.

  - The choice of 80 versus say 85 is somewhat arbitrary and is primarily made
    to adhere to usual conventions.

    - Another motivation for 80 is that in high-performance computing it is
      often convenient to edit a file from a terminal. For better or for worse,
      for legacy reasons terminals tend to be based on 80 characters.
