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

Returning Values
================

Unfortunately, CMake does not allow functions or macros to return values in the
traditional sense, that is to say the following is not valid CMake:

.. code-block:: cmake

   result = a_fxn(an_argument)

The only way to return values from a CMake function/macro is to set the value in
the parent scope (for functions; for macros all values are already accessible
from outside the macro). Historically this has been done by standardizing names.
For example, many of the older ``FindXXX.cmake`` modules return their values by
setting variables like ``XXX_INCLUDE_DIRS`` and the like. This is considered bad
practice now and should be avoided. The modern way to return values is to ask
the caller for an identifier and then use that identifier to return the result.
For example:

.. code-block:: cmake

   function(say_hello identifier_to_use)
       set("${identifier_to_use}" "Hello World" PARENT_SCOPE)
   end_function()

   say_hello(result)
   message("Value returned : ${result}")  # Will be "Hello World"

This pattern allows the caller to specify the variable to use and avoids the
callee accidentally overwriting state in the caller's scope (a somewhat common
problem of older, poorly written ``FindXXX.cmake`` modules which have a tendency
to clobber variables like ``CMAKE_CXX_FLAGS``).

For functions with multiple return points the above pattern becomes:

.. code-block:: cmake

   function(say_hello result who_to_say_hi_to)
       if("${who_to_say_hi_to}" STREQUAL "Bill")
           set("${result}" "I guess I will say hello to Bill" PARENT_SCOPE)
           return()
       endif()
       set("${result}" "Hello World" PARENT_SCOPE)
   endfunction()

Of note you need to include the ``return()`` command which returns control to
the caller (otherwise control will continue after the "if"-statement). These
scenarios occur often enough that CMakePP includes the ``cpp_return`` function
which if called like: ``cpp_return(identifier)`` will set ``identifier`` in the
parent scope to the value ``${identifier}`` and return control to the caller.

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

Variable Collisions
===================

Even though functions create scope you have to be careful when your functions
take identifiers. Consider this somewhat contrived example:

.. code-block:: cmake

   # Sets the identifier to 3
   function(return_3 result)
       set(${result} 3 PARENT_SCOPE)
   endfunction()

   # Sets the identifier to 32
   function(return_32 input)
       set(result 2)
       return_3(${input})
       set(${input} "${${input}}${result}" PARENT_SCOPE)
   endfunction()

   return_32(var)
   message("Contents: ${var}")  # prints "32"
   return_32(result)
   message("Contents: ${result}")  # prints "33"

We define two functions. The first one takes an identifier and sets its value to
3. The second one's intent is to set an identifier to the value 324 in a
somewhat convoluted manner by:

1. Setting a temporary variable ``result`` to 2,
2. having the ``return_3`` set the provided identifier to 3, and
3. finally concatenates the identifier's value with the temporary's value.

As long as the caller of ``return_32`` doesn't pass in an identifier named
``result``, ``return_32`` works correctly. If the caller does decide to call
their identifier ``result``, then the call to ``return_3`` in ``return_32``
overwrites the temporary of the same name so that the result of ``return_32`` is
actually ``33``.

While this example may seem contrived, one of the dangers of having to pass an
identifier in to a function in order to get a return is that if that identifier
clashes with any temporaries they get overridden. Particularly for common,
simple variable names (like ``result``) the caller picking an identifier
identical to your temporary happens more often than you might think (especially
when the same programmer wrote all the functions on the stack). To mitigate
this, it's common to prefix function variable names with ``_`` characters, the
idea being that users writing CMake are unlikely to declare variable names that
start with such characters. The problem is that in a framework like CMakePP we
end up nesting so many developer functions it's actually quite likely for the
underscore prefixed names to clash too. Our solution is to mangle the name of
the function into the variable as well. While not foolproof it does help.
