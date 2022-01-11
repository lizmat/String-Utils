# Since this distribution is about providing optimized functionality
# that can also be achieved by using regular expressions, it was decided
# to use NQP in here.  All of these subroutines could easily be rewritten
# in pure Raku if necessary, should that be needed for Raku implementations
# that are not based on NQP.
use nqp;

my sub between(str $string, str $before, str $after) is export {
    nqp::if(
      nqp::iseq_i((my int $left = nqp::index($string,$before)),-1),
      Nil,
      nqp::if(
        nqp::iseq_i((my int $right = nqp::index($string,$after,$left)),-1),
        Nil,
        nqp::stmts(
          (my int $offset = $left + nqp::chars($before)),
          nqp::substr($string,$offset,nqp::sub_i($right,$offset))
        )
      )
    )
}

my sub before(str $string, str $before) is export {
    nqp::iseq_i((my int $left = nqp::index($string,$before)),-1)
      ?? Nil
      !! nqp::substr($string,0,$left)
}

my sub after(str $string, str $after) is export {
    nqp::iseq_i((my int $right = nqp::index($string,$after)),-1)
      ?? Nil
      !! nqp::substr($string,nqp::add_i($right,nqp::chars($after)))
}

=begin pod

=head1 NAME

String::Utils - Provide some optimized string functions

=head1 SYNOPSIS

=begin code :lang<raku>

use String::Utils;

say before("foobar","bar");            # foo

say between("foobarbaz","foo","baz");  # bar

say after("foobar","foo");             # bar

=end code

=head1 DESCRIPTION

String::Utils provides some simple string functions that are not (yet)
provided by the core Raku Programming Language.

=head1 SUBROUTINES

=head2 after

=begin code :lang<raku>

say after("foobar","foo");   # bar

say "foobar".&after("foo");  # bar

say after("foobar","goo");   # Nil

=end code

Return the string B<after> a given string, or C<Nil> if the given string could
not be found.  The equivalent of the stringification of C</ <?after foo> .* />.

=head2 before

=begin code :lang<raku>

say before("foobar","bar");   # foo

say "foobar".&before("bar");  # foo

say before("foobar","baz");   # Nil

=end code

Return the string B<before> a given string, or C<Nil> if the given string could
not be found.  The equivalent of the stringification of
C</ .*? <?before bar> />.

=head2 between

=begin code :lang<raku>

say between("foobarbaz","foo","baz");   # bar

say "foobarbaz".&between("foo","baz");  # bar

say between("foobarbaz","goo","baz");   # Nil

=end code

Return the string B<between> two given strings, or C<Nil> if either of the
bounding strings could not be found.  The equivalent of the stringification of
C</ <?after foo> .*? <?before baz> />.

=head1 AUTHOR

Elizabeth Mattijsen <liz@raku.rocks>

Source can be located at: https://github.com/lizmat/String-Utils . Comments and
Pull Requests are welcome.

=head1 COPYRIGHT AND LICENSE

Copyright 2022 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod

# vim: expandtab shiftwidth=4
