********************************
Writing Your Own CMake Functions
********************************

The main reason CMakePP can exist is that CMake allows users to write their own
functions. While the process of declaring a function is straightforward there
are some gotchas to keep in mind. This chapter focuses on avoiding those
gotchas.

Function vs. Macro
==================

CMake provides two types of user-defined functions "macros" and
"functions". The only difference is that "functions" create a new scope, whereas
"macros" do not. This is probably easiest to explain with an example:

.. code-block:: cmake

   function(a_fxn)
       set(my_x "Hello World")
   endfunction()

   macro(a_macro)
       set(my_x "Hello World")
   endmacro()

   set(my_x "")
   a_fxn()
   message("my_x = '${my_x}'") # Will print "my_x = ''"
   a_macro()
   message("my_x = '${my_x}'") # Will print "my_x = 'Hello World'"

When designing functionality for CMakePP you should primarily use functions to
avoid contaminating the caller's namespace. That said, there are some
circumstances where CMakePP developers will still want to use macros. Arguably,
the most common circumstance is to break up long functions into smaller units.
In this use case, which the macros are intended for use solely in the longer
function and thus the lack of an additional scope does not affect the caller of
the function because the macro's manipulations are contained within the
function's scope. Generally speaking, if you use a macro instead of a function
it is a good idea to explain why in the documentation.

Namespace Collisions
====================

CMake does not have the equivalent of C/C++'s one-definition rule, *e.g.*, the
following is perfectly valid CMake:

.. code-block:: cmake

   function(add_library)
       message("Look I overrode a native CMake command!!!")
   endfunction()

   add_library()                                 # Calls our add_library
   add_library(my_lib STATIC a_source_file.cpp)  # Still our add_library call

Note in particular that the last line will run just fine because CMake allows
you to pass in more arguments than just the positional ones (the extra arguments
get passed as ``${ARGN}``). It is thus essential that we avoid such collisions,
not just with CMake's native commands, but also with commands from third party
modules. The latter in particular is a tall order. The CMakePP solution is to
use a per module prefix. For example, in the CMakeTest repository we use the
prefix ``ct_``. While not foolproof, when combined with type checking, this
strategy should avoid many collisions, and raise errors for most of the
remaining such collisions.
