# Since this distribution is about providing optimized functionality
# that can also be achieved by e.g. using regular expressions, it was decided
# to use NQP in here.  All of these subroutines could easily be rewritten
# in pure Raku if necessary, should that be needed for Raku implementations
# that are not based on NQP.
use nqp;

#- helper subs -----------------------------------------------------------------
my sub is-CCLASS(str $string, int $type) {
    nqp::hllbool(
      nqp::iseq_i(
        nqp::findnotcclass($type,$string,0,nqp::chars($string)),
        nqp::chars($string)
      )
    )
}

#- abbrev ----------------------------------------------------------------------
my proto sub abbrev(|) {*}
my multi sub abbrev() { BEGIN Map.new }
my multi sub abbrev(*@words) { abbrev(@words) }
my multi sub abbrev(@words) {
    my $result := Map.new;
    my $seen   := nqp::getattr($result,Map,'$!storage');
    for @words -> str $word {
        nqp::bindkey($seen,$word,$word);

        my int $chars = nqp::chars($word);
        nqp::while(
          --$chars > 0,
          nqp::stmts(
            (my str $needle = nqp::substr($word,0,$chars)),
            nqp::if(
              nqp::existskey($seen,$needle),
              nqp::stmts(
                nqp::deletekey($seen,$needle),
                nqp::while(
                  --$chars,
                  nqp::deletekey($seen,nqp::substr($word,0,$chars))
                )
              ),
              nqp::bindkey($seen,$needle,$word)
            )
          )
        );
    }

    $result
}

#- after -----------------------------------------------------------------------
my sub after(str $string, str $after) {
    nqp::iseq_i((my int $right = nqp::index($string,$after)),-1)
      ?? Nil
      !! nqp::substr($string,nqp::add_i($right,nqp::chars($after)))
}

#- all-same --------------------------------------------------------------------
my sub all-same(str $string) {
    nqp::chars($string)
      && consists-of($string, nqp::substr($string,0,1))
      ?? nqp::substr($string,0,1)
      !! Nil
}

#- around ----------------------------------------------------------------------
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

#- before ----------------------------------------------------------------------
my sub before(str $string, str $before) {
    nqp::iseq_i((my int $left = nqp::index($string,$before)),-1)
      ?? Nil
      !! nqp::substr($string,0,$left)
}

#- between ---------------------------------------------------------------------
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

#- between-included ------------------------------------------------------------
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

#- chomp-needle ----------------------------------------------------------------
my sub chomp-needle(str $haystack, str $needle) {
    my int $offset = nqp::sub_i(nqp::chars($haystack),nqp::chars($needle));
    nqp::eqat($haystack,$needle,$offset)
      ?? nqp::substr($haystack,0,$offset)
      !! $haystack
}

#- consists-of -----------------------------------------------------------------
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

#- describe-Version ------------------------------------------------------------
my sub describe-Version(Str() $version) {
    if after($version,"g") -> $sha {
        my @major = before($version,"g").split(".", :skip-empty);
        "@major.head(*-1).join(".")-@major.tail()-g$sha.subst('.',:global)"
    }
    else {
        $version
    }
}

#- expand-tab ------------------------------------------------------------------
my sub expand-tab(str $spec, int $size) {
    my str @parts = nqp::split("\t",$spec);

    # need to do something
    if nqp::elems(@parts) > 1 {

        # just remove tabs
        if $size <= 0 {
            nqp::join("",@parts)
        }

        # just replace tab by space
        elsif $size == 1 {
            nqp::join(" ",@parts)
        }

        # need to calculate columns
        else {
            my int $end = nqp::elems(@parts) - 1;
            my int $width;
            my int $i = -1;
            nqp::while(
              nqp::islt_i(++$i,$end),
              nqp::stmts(
                (my str $part = nqp::atpos_s(@parts,$i)),
                ($width = $width + nqp::chars($part)),  # UNCOVERABLE
                (my int $add = $size - nqp::mod_i($width,$size)),  # UNCOVERABLE
                nqp::bindpos_s(@parts,$i,nqp::concat($part,nqp::x(' ',$add))),  # UNCOVERABLE
                ($width = $width + $add)  # UNCOVERABLE
              )
            );
            nqp::join('',@parts)
        }
    }

    # nothing to do
    else {
        $spec
    }
}

#- has-marks -------------------------------------------------------------------
my sub has-marks(str $string) {
    my str $letters = letters($string);
    nqp::strtocodes($letters, nqp::const::NORMALIZE_NFD, my int32 @ords);
    nqp::hllbool(nqp::isne_i(nqp::chars($letters),nqp::elems(@ords)))
}

#- is-lowercase ----------------------------------------------------------------
my sub is-lowercase(str $string) {
    is-CCLASS($string, nqp::const::CCLASS_LOWERCASE)
}

#- is-sha1 ---------------------------------------------------------------------
my sub is-sha1(str $needle) {
    my int $i;
    if nqp::chars($needle) == 40 {
        my $map := BEGIN {
            my int @map;
            @map[.ord] = 1 for "0123456789ABCDEF".comb;  # UNCOVERABLE
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

#- is-uppercase ----------------------------------------------------------------
my sub is-uppercase(str $string) {
    is-CCLASS($string, nqp::const::CCLASS_UPPERCASE)
}

#- is-whitespace ---------------------------------------------------------------
my sub is-whitespace(str $string) {
    is-CCLASS($string, nqp::const::CCLASS_WHITESPACE)
}

#- leading-whitespace ----------------------------------------------------------
my sub leading-whitespace(str $string) {  # UNCOVERABLE
    nqp::substr($string,0,nqp::findnotcclass(
      nqp::const::CCLASS_WHITESPACE,$string,0,nqp::chars($string)
    ))
}

#- leaf ------------------------------------------------------------------------
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

#- letters ---------------------------------------------------------------------
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

#- ngram -----------------------------------------------------------------------
# This is a copy of Rakudo::Iterator::NGrams from the Rakudo
# core from 2022.10 onwards.
my class NGrams does PredictiveIterator {
    has str $!str;
    has Mu  $!what;
    has int $!size;
    has int $!step;
    has int $!pos;
    has int $!todo;
    method !SET-SELF($string, $size, $limit, $step, $partial) {
        $!str   = $string;  # UNCOVERABLE
        $!what := $string.WHAT;
        $!size  = $size < 1 ?? 1 !! $size;
        $!step  = $step < 1 ?? 1 !! $step;
        $!pos   = -$step;
        $!todo = (  # UNCOVERABLE
          nqp::chars($!str) + $!step - ($partial ?? 1 !! $!size)
        ) div $!step;
        $!todo  = $limit
          unless nqp::istype($limit,Whatever) || $limit > $!todo;
        $!todo  = $!todo + 1;  # UNCOVERABLE
        self
    }
    method new($string, $size, $limit, $step, $partial) {
        $string
          ?? nqp::create(self)!SET-SELF($string,$size,$limit,$step,$partial)
          !! Rakudo::Iterator.Empty
    }
    method pull-one() {
        --$!todo  # UNCOVERABLE
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

#- nomark ----------------------------------------------------------------------
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

#- non-word --------------------------------------------------------------------
my sub non-word(str $string) {  # UNCOVERABLE
    nqp::hllbool(
      nqp::islt_i(
        nqp::findnotcclass(
          nqp::const::CCLASS_WORD,$string,0,nqp::chars($string)
        ),
        nqp::chars($string)
      )
    )
}

#- paragraphs ------------------------------------------------------------------
my proto sub paragraphs(|) {*}
my multi sub paragraphs(@source, Int:D $initial = 0, :$Pair = Pair) {
    my class Paragraphs does Iterator {
        has     $!iterator;
        has str $!next;
        has int $!line;
        has     $!Pair;

        method new($iterator, int $line, $Pair) {
            my $self := nqp::create(self);
            nqp::bindattr(  $self,Paragraphs,'$!iterator',$iterator);
            nqp::bindattr_s($self,Paragraphs,'$!next',    nqp::null_s);
            nqp::bindattr_i($self,Paragraphs,'$!line',    $line - 1);
            nqp::bindattr(  $self,Paragraphs,'$!Pair',    $Pair);
            $self
        }

        method pull-one() {

            # Last iteration produced a paragraph, finish now
            return IterationEnd if nqp::isnull($!iterator);

            # Production logic
            my int $line   = $!line;
            my int $done;    # 1 if paragraph is done
            my $collected := nqp::list_s;

            unless nqp::isnull_s($!next) {
                nqp::push_s($collected,$!next);
                $!next = nqp::null_s;
            }

            my sub paragraph(str $next) {
               $!line = $line;  # UNCOVERABLE
               $!next = $next;  # UNCOVERABLE

               $!Pair.new(
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
                  nqp::stmts(
                    nqp::push_s($collected,$_),
                    ($done = 1)
                  ),
                  nqp::if(                 # not whitespace
                    $done,
                    (return paragraph($_)),
                    nqp::push_s($collected, $_)
                  )
                )
              )
            );

            # Single line after last paraghraph
            if $!next {
                $!iterator := nqp::null;  # UNCOVERABLE
                $!next
            }

            # Still need to produce final paragraph
            elsif nqp::elems($collected) {  # UNCOVERABLE
                $!iterator := nqp::null;  # UNCOVERABLE
                ++$line;  # UNCOVERABLE
                paragraph("")
            }

            # No final paragraph, we're done
            else {
                IterationEnd
            }
        }
    }

    # Produce the sequence
    Seq.new: Paragraphs.new(@source.iterator, $initial, $Pair)
}
my multi sub paragraphs(Cool:D $string, Int:D $initial = 0, :$Pair = Pair) {
    paragraphs $string.Str.lines, $initial, :$Pair
}

#- regexify --------------------------------------------------------------------
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

#- replace ---------------------------------------------------------------------
my constant $cursor-init = Match.^lookup("!cursor_init");
my sub replace(str $haystack, Regex:D $needle, str $replacement) {
    my $cursor := $needle($cursor-init(Match,$haystack,:0c));
    my int $pos = nqp::getattr_i($cursor,Match,'$!pos');
    $pos >= 0
      ?? nqp::substr($haystack,0,nqp::getattr_i($cursor,Match,'$!from'))
           ~ $replacement
           ~ nqp::substr($haystack,$pos)
      !! $haystack
}

#- replace-all -----------------------------------------------------------------
my constant $global = Match.^lookup("CURSOR_MORE");
my sub replace-all(str $haystack, Regex:D $needle, str $replacement) {
    my $cursor := $needle($cursor-init(Match,$haystack,:0c));
    my int $pos = nqp::getattr_i($cursor,Match,'$!pos');
    if $pos >= 0 {
        my int $start;
        my str @parts;
        nqp::while(
          $pos >= 0,
          nqp::stmts(
            nqp::push_s(@parts,
              nqp::substr(
                $haystack,
                $start,
                nqp::getattr_i($cursor,Match,'$!from') - $start
              )
            ),
            nqp::push_s(@parts,$replacement),
            $start = $pos,
            ($cursor := $global($cursor)),
            ($pos = nqp::getattr_i($cursor,Match,'$!pos'))
          )
        );
        nqp::push_s(@parts,nqp::substr($haystack,$start));
        nqp::join("",@parts)
    }
    else {
        $haystack
    }
}

#- root ------------------------------------------------------------------------
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

#- sha1 ------------------------------------------------------------------------
my sub sha1(str $needle) { nqp::sha1($needle) }  # UNCOVERABLE

#- shorten ---------------------------------------------------------------------
my sub shorten(str $target, int $max) {
    nqp::if(
      nqp::chars($target) <= $max,
      $target,
      nqp::if(
        $max >= 3,
        nqp::concat(
          nqp::substr(
            $target,
            0,
            (my int $half = nqp::bitshiftr_i($max,1))
              - nqp::not_i(nqp::bitand_i($max,1))  # UNCOVERABLE
          ),
          nqp::concat(
            '…',
            nqp::substr(
              $target,
              nqp::chars($target) - $half
            )
          )
        ),
        "Target length $max is too short".Failure
      )
    )
}

#- stem ------------------------------------------------------------------------
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

#- text-from-url ---------------------------------------------------------------
my sub text-from-url(str $url, :$verbose) {
    my $proc := run 'curl', '--fail', $url, :out, :err ;
    if $proc.exitcode {
        $*ERR.put: $proc.err.slurp if $verbose;
        Nil
    }
    else {
        $proc.out.slurp
    }
}

#- trailing-whitespace ---------------------------------------------------------
my sub trailing-whitespace(str $string) {
    nqp::substr($string,nqp::chars($string) - nqp::findnotcclass(
      nqp::const::CCLASS_WHITESPACE,nqp::flip($string),0,nqp::chars($string)
    ))
}

#- word-at ---------------------------------------------------------------------
my sub word-at(str $string, int $cursor) {

    # something to look at
    if $cursor >= 0 && nqp::chars($string) -> int $length {
        my int $last;
        my int $pos;
        my int $index;
        nqp::while(
          $last < $length && ($pos = nqp::findcclass(
            nqp::const::CCLASS_WHITESPACE,
            $string,
            $last,
            $length - $last
          )) < $cursor,
          nqp::stmts(
            nqp::if($pos > $last, ++$index),
            ($last  = $pos + 1)  # UNCOVERABLE
          )
        );
        $last >= $length || $pos == $last
          ?? Empty
          !! ($last, $pos - $last, $index)
    }

    # nothing to look at
    else {
        Empty
    }
}

#- EXPORT ----------------------------------------------------------------------
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

#- hack ------------------------------------------------------------------------
# To allow version / auth / api fetching
module String::Utils:ver<0.0.37>:auth<zef:lizmat> { }

# vim: expandtab shiftwidth=4
