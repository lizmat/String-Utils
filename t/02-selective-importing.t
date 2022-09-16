use Test;

my constant @subs = <
  between between-included around before after root chomp-needle is-sha1
>;

plan +@subs;

my $code;
for @subs {
    $code ~= qq:!c:to/CODE/;
    {
        use String::Utils '$_';
        ok MY::<&$_>:exists, "Did '$_' got exported?";
    }
    CODE
}

$code.EVAL;

# vim: expandtab shiftwidth=4
