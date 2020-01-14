************************
Working With CMake Lists
************************

CMake lists are a pain point and should be avoided. That said, there are times
you need to work with them (for example when using native CMake functions, or in
low-level CMakePP routines). This page hopes to make working with CMake lists as
painless as possible.

List Gotchas
============

The biggest gotcha associated with CMake lists is the fact that they are just
strings separated by semicolons. What this means is they don't retain any sort
of nesting. For example:

.. code-block:: cmake

   set(a_list 1 2 3)
   set(b_list "${a_list}" "${a_list}" "${a_list}")
   message("${b_list}")  # prints "1;2;3;1;2;3;1;2;3"

If the intent is to set ``b_list`` to a list of lists this will fail. The print
statement shows why, namely CMake "flattened" the list. Instead of getting a
list whose elements are lists of three numbers, we get a list of nine numbers.
It is possible to preserve the nesting by escaping the semicolons:

.. code-block:: cmake

   set(a_list "1\;2\;3")
   set(b_list "${a_list}" "${a_list}" "${a_list}")
   message("${b_list}")  # prints "1\;2\;3;1\;2\;3;1\;2\;3"

Now the ``\;`` diglyph is a separator for elements in the nested lists and the
unescaped semicolons are separators for elements in the outer list. This can be
extended to arbitrary nestings, but is a particularly ugly means of doing so.

At first the nesting gotcha may not seem so bad since we rarely need to pass
two-dimensional lists in CMake; however, one needs to keep in mind that CMake
concatenates arguments to a function into a list in order to pass them. This is
perhaps easiest to see with an example. Consider the function:

.. code-block:: cmake

   function(a_fxn arg0 arg1 arg2)
       message("Provided arguments: ${arg0}, ${arg1}, ${arg2}, and ${ARGN}")
   endfunction()

which prints the three provided positional arguments and then the variadic
arguments separated by the word "and". If we invoke the function like:

.. code-block:: cmake

   a_fxn(1 2 3 4)

we get the output ``"Provided arguments: 1, 2, 3, and 4"``, as expected. If we
instead call it like:

.. code-block:: cmake

   set(a_list 1 2)
   a_fxn("${a_list}" 3 4 5)

we get ``"Provided arguments: 1, 2, 3, and 4;5"``. The user likely expected to
get ``"Provided arguments: 1;2, 3, 4, and 5"``. The reason for 4 and 5 being
passed as the variadic arguments is that ``a_fxn("${a_list}" 3 4 5)`` actually
looks like ``a_fxn(1;2;3;4;5)`` when ``a_fxn`` is invoked.

Passing Lists
=============

The previous section illustrated how passing lists to a function can be tricky.
Thankfully there is an easy to way to pass arbitrarily nested lists without
resorting to escape characters, pass them by reference. To do this we save each
nesting of the list into a variable and use the name of the variable (not the
list itself) when composing the next list. For example:

.. code-block:: cmake

   set(nesting00 1 2)
   set(nesting01 3 4)
   set(nesting0 nesting00 nesting01)
   set(nesting10 5 6)
   set(nesting11 7 8)
   set(nesting1 nesting10 nesting11)
   set(the_list nesting0 nesting1)

   function(fxn_taking_list a_list)
       message("List contents: ${${a_list}}")
   endfunction()

   fxn_taking_list(the_list)  # Prints "nesting0;nesting1"

The first seven lines make a nested-nested-list (it's a row-major 2x2x2 tensor
whose elements are the numbers 1 to 8 if that helps you wrap your mind around
the structure). Note that on lines 3 and 6 we build the nested-list by using
the names of the sublists and not the values, *i.e.*, we do **NOT** do:

.. code-block:: cmake

   set(nesting0 "${nesting00}" "${nesting01}")

We follow the same principle on line 7 where we put the nested-lists together to
make the nested-nested-list. The next thing to note is the function takes the
list by reference and not value, by this we mean we need a double dereference
(the ``${${a_list}}`` part) to get the value instead of the normal
``${a_list}``. This is because ``${a_list}`` evaluates to ``the_list``, which
then needs to be dereferenced again in order to get the list.

The drawback of this approach is that the function needs to know ahead of time
that it is getting a list by reference and it needs to know how deeply nested
the list is in order to actually retrieve values, as opposed to a sublist. For
functions designed to work with arbitrarily nested lists this can be remedied by
having the caller pass in the nesting. Attempting to dereference until an
empty string is found is not recommended as it becomes difficult to work with
slices of the list this way.

