use Test;

my constant @subs = <
  between between-included around before after
  root leaf chomp-needle is-sha1 stem
>;

plan +@subs;

my $code;
for @subs {
    $code ~= qq:!c:to/CODE/;
    {
        use String::Utils '$_';
        ok MY::<&$_>:exists, "Did '$_' get exported?";
    }
    CODE
}

$code.EVAL;

# vim: expandtab shiftwidth=4
