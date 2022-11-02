[![Actions Status](https://github.com/lizmat/String-Utils/workflows/test/badge.svg)](https://github.com/lizmat/String-Utils/actions)

NAME
====

String::Utils - Provide some optimized string functions

SYNOPSIS
========

```raku
use String::Utils;

say before("foobar","bar");            # foo

say between("foobarbaz","foo","baz");  # bar

say between-included("foobarbaz","oo","baz");  # oobarbaz

say around("foobarbaz", "ob", "rb");   # foaz

say after("foobar","foo");             # bar

say chomp-needle("foobarbaz", "baz");  # foobar

say root <abcd abce abde>;             # ab

say leaf <zip.txt zop.txt ff.txt>;     # .txt

say is-sha1 "foo bar baz";             # False

say stem "foo.tar.gz";                 # foo
say stem "foo.tar.gz", 1;              # foo.tar

say ngram "foobar", 3;                 # foo oob oba bar

say non-word "foobar";                 # False
say non-word "foo/bar";                # True

say letters("//foo:bar");              # foobar

say has-marks("foo👩🏽‍💻bar");             # False
say has-marks("fóöbar");               # True

use String::Utils <before after>;  # only import "before" and "after"
```

DESCRIPTION
===========

String::Utils provides some simple string functions that are not (yet) provided by the core Raku Programming Language.

These functions are implemented **without** using regexes for speed.

SELECTIVE IMPORTING
===================

```raku
use String::Utils <before after>;  # only import "before" and "after"
```

By default all utility functions are exported. But you can limit this to the functions you actually need by specifying the names in the `use` statement.

To prevent name collisions and/or import any subroutine with a more memorable name, one can use the "original-name:known-as" syntax. A semi-colon in a specified string indicates the name by which the subroutine is known in this distribution, followed by the name with which it will be known in the lexical context in which the `use` command is executed.

```raku
use String::Utils <root:common-start>;  # import "root" as "common-start"

say common-start <abcd abce abde>;  # ab
```

SUBROUTINES
===========

after
-----

```raku
say after("foobar","foo");   # bar

say "foobar".&after("foo");  # bar

say after("foobar","goo");   # Nil
```

Return the string **after** a given string, or `Nil` if the given string could not be found. The equivalent of the stringification of `/ <?after foo> .* /`.

around
------

```raku
say around("foobarbaz","ob","rb");     # foaz

say "foobarbaz".&around("ob","rb");    # foaz

say around("foobarbaz","goo","baz");   # foobarbaz
```

Return the string **around** two given strings, or the string itself if either of the bounding strings could not be found. The equivalent of `.subst: / <?after ob> .*? <?before rb> /`.

before
------

```raku
say before("foobar","bar");   # foo

say "foobar".&before("bar");  # foo

say before("foobar","baz");   # Nil
```

Return the string **before** a given string, or `Nil` if the given string could not be found. The equivalent of the stringification of `/ .*? <?before bar> /`.

between
-------

```raku
say between("foobarbaz","foo","baz");   # bar

say "foobarbaz".&between("foo","baz");  # bar

say between("foobarbaz","goo","baz");   # Nil
```

Return the string **between** two given strings, or `Nil` if either of the bounding strings could not be found. The equivalent of the stringification of `/ <?after foo> .*? <?before baz> /`.

between-included
----------------

```raku
say between-included("foobarbaz","oo","baz");   # oobarbaz

say "foobarbaz".&between-included("oo","baz");  # oobarbaz

say between-included("foobarbaz","goo","baz");  # Nil
```

Return the string **between** two given strings **including** the given strings, or `Nil` if either of the bounding strings could not be found. The equivalent of the stringification of `/ o .*? baz /`.

chomp-needle
------------

```raku
say chomp-needle("foobarbaz","baz");   # foobar

say "foobarbaz".&chomp-needle("baz");  # foobar

say chomp-needle("foobarbaz","bar");   # foobarbaz
```

Return the string without the given target string at the end, or the string itself if the target string is not at the end. The equivalent of `.subst(/ baz $/)`.

root
----

```raku
say root <abcd abce abde>;  # ab
```

Return the common **beginning** of the given strings, or the empty string if no common string could be found. See also `leaf`.

leaf
----

```raku
say leaf <zip.txt zop.txt ff.txt>;  # .txt
```

Return the common **end** of the given strings, or the empty string if no common string could be found. See also `root`.

is-sha1
-------

```raku
say is-sha1 "abcd abce abde";  # False
say is-sha1 "356A192B7913B04C54574D18C28D46E6395428AB";  # True
```

Return a `Bool` indicating whether the given string is a SHA1 string (40 chars and only containing 0123456789ABCDEF).

stem
----

```raku
say stem "foo.tar.gz";     # foo
say stem "foo.tar.gz", 1;  # foo.tar
say stem "foo.tar.gz", *;  # foo
```

Return the stem of a string with all of its extensions removed. Optionally accepts a second argument indicating the number of extensions to be removed. This may be `*` (aka `Whatever`) to indicate to remove all extensions.

ngram
-----

```raku
say ngram "foobar", 3;            # foo oob oba bar

say ngram "foobar", 4, :partial;  # foob ooba obar bar ar r
```

Return a sequence of substrings of the given size, while only moving up one position at a time in the original string. Optionally takes a `:partial` flag to also produce incomplete substrings at the end of the sequence.

non-word
--------

```raku
say non-word "foobar";   # False

say non-word "foo/bar";  # True
```

Returns a `Bool` indicating whether the string contained **any** non-word characters.

letters
-------

```raku
say letters("//foo:bar");  # foobar
```

Returns all of the alphanumeric characters in the given string as a string.

has-marks
---------

```raku
say has-marks("foo👩🏽‍💻bar");             # False
say has-marks("fóöbar");               # True
```

Returns a `Bool` indicating whether the given string contains any alphanumeric characters with marks (accents).

AUTHOR
======

Elizabeth Mattijsen <liz@raku.rocks>

Source can be located at: https://github.com/lizmat/String-Utils . Comments and Pull Requests are welcome.

If you like this module, or what I’m doing more generally, committing to a [small sponsorship](https://github.com/sponsors/lizmat/) would mean a great deal to me!

COPYRIGHT AND LICENSE
=====================

Copyright 2022 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

