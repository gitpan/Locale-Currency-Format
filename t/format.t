
BEGIN { $| = 1; print "1..6\n"; }
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
