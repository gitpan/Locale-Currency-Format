
BEGIN { $| = 1; print "1..20\n"; }
END   { print "not ok 1\n" unless $loaded; }

use Locale::Currency::Format;

$loaded = 1;

print "ok 1\n";

print "not " unless currency_format('usd', 1000) eq '1,000.00 USD';
print "ok 2\n";

print "not " unless currency_format('usd', 1000, FMT_NOZEROS) eq '1,000 USD';
print "ok 3\n";

print "not " unless currency_format('usd', 1000, FMT_HTML) eq '&#x0024;1,000.00';
print "ok 4\n";

print "not " unless currency_format('usd', 1000, FMT_NAME) eq "1,000.00 US Dollar";
print "ok 5\n";

print "not " unless currency_format('usd', 1000, FMT_SYMBOL) eq "\x{0024}1,000.00";
print "ok 6\n";

print "not " if currency_format('usd');
print "ok 7\n";

print "not " if currency_format();
print "ok 8\n";

print "not " if currency_format('us', 1000);
print "ok 9\n";

print "not " unless currency_symbol('vnd', SYM_UTF)  eq "\x{20AB}";
print "ok 10\n";

print "not " unless currency_symbol('vnd', SYM_HTML) eq "&#x20AB;";
print "ok 11\n";

print "not " if currency_symbol();
print "ok 12\n";

print "not " if currency_symbol('usd', 10);
print "ok 13\n";

print "not " if currency_symbol('vn');
print "ok 14\n";

print "not " if currency_symbol('aed');
print "ok 15\n";

print "not " unless currency_set('USD', '#.###,## $', FMT_COMMON);
print "ok 16\n";

print "not " unless currency_format('USD', 1000, FMT_COMMON) eq '1.000,00 $';
print "ok 17\n";

print "not " unless currency_set('USD');
print "ok 18\n";

print "not " unless currency_format('USD', 1000, FMT_COMMON) eq '$1,000.00';
print "ok 19\n";

print "not " unless currency_set('GBP', "\x{00A3}#,###.##", FMT_COMMON);
print "ok 20\n";
