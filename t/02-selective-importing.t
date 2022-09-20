use Test;

my constant @subs = <
  between between-included around before after
  root leaf chomp-needle is-sha1 stem
>;

plan @subs + 2;

my $code;
for @subs {
    $code ~= qq:!c:to/CODE/;
    {
        use String::Utils '$_';
        ok MY::<&$_>:exists, "Did '$_' get exported?";
    }
    CODE
}

$code ~= qq:!c:to/CODE/;
{
    use String::Utils <root:common-start>;
    ok MY::<&common-start>:exists, "Did 'common-start' get exported?";
    is MY::<&common-start>.name, 'root', 'Was the original name "root"?';
}
CODE

$code.EVAL;

# vim: expandtab shiftwidth=4
