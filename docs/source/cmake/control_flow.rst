***********************
Control Flow Statements
***********************

Control flow statements are a key piece of almost all programming languages.
CMake includes support for ``if/elseif/else``, ``while``, and ``foreach``. For
the most part ``while`` behaves how you expect, once you understand ``if``, and
will not be covered in this chapter.

"if" Statements
===============

"if" statements in CMake are very tricky owing to their peculiar semantics and
rules. This section is dedicated to pointing out the quirks of "if" statements
and how to avoid them. This section is only focused on "if" statements
encountered during normal CMake execution.

.. warning::

   At least with CMake 3.15.3 the semantics for passing recognized booleans
   differ between normal CMake execution and CMake scripting mode (running CMake
   with the ``-P`` flag). More specifically in scripting mode booleans provided
   to functions are not recognized by "if" statements within those functions.
   The boolean values are instead treated like normal strings (as evidenced by
   the raised warning). For example:

   .. code-block::

    function(a_fxn x)
        if(${x})
            message("All good")
        else()
            message(FATAL_ERROR "what????")
        endif()
    endfunction()
    a_fxn(TRUE)

   will pass during normal CMake execution, but fail if CMake is run in
   scripting mode. It is not clear if this is a bug or a subtle difference
   between the two modes.

Evaluating Conditions
---------------------

"if" statements were written early in CMake's lifetime, before ``${}`` was
introduced and therefore have somewhat obscure semantics.  This subsection goes
through those semantics.

Since ``${}`` was not invented yet, it was decided that the "if" statement
automatically dereferences its argument, unless that argument is a recognized
boolean. In other words:

.. code-block:: cmake

   set(x FALSE)
   set(y x)

   if(y)
       message("The if clause")
   else()
       message("The else clause")
   endif()

   if(${y})
       message("The if clause")
   else()
       message("The else clause")
   endif()

will print "The if clause" and then the "The else clause". This is because the
first "if" statement checks that ``y`` has a non-false value, which it does
(its value is ``"x"``). The second statement checks that ``x`` has a non-false
value, which it does not (its value is ``FALSE``). In other words, the second
statement is **NOT** checking whether or not ``x`` is defined, but rather if
``${x}`` is true. The only time the variable does not get dereferenced is if it
is a recognized CMake boolean literal (you should never name your variables this
way...):

.. code-block:: cmake

   set(TRUE FALSE)

   if(TRUE)
       message("The if clause")
   else()
       message("The else clause")
   endif()

will trip the if-clause because CMake will not dereference the variable
``TRUE``.


Wrapping "if" Statements
------------------------

Several of the lower-level CMakePP functions look like:

.. code-block:: cmake

   cmakepp_fxn(<condition> <thing2do>)

where the idea is that based on the truthy-ness of the condition the function
does something. Under the hood the implementation of such functions inevitably
wraps a call to "if". This section focuses on the gotchas of implementing such
functions. For our purposes let's assume we are trying to write a function,
which prints the message if a condition is true. This looks like:

.. code-block:: cmake

   function(print_if_true condition msg)
       if(${condition})
           message(${msg})
       endif()
   endfunction()

So now we try it out with a few conditions:

.. code-block:: cmake

   print_if_true(TRUE "just a boolean")

As part of a normal CMake run this works fine; however, it fails if CMake is run
in scripting mode (I was using CMake 3.15.3 and am not sure if this is a bug or
some oddity of scripting mode; in scripting mode this somehow becomes "TRUE",
which trips a warning that if statement looks like ``if("TRUE")``).

Let's try a more complicated expression:

.. code-block:: cmake

   print_if_true("x STREQUAL x" "with a string comparison")

Using the rules of how if statements evaluate, we see this call evaluates to:

.. code-block:: cmake

   if("x STREQUAL x")
       ...
   endif()

which checks if ``${x STREQUAL x}`` evaluates to a non-false constant and it
fails (assuming you didn't set ``"x STREQUAL x"`` to a non-false constant). We
can fix that if we make the condition a list:

.. code-block:: cmake

   print_if_true("x;STREQUAL;x" "with a string comparison")

This will work with an arbitrarily complicated condition, so long as there are
no empty strings in it. The easiest way to deal with empty string (or variables
that may possibly be empty) is to add padding spaces:

.. code-block:: cmake

   print_if_true("${I_may_be_empty} ;STREQUAL; " "variable is empty")

Lists are also somewhat problematic, but the problem can be avoided by using
bracket arguments, for example:

.. code-block:: cmake

   print_if_true("[[1;2;3]];STREQUAL;[[1;2;3]]" "lists are equal")

Foreach Statements
==================

For looping in CMake one typically uses the ``foreach`` statement. This
statement works great if you need to loop over the elements in a CMake list. In
such cases looping is as simple as:

.. code-block:: cmake

   foreach(elem ${my_list})
      # Do stuff with element
   endforeach()

However, other looping modes are not so straightforward.

Iterating Over Ranges
---------------------

To iterate over a range one needs the starting value, the ending value, and the
increment (we ignore the increment for this section). When indexing starts at 0
it is common to specify ranges as half-open like :math:`[0, n)`, where :math:`n`
is the number of elements in the range, but :math:`n` is not in the range
itself. Indexing in CMake also starts at 0; however, CMake's ``foreach``
statements require you to specify closed ranges. As a closed range,
:math:`[0, n)` is :math:`[0, n-1]`, thus we need to provide ``foreach`` with
:math:`n-1`. In most languages this would amount to two extra key strokes (or
four with some padding spaces); however, in CMake we can not do the arithmetic
in-place (*i.e.* ``foreach(i RANGE n-1)`` is not valid). The result is that in
CMake one typically iterates over a range using boilerplate like:

.. code-block:: cmake

   math(EXPR last_index "<number_of_elements_in_range> - 1")
   foreach(index RANGE "${last_index}")
       list(GET element <list> "${index}")  # (or whatever gets index-th value)
       # Do stuff
   endforeach()


