# Since this distribution is about providing optimized functionality
# that can also be achieved by e.g. using regular expressions, it was decided
# to use NQP in here.  All of these subroutines could easily be rewritten
# in pure Raku if necessary, should that be needed for Raku implementations
# that are not based on NQP.
use nqp;

my sub between(str $string, str $before, str $after) is export {
    nqp::if(
      nqp::iseq_i((my int $left = nqp::index($string,$before)),-1),
      Nil,
      nqp::if(
        nqp::iseq_i(
          (my int $right = nqp::index(
            $string,$after,(my $offset = nqp::add_i($left,nqp::chars($before)))
          )),
          -1
        ),
        Nil,
        nqp::substr($string,$offset,nqp::sub_i($right,$offset))
      )
    )
}

my sub between-included(str $string, str $before, str $after) is export {
    nqp::if(
      nqp::iseq_i((my int $left = nqp::index($string,$before)),-1),
      Nil,
      nqp::if(
        nqp::iseq_i(
          (my int $right = nqp::index(
            $string,$after,nqp::add_i($left,nqp::chars($before))
          )),
          -1
        ),
        Nil,
        nqp::substr(
          $string,
          $left,
          nqp::sub_i(nqp::add_i($right,nqp::chars($after)),$left)
        )
      )
    )
}

my sub around(str $string, str $before, str $after) is export {
    nqp::if(
      nqp::iseq_i((my int $left = nqp::index($string,$before)),-1),
      $string,
      nqp::if(
        nqp::iseq_i(
          (my int $right = nqp::index(
            $string,$after,nqp::add_i($left,nqp::chars($before))
          )),
          -1
        ),
        $string,
        nqp::concat(
          nqp::substr($string,0,$left),
          nqp::substr($string,nqp::add_i($right,nqp::chars($after)))
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

my uint32 @empty;
my sub root(*@_) is export {
    my str $base = @_.shift.Str;

    my @same := nqp::strtocodes(
      $base,nqp::const::NORMALIZE_NFC,nqp::create(array[uint32])
    );

    nqp::while(
      nqp::elems(@same) && @_,
      nqp::stmts(
        (my @next := nqp::strtocodes(
          @_.shift.Str,nqp::const::NORMALIZE_NFC,nqp::create(array[uint32])
        )),
        (my int $i = -1),
        nqp::while(
          nqp::islt_i(($i = nqp::add_i($i,1)),nqp::elems(@same)),
          nqp::if(
            nqp::isne_i(nqp::atpos_i(@same,$i),nqp::atpos_i(@next,$i)),
            nqp::splice(@same,@empty,$i,nqp::sub_i(nqp::elems(@same),$i))
          )
        )
      )
    );

    nqp::substr($base, 0, nqp::elems(@same))
}

my sub chomp-needle(str $haystack, str $needle) is export {
    my int $offset = nqp::sub_i(nqp::chars($haystack),nqp::chars($needle));
    nqp::eqat($haystack,$needle,$offset)
      ?? nqp::substr($haystack,0,$offset)
      !! $haystack
}

=begin pod

=head1 NAME

String::Utils - Provide some optimized string functions

=head1 SYNOPSIS

=begin code :lang<raku>

use String::Utils;

say before("foobar","bar");            # foo

say between("foobarbaz","foo","baz");  # bar

say between-included("foobarbaz","oo","baz");  # oobarbaz

say around("foobarbaz", "ob", "rb");   # foaz

say after("foobar","foo");             # bar

say chomp-needle("foobarbaz", "baz");  # foobar

say root <abcd abce abde>;             # ab

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

=head2 around

=begin code :lang<raku>

say around("foobarbaz","ob","rb");     # foaz

say "foobarbaz".&around("ob","rb");    # foaz

say around("foobarbaz","goo","baz");   # foobarbaz

=end code

Return the string B<around> two given strings, or the string itself if either
of the bounding strings could not be found.  The equivalent of
C<.subst: / <?after ob> .*? <?before rb> />.

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

=head2 between-included

=begin code :lang<raku>

say between-included("foobarbaz","oo","baz");   # oobarbaz

say "foobarbaz".&between-included("oo","baz");  # oobarbaz

say between-included("foobarbaz","goo","baz");  # Nil

=end code

Return the string B<between> two given strings B<including> the given strings,
or C<Nil> if either of the bounding strings could not be found.  The equivalent
of the stringification of C</ o .*? baz />.

=head2 chomp-needle

=begin code :lang<raku>

say chomp-needle("foobarbaz","baz");   # foobar

say "foobarbaz".&chomp-needle("baz");  # foobar

say chomp-needle("foobarbaz","bar");   # foobarbaz

=end code

Return the string B<between> two given strings B<including> the given strings,
or C<Nil> if either of the bounding strings could not be found.  The equivalent
of the stringification of C</ .* <?before baz $> />.

=head2 root

=begin code :lang<raku>

say root <abcd abce abde>;  # ab

=end code

Return the common root of the given strings, or the empty string if no
common string could be found.

=head1 AUTHOR

Elizabeth Mattijsen <liz@raku.rocks>

Source can be located at: https://github.com/lizmat/String-Utils . Comments and
Pull Requests are welcome.

=head1 COPYRIGHT AND LICENSE

Copyright 2022 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod

# vim: expandtab shiftwidth=4
