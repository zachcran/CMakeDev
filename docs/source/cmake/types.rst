*********************
CMake Intrinsic Types
*********************

Enumerating the intrinsic types in CMake is a bit fuzzy because at some level
CMake only has one type, a string. Depending on the context that string is then
lexically converted to another type. The purpose of this chapter is to document
the lexical conversions that CMake natively supports. For all intents and
purposes the resulting list of supported lexical conversions can be taken as the
set of intrinsic types that CMake supports.

Strings
=======

Typically in CMake one thinks of a string as being defined with double quotes,
for example in something like:

.. code-block:: cmake

   set(my_variable "Hello World")

we think of ``"Hello World"`` as being a string. In truth everything between the
parenthesis is considered a string by CMake, regardless of whether or not it is
in double quotes. This means that ``my_variable`` is also a string in the above
example. Double quotes in CMake serve two purpose: to partition strings and to
keep lists together (*vide infra*). With respect to the first use case, by
default CMake assumes that individual strings are partitioned by white space,
which is to say that:

.. code-block:: cmake

   set(my_variable Hello World)

is interpreted by CMake as passing three strings to the ``set`` command:
``"my_variable"``, ``"Hello"``, and ``"World"``. By using double quotes in our
first example, we told CMake that it should consider ``"Hello World"`` to be a
single string. We'll cover lists below.

Booleans
========

In CMake the literal strings ``ON``, ``YES``, ``TRUE``, and ``Y`` have special
interpretations as being boolean objects with a true value, whereas the literals
``OFF``, ``NO``, ``FALSE``, ``N``, and ``NOTFOUND`` have special interpretations
as being boolean objects with false values. CMake also considers any non-zero
number to be true and zero to be false; however, such literals are better
characterized as integers, which can be converted to booleans, than outright
booleans.

Numbers
=======

CMake is capable of lexical casting strings to both integer and floating point
numbers. Since CMake predominately serves as a procedural language, numbers do
not come up all that often. When numbers are needed it is almost always integers
in the context of indexing. It is worth noting that CMake only supports
mathematical operations on numbers through the ``math`` command.


Identifiers
===========

Identifiers in CMake are variable names. While it may seem odd to consider an
identifier as a type, the reality is that they play a role akin to pointers in
C/C++. Identifiers are "dereferenced" using ``${}``. For example:

.. code-block:: cmake

   message("${an_identifier}")

will print the contents held by the identifier ``"an_identifier"``. One
important gotcha concerning identifiers concerns function boundaries. CMake
functions do not have the ability to return values in the normal sense, *i.e.*,

.. code-block:: cmake

   x = some_cmake_function()

is not valid CMake code. If ``some_cmake_function()`` returns a value, best
CMake practice is to make it take the identifier to hold the return as an
argument, *i.e.*:

.. code-block:: cmake

   some_cmake_function(x)  # Returns by setting x to the return value
   message("The value of ${x}")

Unlike C/C++ where ``some_cmake_function`` would be declared something like
``some_cmake_function(T* input)``, in CMake there is no equivalent ``*`` syntax
to signal that the argument to ``some_cmake_function`` should be an identifier.
Making matters worse CMake lets you do things like:

.. code-block:: cmake

   set(TRUE "Hello World")
   message("${TRUE}")

so if you accidentally pass a value to our hypothetical ``some_cmake_function``,
and not an identifier, there's a good chance you won't trip an error. Thus it's
crucial that the documentation for a function clearly state when it takes a
value and when it takes an identifier.

Generator Expressions
=====================

Generator expressions are a bit of an advanced feature. They can be thought of
as statements that are evaluated during the generation phase. They look like
``$<...>``. Since they are evaluated during the generation phase, they tend to
play a minor role in CMakePP code, which runs during the configuration phase.

Targets
=======

Targets are the closest thing native CMake has to objects. When you run a
command like:

.. code-block:: cmake

   add_library(my_library ...)

it makes the string ``my_library`` into a target. For all intents and purposes
``my_library`` is the "this" pointer of the resulting target.

File Paths
==========

File paths are arguably just strings with ``/`` characters in them (CMake uses
``/`` characters to separate directories regardless of the operating system).
Generally speaking file paths in CMake should always be absolute (relative to
the filesystem root) and not relative. Most native CMake functions require
absolute paths, but most will not enforce them. CMake has builtin functionality
for making paths absolute that should be used. Said functionality is operating
system agnostic.

Lists
=====

Lists are simply strings with ``;`` characters between entries. For better or
for worse, the CMake parser contextually will unpack lists in certain
circumstances. For example:

.. code-block:: cmake

   set(args_for_function arg1 arg2 arg3 arg4)
   a_fxn(${args_for_function})

will call ``a_fxn`` with a call that looks like ``a_fxn(arg1 arg2 arg3 arg4)``.
We can keep the list together by using double quotes.

.. code-block:: cmake

   set(args_for_function arg1 arg2 arg3 arg4)
   a_fxn("${args_for_function}")

will call ``a_fxn`` with a call that looks like
``a_fxn("arg1;arg2;arg3;arg4")``.

There are many gotchas associated with CMake's native lists, the most common one
is the fact that CMake does not support nested lists without some difficulty. In
particular this comes into play when you pass lists to native CMake functions
which accept their arguments via variadic arguments (most notably as keywords).
Keyword accepting functions are essentially defined akin to:

.. code-block:: cmake

   function(my_kwargs_fxn)
        cmake_parse_arguments(
            a_prefix "${options}" "${one_value}" "${multi_value}" ${ARGN}
        )
        # Do stuff with the kwargs
   end_function()

Here ``a_prefix`` is used to namespace protect the resulting variables, and
``${options}``, ``${one_value}``, and ``${multi_value}`` are lists of recognized
keywords separated by what sort of values they should take. The important point
is that all of the keywords and associated values that you pass into
``my_kwargs_fxn`` get put into the list ``${ARGN}``. Thus a call like:

.. code-block:: cmake

   execute_process(COMMAND cmake -DCMAKE_MODULE_PATH=${CMAKE_MODULE_PATH})

results in an ``${ARGN}`` like
``COMMAND;cmake;-DCMAKE_MODULE_PATH=path1;path2``. Basically the nested list
structure gets destroyed. To preserve the nested list structure you need to
escape the semicolons in ``${CMAKE_MODULE_PATH}`` (replace them with ``\;``).
Making matters more fun, the escapes are usually only good for one function
call. So if your list actually needs to be forwarded again from within the
function (and assuming the function isn't coded to protect the semicolons)
you'll need to replace the semicolons in ``${CMAKE_MODULE_PATH}`` with
``\\\;`` (think of this as ``(\\)(\;)``, the first part makes sure a ``\``
survives the first call and the second part makes sure the semicolon doesn't get
swallowed by the first call).  Forwarding lists is nasty business and should be
avoided at all costs.
