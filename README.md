[![Actions Status](https://github.com/lizmat/String-Utils/actions/workflows/linux.yml/badge.svg)](https://github.com/lizmat/String-Utils/actions) [![Actions Status](https://github.com/lizmat/String-Utils/actions/workflows/macos.yml/badge.svg)](https://github.com/lizmat/String-Utils/actions) [![Actions Status](https://github.com/lizmat/String-Utils/actions/workflows/windows.yml/badge.svg)](https://github.com/lizmat/String-Utils/actions)

NAME
====

String::Utils - Provide some optimized string functions

SYNOPSIS
========

```raku
use String::Utils;

say abbrev(<yes no>).keys.sort;        # (n no y ye yes)

say after("foobar","foo");             # bar

say all-same("aaaaaa");                # "a"
say all-same("aaaaba");                # Nil
say all-same("");                      # Nil

say around("foobarbaz", "ob", "rb");   # foaz

say before("foobar","bar");            # foo

say between("foobarbaz","foo","baz");  # bar

say between-included("foobarbaz","oo","baz");  # oobarbaz

say chomp-needle("foobarbaz", "baz");  # foobar

say consists-of("aaabbcc", "abc");     # True
say consists-of("aaadbcc", "abc");     # False
say consists-of("", "abc");            # True

dd expand-tab("a\tbb\tccc",4);         # "a   bb  ccc"

say has-marks("foo👩🏽‍💻bar");             # False
say has-marks("fóöbar");               # True

say is-lowercase("foobar");            # True
say is-lowercase("FooBar");            # False
say is-lowercase("");                  # True

say is-sha1 "foo bar baz";             # False

say is-uppercase("FOOBAR");            # True
say is-uppercase("FooBar");            # False
say is-uppercase("");                  # True

say is-whitespace("\t \n");            # True
say is-whitespace("\ta\n");            # False
say is-whitespace("");                 # True

dd leading-whitespace(" \t foo");      # " \t "

say leaf <zip.txt zop.txt ff.txt>;     # .txt

say letters("//foo:bar");              # foobar

say ngram "foobar", 3;                 # foo oob oba bar

say nomark("élève");                   # eleve

say non-word "foobar";                 # False
say non-word "foo/bar";                # True

.say for paragraphs("a\n\nb");         # 0 => a␤2 => b␤
.say for paragraphs($path.IO.lines);   # …

my $string = "foo";
my $regex  = regexify($string, :ignorecase);
say "FOOBAR" ~~ $regex;                # ｢FOO｣

say root <abcd abce abde>;             # ab

say sha1("foo bar baz";                # C7567E8B39E...

say stem "foo.tar.gz";                 # foo
say stem "foo.tar.gz", 1;              # foo.tar

say text-from-url $url, :verbose;      # ...

dd trailing-whitespace("bar \t ");     # " \t "

say word-at("foo bar baz", 5);         # (4 3 1)

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

abbrev
------

```raku
say abbrev(<yes no>).keys.sort;       # (n no y ye yes)

say abbrev(<foo bar baz>).keys.sort;  # (bar baz f fo foo)
```

Takes 0 or more strings as arguments, and returns a `Map` with all shortest possible unambigious versions of the given strings as keys, and their associated original string as the value.

Inspired by Text::Abbrev module by KamilaBorowska.

after
-----

```raku
say after("foobar","foo");   # bar

say "foobar".&after("foo");  # bar

say after("foobar","goo");   # Nil
```

Return the string **after** a given string, or `Nil` if the given string could not be found. The equivalent of the stringification of `/ <?after foo> .* /`.

all-same
--------

```raku
say all-same("aaaaaa");                # "a"
say all-same("aaaaba");                # Nil
say all-same("");                      # Nil
```

If the given string consists of a single character, returns that character. Else returns `Nil`.

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

consists-of
-----------

```raku
say consists-of("aaabbcc", "abc");     # True
say consists-of("aaadbcc", "abc");     # False
say consists-of("", "abc");            # True
```

Returns a `Bool` indicating whether the string given as the first positional argument only consists of characters given as the second positional argument, or is empty.

describe-Version
----------------

```raku
say $*VM.version;                    # v2025.06.5.gb.1.c.74.b.8.d.8
say describe-Version($*VM.version);  # 2025.06-5-gb1c74b8d8
```

The `describe-Version` subroutine takes a `Version` object and returns a string in the "git describe" format.

expand-tab
----------

```raku
dd expand-tab("a\tbb\tccc",4);  # "a   bb  ccc"
```

Expand any tabs in a string (the first argument) to the given tab width (the second argument). If there are no tabs, then the given string will be returned unaltered.

If the tab width is **zero** or **negative**, will remove any tabs from the string. If the tab width is **one**, then all tabs will be replaced by spaces.

has-marks
---------

```raku
say has-marks("foo👩🏽‍💻bar");             # False
say has-marks("fóöbar");               # True
```

Returns a `Bool` indicating whether the given string contains any alphanumeric characters with marks (accents).

is-lowercase
------------

```raku
say is-lowercase("foobar");  # True
say is-lowercase("FooBar");  # False
say is-lowercase("");        # True
```

Returns a `Bool` indicating whether the string consists of just lowercase characters, or is empty.

is-sha1
-------

```raku
say is-sha1 "abcd abce abde";  # False
say is-sha1 "356A192B7913B04C54574D18C28D46E6395428AB";  # True
```

Return a `Bool` indicating whether the given string is a SHA1 string (40 chars and only containing 0123456789ABCDEF).

is-uppercase
------------

```raku
say is-uppercase("FOOBAR");  # True
say is-uppercase("FooBar");  # False
say is-uppercase("");        # True
```

Returns a `Bool` indicating whether the string consists of just uppercase characters, or is empty.

is-whitespace
-------------

```raku
say is-whitespace("\t \n");  # True
say is-whitespace("\ta\n");  # False
say is-whitespace("");       # True
```

Returns a `Bool` indicating whether the string consists of just whitespace characters, or is empty.

leading-whitespace
------------------

```raku
dd leading-whitespace("foo");      # ""
dd leading-whitespace(" \t foo");  # " \t "
dd leading-whitespace(" \t ");     # " \t "
```

Returns a `Str` containing any leading whitespace of the given string.

leaf
----

```raku
say leaf <zip.txt zop.txt ff.txt>;  # .txt
```

Return the common **end** of the given strings, or the empty string if no common string could be found. See also `root`.

letters
-------

```raku
say letters("//foo:bar");  # foobar
```

Returns all of the alphanumeric characters in the given string as a string.

ngram
-----

```raku
say ngram "foobar", 3;            # foo oob oba bar

say ngram "foobar", 4, :partial;  # foob ooba obar bar ar r
```

Return a sequence of substrings of the given size, while only moving up one position at a time in the original string. Optionally takes a `:partial` flag to also produce incomplete substrings at the end of the sequence.

nomark
------

```raku
say nomark("élève");  # eleve
```

Returns the given string with any diacritcs removed.

non-word
--------

```raku
say non-word "foobar";   # False

say non-word "foo/bar";  # True
```

Returns a `Bool` indicating whether the string contained **any** non-word characters.

paragraphs
----------

```raku
.say for paragraphs($path.IO.lines);   # …
.say for paragraphs("a\n\nb");         # 0 => a␤2 => b␤
.say for paragraphs("a\n\nb", 1);      # 1 => a␤3 => b␤
```

Lazily produces a `Seq` of `Pairs` with paragraphs from a `Seq` or string in which the key is the line number where the paragraph starts, and the value is the paragraph (without **last** trailing newline).

The optional second argument can be used to indicate the ordinal number of the first line in the string.

```raku
my class A is Pair { }
.say for paragraphs("a\n\nb", 1, :Pair(A));  # 1 => a␤␤3 => b␤
```

Also takes an optional named argument `:Pair` that indicates the class with which the objects should be created. This defailts to the core `Pair` class.

regexify
--------

```raku
my $string = "foo";
my $regex  = regexify($string, :ignorecase);
say "FOOBAR" ~~ $regex;  # ｢FOO｣
```

Produce a `Regex` object from a given string and modifiers. Note that this is similar to the `/ <$string> /` syntax. But opposed to that syntax, which interpolates the contents of the string **each time** the regex is executed, the `Regex` object returned by `regexify` is immutable.

The following modifiers are supported:

### i / ignorecase

```raku
# accept haystack if "bar" is found, regardless of case
my $regex = regexify("bar", :i);  # or :ignorecase
```

Allow characters to match even if they are of mixed case.

### smartcase

```raku
# accept haystack if "bar" is found, regardless of case
my &anycase = regexify("bar", :smartcase);

# accept haystack if "Bar" is found
my &exactcase = regexify("Bar", :smartcase);
```

If the needle is a string and does **not** contain any uppercase characters, then `ignorecase` semantics will be assumed.

### m / ignoremark

```raku
# accept haystack if "bar" is found, regardless of any accents
my &anycase = regexify("bar", :m);  # or :ignoremark
```

Allow characters to match even if they have accents (or not).

### smartmark

```raku
# accept haystack if "bar" is found, regardless of any accents
my &anymark = regexify("bar", :smartmark);

# accept haystack if "bår" is found
my &exactmark = regexify("bår", :smartmark);
```

If the needle is a string and does **not** contain any characters with accents, then `ignoremark` semantics will be assumed.

root
----

```raku
say root <abcd abce abde>;  # ab
```

Return the common **beginning** of the given strings, or the empty string if no common string could be found. See also `leaf`.

sha1
----

```raku
say sha1("foo bar baz";  # C7567E8B39E2428E38BF9C9226AC68DE4C67DC39
```

Returns a [`SHA1`](https://en.wikipedia.org/wiki/SHA-1) of the given string. It should only be used for simple identification uses, as it can no longer reliably serve in any cryptographic use.

stem
----

```raku
say stem "foo.tar.gz";     # foo
say stem "foo.tar.gz", 1;  # foo.tar
say stem "foo.tar.gz", *;  # foo
```

Return the stem of a string with all of its extensions removed. Optionally accepts a second argument indicating the number of extensions to be removed. This may be `*` (aka `Whatever`) to indicate to remove all extensions.

text-from-url
-------------

```raku
my $text = text-from-url $url, :verbose;
```

Returns the text found at the given URL, or `Nil` if the fetch of the text failed for some reason. Takes an optional `:verbose` named argument: if specified with a trueish value, will show any error output that was received on `STDERR`: defaults to False, to quietly just return `Nil` on error.

Assumes the `curl` command-line program is installed and a network connection is available.

trailing-whitespace
-------------------

```raku
dd trailing-whitespace("bar");      # ""
dd trailing-whitespace("bar \t ");  # " \t "
dd trailing-whitespace(" \t ");     # " \t "
```

Returns a `Str` containing any trailing whitespace of the given string.

word-at
-------

```raku
say word-at("foo bar baz", 5);  # (4 3 1)
```

Returns a `List` with the start position, the number of characters of the word, and the ordinal number of the word found in the given string at the given position, or directly before it (using `.words` semantics).

Returns `Empty` if no word could be found at the given position, or the position was out of range.

AUTHOR
======

Elizabeth Mattijsen <liz@raku.rocks>

Source can be located at: https://github.com/lizmat/String-Utils . Comments and Pull Requests are welcome.

If you like this module, or what I’m doing more generally, committing to a [small sponsorship](https://github.com/sponsors/lizmat/) would mean a great deal to me!

COPYRIGHT AND LICENSE
=====================

Copyright 2022, 2023, 2024, 2025 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

