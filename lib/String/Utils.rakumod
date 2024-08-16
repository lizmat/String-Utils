# Since this distribution is about providing optimized functionality
# that can also be achieved by e.g. using regular expressions, it was decided
# to use NQP in here.  All of these subroutines could easily be rewritten
# in pure Raku if necessary, should that be needed for Raku implementations
# that are not based on NQP.
use nqp;

my sub between(str $string, str $before, str $after) {
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

my sub between-included(str $string, str $before, str $after) {
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

my sub around(str $string, str $before, str $after) {
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

my sub before(str $string, str $before) {
    nqp::iseq_i((my int $left = nqp::index($string,$before)),-1)
      ?? Nil
      !! nqp::substr($string,0,$left)
}

my sub after(str $string, str $after) {
    nqp::iseq_i((my int $right = nqp::index($string,$after)),-1)
      ?? Nil
      !! nqp::substr($string,nqp::add_i($right,nqp::chars($after)))
}

my sub root(*@s) {
    if @s > 1 {
        my str $base = @s.shift.Str;
        my $same := nqp::clone(nqp::strtocodes(  # MUST be a clone
          $base,nqp::const::NORMALIZE_NFC,nqp::create(array[uint32])
        ));
        my int $elems = nqp::elems($same);
        my $next := nqp::create(array[uint32]);

        nqp::while(
          $elems && @s,
          nqp::stmts(
            nqp::strtocodes(@s.shift.Str,nqp::const::NORMALIZE_NFC,$next),
            (my int $i = -1),
            nqp::while(
              nqp::islt_i(++$i,$elems),
              nqp::if(
                nqp::isne_i(nqp::atpos_i($same,$i),nqp::atpos_i($next,$i)),
                nqp::setelems($same, $elems = $i)
              )
            )
          )
        );

        nqp::substr($base, 0, $elems)
    }
    else {
        @s.head // ""
    }
}

my sub leaf(*@s) {
    if @s > 1 {
        my str $base = nqp::flip(@s.shift.Str);
        my $same := nqp::clone(nqp::strtocodes(  # MUST be a clone
          $base,nqp::const::NORMALIZE_NFC,nqp::create(array[uint32])
        ));
        my int $elems = nqp::elems($same);
        my $next := nqp::create(array[uint32]);

        nqp::while(
          $elems && @s,
          nqp::stmts(
            nqp::strtocodes(
              nqp::flip(@s.shift.Str),nqp::const::NORMALIZE_NFC,$next
            ),
            (my int $i = -1),
            nqp::while(
              nqp::islt_i(++$i,$elems),
              nqp::if(
                nqp::isne_i(nqp::atpos_i($same,$i),nqp::atpos_i($next,$i)),
                nqp::setelems($same, $elems = $i)
              )
            )
          )
        );

        nqp::flip(nqp::substr($base, 0, $elems))
    }
    else {
        @s.head // ""
    }
}

my sub chomp-needle(str $haystack, str $needle) {
    my int $offset = nqp::sub_i(nqp::chars($haystack),nqp::chars($needle));
    nqp::eqat($haystack,$needle,$offset)
      ?? nqp::substr($haystack,0,$offset)
      !! $haystack
}

my sub is-sha1(str $needle) {
    my int $i;
    if nqp::chars($needle) == 40 {
        my $map := BEGIN {
            my int @map;
            @map[.ord] = 1 for "0123456789ABCDEF".comb;
            @map;
        }

        nqp::while(
          nqp::isle_i($i,40)
            && nqp::atpos_i($map,nqp::ordat($needle,$i)),
          ++$i
        )
    }

    nqp::hllbool(nqp::iseq_i($i,41))
}

my sub stem(str $basename, $parts = *) {
    (my @indices := indices($basename, '.'))
      ?? nqp::substr(
           $basename,
           0,
           nqp::istype($parts,Whatever) || $parts > @indices
            ?? @indices[0]
            !! @indices[@indices - $parts]
         )
      !! $basename
}

# This is a copy of Rakudo::Iterator::NGrams from tyhe Rakudo
# core from 2022.10 onwards.
my class NGrams does PredictiveIterator {
    has str $!str;
    has Mu  $!what;
    has int $!size;
    has int $!step;
    has int $!pos;
    has int $!todo;
    method !SET-SELF($string, $size, $limit, $step, $partial) {
        $!str   = $string;
        $!what := $string.WHAT;
        $!size  = $size < 1 ?? 1 !! $size;
        $!step  = $step < 1 ?? 1 !! $step;
        $!pos   = -$step;
        $!todo = (
          nqp::chars($!str) + $!step - ($partial ?? 1 !! $!size)
        ) div $!step;
        $!todo  = $limit
          unless nqp::istype($limit,Whatever) || $limit > $!todo;
        $!todo  = $!todo + 1;
        self
    }
    method new($string, $size, $limit, $step, $partial) {
        $string
          ?? nqp::create(self)!SET-SELF($string,$size,$limit,$step,$partial)
          !! Rakudo::Iterator.Empty
    }
    method pull-one() {
        --$!todo
          ?? nqp::box_s(
               nqp::substr($!str,($!pos = $!pos + $!step),$!size),
               $!what
             )
          !! IterationEnd
    }
    method push-all(\target --> IterationEnd) {
        my str $str   = $!str;
        my int $todo  = $!todo;
        my int $pos   = $!pos;
        my int $size  = $!size;
        my int $step  = $!step;
        my Mu  $what := $!what;

        nqp::while(
          --$todo,
          target.push(
            nqp::box_s(
              nqp::substr($str,($pos = $pos + $step),$size),
              $what
            )
          )
        );
        $!todo = 0;
    }
    method count-only(--> Int:D) {
        nqp::sub_i($!todo,nqp::isgt_i($!todo,0))
    }
    method sink-all(--> IterationEnd) { $!pos = nqp::chars($!str) }
}

my sub ngram(str $string, Int:D $size, $limit = *, :$partial) {
    $size <= 1 && (nqp::istype($limit,Whatever) || $limit == Inf)
      ?? $string.comb
      !! Seq.new: NGrams.new: $string, $size, $limit, 1, $partial
}

my sub non-word(str $string) {
    nqp::hllbool(
      nqp::islt_i(
        nqp::findnotcclass(
          nqp::const::CCLASS_WORD,$string,0,nqp::chars($string)
        ),
        nqp::chars($string)
      )
    )
}

my sub letters(str $string) {
    my $found := nqp::list_s;
    my int $start;
    my int $end;
    my int $chars = nqp::chars($string);
    nqp::until(
      nqp::iseq_i($start,$chars),
      nqp::stmts(
        ($end = nqp::findnotcclass(
          nqp::const::CCLASS_WORD,$string,$start,$chars
        )),
        nqp::if(
          nqp::isgt_i($end,$start),
          nqp::push_s($found,nqp::substr($string,$start,$end - $start))
        ),
        nqp::if(
          nqp::iseq_i($end,$chars),
          ($start = $end),
          ($start = nqp::findcclass(
            nqp::const::CCLASS_WORD,$string,$end,$chars
          ))
        )
      )
    );
    nqp::join('',$found)
}

my constant $gcprop = nqp::unipropcode("General_Category");
my constant $empty  = nqp::create(array[uint32]);
my sub nomark(str $string) {

    # At least 1 char in the string
    if nqp::chars($string) -> int $c {
        my $codes := nqp::strtocodes(
          $string,
          nqp::const::NORMALIZE_NFD,
          nqp::create(array[uint32])
        );
        my int $m = nqp::elems($codes);

        # No codepoints that decomposed
        if $m == $c {
            $string
        }

        # At least one codepoint that decomposed
        else {
            my $cleaned := nqp::setelems(
              nqp::setelems(nqp::create(array[uint32]), $c),
              0
            );

            my int $i = -1;
            nqp::while(
              ++$i < $m,
              nqp::if(
                nqp::isne_i(
                  nqp::getuniprop_int(
                    nqp::atpos_i($codes, $i),
                    $gcprop
                  ),
                  6   # mark
                ),
                nqp::push_i($cleaned, nqp::atpos_i($codes, $i))
              )
            );
            nqp::strfromcodes($cleaned);
        }
    }

    # Nothing to work with
    else {
        $string
    }
}

my sub has-marks(str $string) {
    my str $letters = letters($string);
    nqp::strtocodes($letters, nqp::const::NORMALIZE_NFD, my int32 @ords);
    nqp::hllbool(nqp::isne_i(nqp::chars($letters),nqp::elems(@ords)))
}

my sub leading-whitespace(str $string) {
    nqp::substr($string,0,nqp::findnotcclass(
      nqp::const::CCLASS_WHITESPACE,$string,0,nqp::chars($string)
    ))
}

my sub trailing-whitespace(str $string) {
    nqp::substr($string,nqp::chars($string) - nqp::findnotcclass(
      nqp::const::CCLASS_WHITESPACE,nqp::flip($string),0,nqp::chars($string)
    ))
}

my sub is-CCLASS(str $string, int $type) {
    nqp::hllbool(
      nqp::iseq_i(
        nqp::findnotcclass($type,$string,0,nqp::chars($string)),
        nqp::chars($string)
      )
    )
}

my sub is-whitespace(str $string) {
    is-CCLASS($string, nqp::const::CCLASS_WHITESPACE)
}

my sub is-uppercase(str $string) {
    is-CCLASS($string, nqp::const::CCLASS_UPPERCASE)
}

my sub is-lowercase(str $string) {
    is-CCLASS($string, nqp::const::CCLASS_LOWERCASE)
}

my sub consists-of(str $string, str $chars) {
    my int32 @codes;
    my int8  @ok;

    nqp::strtocodes($string,nqp::const::NORMALIZE_NFC,@codes);
    @ok[.ord] = 1 for $chars.comb;

    my int $i     = -1;
    my int $elems = nqp::elems(@codes);
    nqp::while(
      nqp::islt_i(++$i,$elems)
        && nqp::atpos_i(@ok,nqp::atpos_i(@codes,$i)),
      nqp::null
    );

    nqp::hllbool(nqp::iseq_i($i,$elems))
}

my sub all-same(str $string) {
    nqp::chars($string)
      && consists-of($string, nqp::substr($string,0,1))
      ?? nqp::substr($string,0,1)
      !! Nil
}

my proto sub paragraphs(|) {*}
my multi sub paragraphs(@source, Int:D $initial = 0) {
    my class Paragraphs does Iterator {
        has     $!iterator;
        has int $!line;

        method new($iterator, int $line) {
            my $self := nqp::create(self);
            nqp::bindattr(  $self,Paragraphs,'$!iterator',$iterator);
            nqp::bindattr_i($self,Paragraphs,'$!line',    $line - 1);
            $self
        }

        method pull-one() {

            # Last iteration produced a paragraph, finish now
            return IterationEnd if nqp::isnull($!iterator);

            # Production logic
            my int $line   = $!line;
            my $collected := nqp::list_s;
            my sub paragraph() {
               $!line = $line;

               Pair.new(
                  $line - nqp::elems($collected),
                  nqp::join("\n", $collected)
               )
            }

            # Collection logic
            nqp::until(
              nqp::eqaddr(($_ := $!iterator.pull-one),IterationEnd),
              nqp::stmts(
                ++$line,
                nqp::if(
                  is-whitespace($_),
                  nqp::if(
                    nqp::elems($collected),
                    (return paragraph)
                  ),
                  nqp::push_s($collected, $_)
                )
              )
            );

            # Still need to produce final paragraph
            if nqp::elems($collected) {
                $!iterator := nqp::null;
                ++$line;
                paragraph
            }

            # No final paragraph, we're done
            else {
                IterationEnd
            }
        }
    }

    # Produce the sequence
    Seq.new: Paragraphs.new(@source.iterator, $initial)
}
my multi sub paragraphs(Cool:D $string, Int:D $initial = 0) {
    paragraphs $string.Str.lines, $initial
}

my sub regexify(str $spec, *%_) {
    my str $i = %_<i>
      || %_<ignorecase>
      || ((%_<m> || %_<smartcase>) && is-lowercase($spec))
      ?? ':i '
      !! '';
    my str $m = %_<m>
      || %_<ignoremark>
      || ((%_<m> || %_<smartmark>) && !has-marks($spec))
      ?? ':m '
      !! '';

    "/$i$m$spec/".EVAL  # until there's a better solution
}

my sub EXPORT(*@names) {
    Map.new: @names
      ?? @names.map: {
             if UNIT::{"&$_"}:exists {
                 UNIT::{"&$_"}:p
             }
             else {
                 my ($in,$out) = .split(':', 2);
                 if $out && UNIT::{"&$in"} -> &code {
                     Pair.new: "&$out", &code
                 }
             }
         }
      !! UNIT::.grep: {
             .key.starts-with('&') && !(.key eq '&EXPORT' | '&is-CCLASS')
         }
}

# vim: expandtab shiftwidth=4
