******************************
Callbacks and Lambdas in CMake
******************************

Callbacks are functions which are provided to another function as input. This
differs from a typical nested function call in that it is possible to change the
"value" of a callback at runtime. Put another way, nested function calls can be
thought of as hard-coded callbacks. Lambdas are functions that are written
on-the-fly and using the runtime state of the program in their definitions.
Lambdas are almost always used as callbacks hence their relevance to the present
discussion. Supporting callbacks and lambdas greatly facilitates generic
programming. CMake does not natively support callbacks, but it does natively
support lambdas (users can declare functions and macros almost anywhere);
however, without callback support these lambdas must be run in-place and can not
be passed to functions, which largely defeats the purpose of a lambda. This
chapter focuses on techniques to implement callbacks in CMake.

Prerequisites
=============

Before we describe some of the solutions out there it is worth explicitly noting
some points about the CMake language so that we understand the limitations the
patterns are constrained by.

CMake Function Names Can NOT be Variables
-----------------------------------------

As the subsection title says CMake does not allow function names to be
variables. Specifically, the following is **NOT** valid CMake:

.. code-block:: cmake

   function(my_fxn1)
   endfunction()

   function(my_fxn2)
   endfunction()

   set(fxn_name my_fxn1)
   if(some_condition)
       set(fxn_name my_fxn2)
   endif()

   ${fxn_name}()

Here the intent is that we default to calling ``my_fxn1``, but if a certain
condition is met, ``some_condition``, we want to call ``my_fxn2``. Everything is
valid CMake until the last line; CMake does **NOT** allow us to get the
function's name from a variable. CMake also does not allow any part of the
function's name to come from a variable, *i.e.*, this is **NOT** valid either:

.. code-block:: cmake

   function(is_valid_cxx_code code)
       # Check if ${code} is valid C++
   endfunction()

   function(is_valid_python_code code)
       # Check if ${code} is valid Python
   endfunction()

   set(lang cxx)

   is_valid_${lang}_code("x = [y in range(3)]")


If by some chance either of these restrictions are removed in a later release of
CMake this chapter becomes nothing more than a historical curiosity.

CMake's include Command
-----------------------

While there is a tendency to group all calls to CMake's native ``include``
command at the top of a file, the reality is these calls can be used almost
anywhere. Of particular relevance ``include`` can be used in a function like:

.. code-block:: cmake

   function(my_fxn)
       include(CMakeDependentOption)
       cmake_dependent_option(...)
   endfunction()

   my_fxn()

This code writes a function, which includes the ``CMakeDependentOption`` module
(the module facilitates declaring options that depend on other options) and then
calls the ``cmake_dependent_option`` function introduced by that module. Next
this code snippet calls the function we just defined.

The arguments to ``include``can be a variable. For example:

.. code-block:: cmake

   set(file_to_include a/path/to/a/CMake/module)
   include(${file_to_include})

is perfectly acceptable CMake code.

CMake's Function Command
------------------------

Along the same lines of the ``include`` subsection above, it is worth noting
that when defining a function the name can be a variable. For example:

.. code-block:: cmake

   set(fxn_name "my_fxn")
   function(${fxn_name})
       ...
   endfunction()

allows us to declare a function with a variable name. In fact, the entire
signature can be a variable:

.. code-block:: cmake

   set(fxn_sig my_fxn arg1 arg2)
   function(${fxn_sig})
       ...
   endfunction()

declares a function ``my_fxn`` which takes two positional arguments named
``arg1`` and ``arg2``.

That said, CMake will not allow the body of the ``function`` command to come
from a variable, in other words the following is **NOT** valid CMake:

.. code-block:: cmake

   set(fxn_contents "message(hello world)")
   function(my_fxn)
       ${fxn_contents}
   endfunction()



Dispatch
========

The dispatch pattern can be used for callbacks when the list of possible
callbacks is explicitly known and can be enumerated while writing the file. Say
we have three possible functions we may want to call ``fxn1``, ``fxn2``, and
``fxn3``, the dispatch pattern looks like:

.. code-block:: cmake

   function(call_a_fxn fxn_name)
       if("${fxn_name}" STREQUAL "fxn1")
           fxn1()
       elseif("${fxn_name}" STREQUAL "fxn2")
           fxn2()
       elseif("${fxn_name}" STREQUAL "fxn3")
           fxn3()
       else()
           message(FATAL_ERROR "Function ${fxn_name} not found."
       endif()
    endfunction()

   # Call fxn2 for example
   call_a_fxn(fxn2)

The code should be self-explanatory. Arguments to functions in the dispatch
pattern are best treated as kwargs unless all functions have the same exact
signature.

Admittedly this pattern does not actually implement callbacks, rather it
simulates them. By itself this pattern is only feasible when the number of
"callbacks" is small and known when ``call_a_fxn`` is being written. It's
important to note that this solution introduces a layer of indirection, but does
not require writing a file to disk (you likely will have to read include files
for the various functions you dispatch among).

Initializer Function Pattern
============================

I first saw this named pattern in the
`CMake++ <https://github.com/toeb/cmakepp>`_ library. The essence of this
pattern is that we generate an implementation file on-the-fly, and then include
that file run the contents. In CMake++ the pattern works by assuming we have the
code we want to call in a string. CMake++ then defines a function ``eval`` like:

.. code-block:: cmake

   function(eval contents)
       set(temp_file path/where/temp/file/should/go)

       file(
           WRITE ${temp_file}
           "function(eval contents)
                file(WRITE ${temp_file} \"\${contents}\")
                include(${temp_file})
            endfunction()"
       )
       include(${temp_file})
       eval("${contents}")
   endfunction()

``eval`` can then be used like:

.. code-block:: cmake

   eval("message(\"hello world\")")

.. note::

   This code is actually quite dense, this note provides a breakdown of how it
   works.

   1. User calls ``eval`` with the contents they want to run.

      - Call to ``eval`` happens in scope ``A``
      - Inside ``eval`` is scope ``A::B``

   2. ``A::eval`` writes a second version of ``eval`` to a temporary file.
   3. ``A::eval`` includes the temporary file

      - Including file runs it, defining a new version of ``eval`` in scope
        ``A::B``

   4. ``A::eval`` runs ``A::B::eval``

      - Scope inside ``A::B::eval`` is ``A::B::C``

   5. ``A::B::eval`` writes the contents to a temporary file

      - Use the same temporary file because we don't need the original anymore

   6. ``A::B::eval`` includes the new temporary file
   7. The user's contents run in scope ``A::B::C``

      - Means ``set(... PARENT_SCOPE)`` only returns to scope ``A::B``

   You may be curious what happens if you do not nest the file writes in
   ``eval``. If you do not nest the file writes then only first call will work.
   For example, without nesting the file writes:

   .. code-block:: cmake

      eval("message(\"hello world\")")
      eval("message(\"42\")")

   will print ``"hello world"`` twice. This is because ``A::B::eval``'s
   definition actually replaces ``A::eval``.

This pattern is expensive in terms of computational resources as it involves two
file reads and two file writes. It also requires special attention if it is
going to be used in parallel as it is quite easy for multiple calls to overwrite
each other's temporary files. As written the first call to ``eval`` can not
return variables (subsequent calls can) since the content is actually run two
scopes down.

It is possible to simplify the above implementation:

.. code-block:: cmake

   function(eval contents)
       set(temp_file path/for/temporary/file)

       file(WRITE ${temp_file} "${contents}")
       include(${temp_file})
   endfunction()

This implementation does the same thing as CMake++'s ``eval`` with less function
calls and I/O. This implementation also has the added benefit of only
introducing one nested scope on all calls, thus we can return variables like:

.. code-block::

   eval("set(x \"hello world\")")
   message("x == ${x}")  # Will print "x == hello world"

A major disadvantage of the ``eval`` calls (both CMake++ and our optimized form)
is that the code to run has to be provided as a string. As shown in the code
examples, this means that special characters, like ``"`` and ``;``, will need
escaped, which is error-prone and tedious.

Visitor Pattern
===============

This pattern works by agreeing on the name of the callback and its signature.
For example, say we are writing a function ``my_fxn`` which generates two
variables and needs to compare them. Since it is reasonable that the user may
want to use a custom comparison operation, we decide that our function should
take a callback to do the comparison. By convention we agree that the callback
is named ``compare_my_variables`` and has a signature like:

.. code-block:: cmake

   compare_my_variables(<result> <var1> <var2>)

we can then write our ``my_fxn`` function like:

.. code-block:: cmake

   function(my_fxn comparison_file)
       # Generate these variables somehow
       set(var1 foo)
       set(var2 bar)
       include(${comparison_file})
       compare_my_variables(result ${var1} ${var2})
   endfunction()

and this is used like:

.. code-block:: cmake

   my_fxn(path/to/comparison_file)

If we think of the CMake module as an object and the function in the module as a
method, this pattern looks a lot like the visitor pattern (one could argue it is
actually duck typing, since the visitor pattern usually has a common base class,
but oh well).
