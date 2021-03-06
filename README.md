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
```

DESCRIPTION
===========

String::Utils provides some simple string functions that are not (yet) provided by the core Raku Programming Language.

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

Return the string **between** two given strings **including** the given strings, or `Nil` if either of the bounding strings could not be found. The equivalent of the stringification of `/ .* <?before baz $> /`.

root
----

```raku
say root <abcd abce abde>;  # ab
```

Return the common root of the given strings, or the empty string if no common string could be found.

AUTHOR
======

Elizabeth Mattijsen <liz@raku.rocks>

Source can be located at: https://github.com/lizmat/String-Utils . Comments and Pull Requests are welcome.

COPYRIGHT AND LICENSE
=====================

Copyright 2022 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

