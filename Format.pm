package Locale::Currency::Format;

require 5.006_00;

use strict;

use Exporter;

$Locale::Currency::Format::VERSION = "1.22";

@Locale::Currency::Format::ISA     = qw(Exporter);
@Locale::Currency::Format::EXPORT  = qw(
  currency_format
  currency_symbol
  FMT_NOZEROS
  FMT_STANDARD
  FMT_COMMON
  FMT_SYMBOL
  FMT_HTML
  FMT_NAME
  SYM_UTF
  SYM_HTML
);

@Locale::Currency::Format::EXPORT_OK = qw($error);

%Locale::Currency::EXPORT_TAGS = (
  DEFAULT => [@Locale::Currency::Format::EXPORT]
);

# Macros for format options
sub FMT_NOZEROS()  { 0x0001 }
sub FMT_STANDARD() { 0x0002 }
sub FMT_SYMBOL()   { 0x0004 }
sub FMT_COMMON()   { 0x0008 }
sub FMT_HTML()     { 0x0010 }
sub FMT_NAME()     { 0x0020 }

# Macros for symbol options
sub SYM_UTF()      { 0x0001 }
sub SYM_HTML()     { 0x0002 }

my $THOUSANDS_SEP = ',';
my $DECIMAL_POINT = '.';

my $list = { };

$Locale::Currency::Format::error = "";

sub currency_format
{
  my ($code, $amnt, $style, $entry) = @_;

  if (!defined $amnt) {
    $Locale::Currency::Format::error = "Undefined currency amount";
    return undef; 
  }

  if (!defined $code) {
    $Locale::Currency::Format::error = "Undefined currency code";
    return undef; 
  }

  $code  = uc $code;
  $entry = $list->{$code};

  if (!$entry) {
    $Locale::Currency::Format::error = "Invalid currency code";
    return undef;
  }

  $THOUSANDS_SEP = defined $entry->[2] ? $entry->[2] : '';
  $DECIMAL_POINT = defined $entry->[3] ? $entry->[3] : '';
  $amnt  = format_number($amnt, $entry->[1] || 0, $style ? !($style & 0x1) : 1);
  $style = $style ? $style & 0x00FE : FMT_STANDARD; 

  # Looks like a switch hehe
  while ($style) {
    $style == FMT_SYMBOL and $entry->[5]
      and return $entry->[8] ? $entry->[5].$entry->[4].$amnt 
                             : $amnt.$entry->[4].$entry->[5];
    $style == FMT_COMMON and $entry->[7]
      and return $entry->[8] ? $entry->[7].$entry->[4].$amnt
                             : $amnt.$entry->[4].$entry->[7];
    $style == FMT_HTML and $entry->[6]
      and return $entry->[8] ? $entry->[6].$entry->[4].$amnt
                             : $amnt.$entry->[4].$entry->[6];
    $style == FMT_NAME
      and return "$amnt $entry->[0]";

    last;
  }

  return "$amnt $code"; 
}

sub currency_symbol
{
  my ($code, $type, $entry) = @_;

  if (!defined $code) {
    $Locale::Currency::Format::error = "Undefined currency code";
    return undef;
  }

  $code  = uc $code;
  $entry = $list->{$code};
  
  if (!$entry) {
    $Locale::Currency::Format::error = "Invalid currency code";
    return undef;
  }

  if ($type and $type == SYM_UTF) {
    $Locale::Currency::Format::error = "Non-existant currency UTF symbol"
      unless $entry->[5];
    return $entry->[5];
  }
  elsif ($type and $type == SYM_HTML) {
    $Locale::Currency::Format::error = "Non-existant currency HTML symbol"
      unless $entry->[6];
    return $entry->[6];
  }
  elsif ($type) {
    $Locale::Currency::Format::error = "Invalid symbol type";
    return undef;
  }

  $Locale::Currency::Format::error = "Non-existant currency symbol"
    unless $entry->[5];

  return $entry->[5];
}


# These functions are copied directly out of Number::Format due to a bug that 
# lets locale settings take higher precedence to user's specific manipulation.
# In addition, this will exclude the unnecessary POSIX module used by 
# Number::Format.

sub round
{
    my ($number, $precision) = @_;
    
    $precision = 2 unless defined $precision;
    $number    = 0 unless defined $number;

    my $sign = $number <=> 0;
    my $multiplier = (10 ** $precision);
    my $result = abs($number);
    $result = int(($result * $multiplier) + .5000001) / $multiplier;
    $result = -$result if $sign < 0;
    return $result;
}

sub format_number
{
    my ($number, $precision, $trailing_zeroes) = @_;

    # Set defaults and standardize number
    $precision = 2 unless defined $precision;
    $trailing_zeroes = 1 unless defined $trailing_zeroes;

    # Handle negative numbers
    my $sign = $number <=> 0;
    $number = abs($number) if $sign < 0;
    $number = round($number, $precision); # round off $number

    # Split integer and decimal parts of the number and add commas
    my $integer = int($number);
    my $decimal;
    # Note: In perl 5.6 and up, string representation of a number
    # automagically includes the locale decimal point.  This way we
    # will detect the decimal part correctly as long as the decimal
    # point is 1 character.
    $decimal = substr($number, length($integer)+1)
        if (length($integer) < length($number));
    $decimal = '' unless defined $decimal;

    # Add trailing 0's if $trailing_zeroes is set.
    $decimal .= '0'x( $precision - length($decimal) )
        if $trailing_zeroes && $precision > length($decimal);

    # Add leading 0's so length($integer) is divisible by 3
    $integer = '0'x(3 - (length($integer) % 3)).$integer
      unless length($integer) % 3 == 0;

    # Split $integer into groups of 3 characters and insert commas
    $integer = join($THOUSANDS_SEP, grep {$_ ne ''} split(/(...)/, $integer));

    # Strip off leading zeroes and/or comma
    $integer =~ s/^0+//;
    $integer = '0' if $integer eq '';

    # Combine integer and decimal parts and return the result.
    my $result = ((defined $decimal && length $decimal) ?
                  join($DECIMAL_POINT, $integer, $decimal) :
                  $integer);

    return ($sign < 0) ? format_negative($result) : $result;
}

sub format_negative
{
    my($number, $format) = @_;
    $format = '-x' unless defined $format;
    $number =~ s/^-//;
    $format =~ s/x/$number/;
    return $format;
}



#===========================================================================
# ISO 4217 and common world currency symbols 
#===========================================================================
# code => 0      1       2       3       4       5       6       7       8
#        name  dplaces  ksep   dsep   symsep  symutf  symesc  symcom  prefix  
$list = {
AED => ["UAE Dirham",2,",","."," ",undef,undef,"Dhs.",1],
AFA => ["Afghani",0,undef,undef,"",undef,undef,undef,undef],
ALL => ["Lek",2,undef,undef,"",undef,undef,undef,undef],
AMD => ["Armenian Dram",2,",",".","",undef,undef,"AMD",0],
ANG => ["Antillian Guilder",2,".",","," ","\x{0192}","&#x0192;","NAf.",1],
AON => ["New Kwanza",0,undef,undef,"",undef,undef,undef,undef],
ARS => ["Argentine Peso",2,".",",","","\x{20B1}","&#x20B1;","\$",1],
ATS => ["Schilling",2,".",","," ",undef,undef,"öS",1],
AUD => ["Australian Dollar",2," ",".","","\x{0024}","&#x0024;","\$",1],
AWG => ["Aruban Guilder",2,",","."," ","\x{0192}","&#x0192;","AWG",1],
AZM => ["Azerbaijanian Manat",2,undef,undef,"",undef,undef,undef,undef],
BAM => ["Convertible Marks",2,",",".","",undef,undef,"AZM",0],
BBD => ["Barbados Dollar",2,undef,undef,"","\x{0024}","&#x0024;",undef,undef],
BDT => ["Taka",2,",","."," ",undef,undef,"Bt.",1],
BEF => ["Belgian Franc",0,".",""," ","\x{20A3}","&#x20A3;","BEF",1],
BGL => ["Lev",2," ",","," ",undef,undef,"lv",0],
BHD => ["Bahraini Dinar",3,",","."," ",undef,undef,"BD",1],
BIF => ["Burundi Franc",0,undef,undef,"",undef,undef,undef,undef],
BMD => ["Bermudian Dollar",2,",",".","","\x{0024}","&#x0024;","\$",1],
BND => ["Brunei Dollar",2,",",".","","\x{0024}","&#x0024;","\$",1],
BOB => ["Bolivian Boliviano",2,",",".","",undef,undef,"Bs",1],
BRL => ["Brazilian Real",2,".",","," ",undef,undef,"R\$",1],
BSD => ["Bahamian Dollar",2,",",".","","\x{0024}","&#x0024;","\$",1],
BTN => ["Bhutan Ngultrum",2,undef,undef,"",undef,undef,undef,undef],
BWP => ["Pula",2,",",".","",undef,undef,"P",1],
BYR => ["Belarussian Ruble",0,undef,undef,"",undef,undef,undef,undef],
BZD => ["Belize Dollar",2,",",".","","\x{0024}","&#x0024;","\$",1],
CAD => ["Canadian Dollar",2,",",".","","\x{0024}","&#x0024;","\$",1],
CDF => ["Franc Congolais",2,undef,undef,"",undef,undef,undef,undef],
CHF => ["Swiss Franc",2,"'","."," ",undef,undef,"SFr.",1],
CLP => ["Chilean Peso",0,".","","","\x{20B1}","&#x20B1;","\$",1],
CNY => ["Yuan Renminbi",2,",",".","","\x{5713}","&#x5713;","Y",1],
COP => ["Colombian Peso",2,".",",","","\x{20B1}","&#x20B1;","\$",1],
CRC => ["Costa Rican Colon",2,".",","," ","\x{20A1}","&#x20A1;","¢",1],
CUP => ["Cuban Peso",2,",","."," ","\x{20B1}","&#x20B1;","\$",1],
CVE => ["Cape Verde Escudo",0,undef,undef,"",undef,undef,undef,undef],
CYP => ["Cyprus Pound",2,".",",","","\x{00A3}","&#x00A3;","£",1],
CZK => ["Czech Koruna",2,".",","," ",undef,undef,"Kc",0],
DEM => ["Deutsche Mark",2,".",",","",undef,undef,"DM",0],
DJF => ["Djibouti Franc",0,undef,undef,"",undef,undef,undef,undef],
DKK => ["Danish Krone",2,".",",","",undef,undef,"kr.",1],
DOP => ["Dominican Peso",2,",","."," ","\x{20B1}","&#x20B1;","\$",1],
DZD => ["Algerian Dinar",2,undef,undef,"",undef,undef,undef,undef],
ECS => ["Sucre",0,undef,undef,"",undef,undef,undef,undef],
EEK => ["Kroon",2," ",","," ",undef,undef,"EEK",0],
EGP => ["Egyptian Pound",2,",","."," ","\x{00A3}","&#x00A3;","L.E.",1],
ERN => ["Nakfa",0,undef,undef,"",undef,undef,undef,undef],
ESP => ["Spanish Peseta",0,".",""," ","\x{20A7}","&#x20A7;","Ptas",0],
ETB => ["Ethiopian Birr",0,undef,undef,"",undef,undef,undef,undef],
EUR => ["Euro",2,".",",","","\x{20AC}","&#x20AC;","EUR",1],
FIM => ["Markka",2," ",","," ",undef,undef,"mk",0],
FJD => ["Fiji Dollar",0,undef,undef,"","\x{0024}","&#x0024;",undef,undef],
FKP => ["Pound",0,undef,undef,"","\x{00A3}","&#x00A3;",undef,undef],
FRF => ["French Franc",2," ",","," ","\x{20A3}","&#x20A3;","FRF",0],
GBP => ["Pound Sterling",2,",",".","","\x{00A3}","&#x00A3;","£",1],
GEL => ["Lari",0,undef,undef,"",undef,undef,undef,undef],
GHC => ["Cedi",2,",",".","",undef,undef,"¢",1],
GIP => ["Gibraltar Pound",2,",",".","","\x{00A3}","&#x00A3;","£",1],
GMD => ["Dalasi",0,undef,undef,"",undef,undef,undef,undef],
GNF => ["Guinea Franc",undef,undef,undef,undef,undef,undef,undef,undef],
GRD => ["Drachma",2,".",","," ","\x{20AF}","&#x20AF;","GRD",0],
GTQ => ["Quetzal",2,",",".","",undef,undef,"Q.",1],
GWP => ["Guinea-Bissau Peso",undef,undef,undef,undef,undef,undef,undef,undef],
GYD => ["Guyana Dollar",0,undef,undef,"","\x{0024}","&#x0024;",undef,undef],
HKD => ["Hong Kong Dollar",2,",",".","","\x{0024}","&#x0024;","HK\$",1],
HNL => ["Lempira",2,",","."," ",undef,undef,"L",1],
HRK => ["Kuna",2,".",","," ",undef,undef,"kn",0],
HTG => ["Gourde",0,undef,undef,"",undef,undef,undef,undef],
HUF => ["Forint",0,".",""," ",undef,undef,"Ft",0],
IDR => ["Rupiah",0,".","","",undef,undef,"Rp.",1],
IEP => ["Irish Pound",2,",",".","","\x{00A3}","&#x00A3;","£",1],
ILS => ["New Israeli Sheqel",2,",","."," ","\x{20AA}","&#x20AA;","NIS",0],
INR => ["Indian Rupee",2,",",".","","\x{20A8}","&#x20A8;","Rs.",1],
IQD => ["Iraqi Dinar",3,undef,undef,"",undef,undef,undef,undef],
IRR => ["Iranian Rial",2,",","."," ","\x{FDFC}","&#xFDFC;","Rls",1],
ISK => ["Iceland Krona",2,".",","," ",undef,undef,"kr",0],
ITL => ["Italian Lira",0,".",""," ","\x{20A4}","&#x20A4;","L.",1],
JMD => ["Jamaican Dollar",2,",",".","","\x{0024}","&#x0024;","\$",1],
JOD => ["Jordanian Dinar",3,",","."," ",undef,undef,"JD",1],
JPY => ["Yen",0,",","","","\x{00A5}","&#x00A5;","¥",1],
KES => ["Kenyan Shilling",2,",",".","",undef,undef,"Kshs.",1],
KGS => ["Som",0,undef,undef,"",undef,undef,undef,undef],
KHR => ["Riel",2,undef,undef,"","\x{17DB}","&#x17DB;",undef,undef],
KMF => ["Comoro Franc",0,undef,undef,"",undef,undef,undef,undef],
KPW => ["North Korean Won",0,undef,undef,"","\x{20A9}","&#x20A9;",undef,undef],
KRW => ["Won",0,",","","","\x{20A9}","&#x20A9;","\\",1],
KWD => ["Kuwaiti Dinar",3,",","."," ",undef,undef,"KD",1],
KYD => ["Cayman Islands Dollar",2,",",".","","\x{0024}","&#x0024;","\$",1],
KZT => ["Tenge",0,undef,undef,"",undef,undef,undef,undef],
LAK => ["Kip",0,undef,undef,"","\x{20AD}","&#x20AD;",undef,undef],
LBP => ["Lebanese Pound",0," ","","","\x{00A3}","&#x00A3;","L.L.",0],
LKR => ["Sri Lanka Rupee",0,undef,undef,"","\x{0BF9}","&#x0BF9;",undef,undef],
LRD => ["Liberian Dollar",0,undef,undef,"","\x{0024}","&#x0024;",undef,undef],
LSL => ["Lesotho Maloti",0,undef,undef,"",undef,undef,undef,undef],
LTL => ["Lithuanian Litas",2," ",","," ",undef,undef,"Lt",0],
LUF => ["Luxembourg Franc",0,"'",""," ","\x{20A3}","&#x20A3;","F",0],
LVL => ["Latvian Lats",2,",","."," ",undef,undef,"Ls",1],
LYD => ["Libyan Dinar",0,undef,undef,"",undef,undef,undef,undef],
MAD => ["Moroccan Dirham",0,undef,undef,"",undef,undef,undef,undef],
MDL => ["Moldovan Leu",0,undef,undef,"",undef,undef,undef,undef],
MGF => ["Malagasy Franc",0,undef,undef,"",undef,undef,undef,undef],
MKD => ["Denar",2,",","."," ",undef,undef,"MKD",0],
MMK => ["Kyat",0,undef,undef,"",undef,undef,undef,undef],
MNT => ["Tugrik",0,undef,undef,"","\x{20AE}","&#x20AE;",undef,undef],
MOP => ["Pataca",0,undef,undef,"",undef,undef,undef,undef],
MRO => ["Ouguiya",0,undef,undef,"",undef,undef,undef,undef],
MTL => ["Maltese Lira",2,",",".","","\x{20A4}","&#x20A4;","Lm",1],
MUR => ["Mauritius Rupee",0,",","","","\x{20A8}","&#x20A8;","Rs",1],
MVR => ["Rufiyaa",0,undef,undef,"",undef,undef,undef,undef],
MWK => ["Kwacha",2,undef,undef,"",undef,undef,undef,undef],
MXN => ["Mexican Peso",2,",","."," ","\x{0024}","&#x0024;","\$",1],
MYR => ["Malaysian Ringgit",2,",",".","",undef,undef,"RM",1],
MZM => ["Metical",2,".",","," ",undef,undef,"Mt",0],
NAD => ["Namibian Dollar",0,undef,undef,"","\x{0024}","&#x0024;",undef,undef],
NGN => ["Naira",0,undef,undef,"","\x{20A6}","&#x20A6;",undef,undef],
NIO => ["Cordoba Oro",0,undef,undef,"",undef,undef,undef,undef],
NLG => ["Netherlands Guilder",2,".",","," ","\x{0192}","&#x0192;","f",1],
NOK => ["Norwegian Krone",2,".",","," ",undef,undef,"kr",1],
NPR => ["Nepalese Rupee",2,",","."," ","\x{20A8}","&#x20A8;","Rs.",1],
NZD => ["New Zealand Dollar",2,",",".","","\x{0024}","&#x0024;","\$",1],
OMR => ["Rial Omani",3,",","."," ","\x{FDFC}","&#xFDFC;","RO",1],
PAB => ["Balboa",0,undef,undef,"",undef,undef,undef,undef],
PEN => ["Nuevo Sol",2,",","."," ",undef,undef,"S/.",1],
PGK => ["Kina",0,undef,undef,"",undef,undef,undef,undef],
PHP => ["Philippine Peso",2,",",".","","\x{20B1}","&#x20B1;","PHP",1],
PKR => ["Pakistan Rupee",2,",",".","","\x{20A8}","&#x20A8;","Rs.",1],
PLN => ["Zloty",2," ",","," ",undef,undef,"zl",0],
PTE => ["Portuguese Escudo",0,".",""," ",undef,undef,"Esc",0],
PYG => ["Guarani",0,undef,undef,"",undef,undef,undef,undef],
QAR => ["Qatari Rial",0,undef,undef,"","\x{FDFC}","&#xFDFC;",undef,undef],
ROL => ["Leu",2,".",","," ",undef,undef,"lei",0],
RUR => ["Russian Ruble",2,".",",","",undef,undef,"RUR",1],
RWF => ["Rwanda Franc",0,undef,undef,"",undef,undef,undef,undef],
SAC => ["S. African Rand Commerc.",0,undef,undef,"",undef,undef,undef,undef],
SAR => ["Saudi Riyal",2,",","."," ","\x{FDFC}","&#xFDFC;","SR",1],
SBD => ["Solomon Islands Dollar",0,undef,undef,"","\x{0024}","&#x0024;",undef,undef],
SCR => ["Seychelles Rupee",0,undef,undef,"","\x{20A8}","&#x20A8;",undef,undef],
SDD => ["Sudanese Dinar",undef,undef,undef,undef,undef,undef,undef,undef],
SDP => ["Sudanese Pound",0,undef,undef,"",undef,undef,undef,undef],
SEK => ["Swedish Krona",2," ",","," ",undef,undef,"kr",0],
SGD => ["Singapore Dollar",2,",",".","","\x{0024}","&#x0024;","\$",1],
SHP => ["St Helena Pound",0,undef,undef,"","\x{00A3}","&#x00A3;",undef,undef],
SIT => ["Tolar",2,".",","," ",undef,undef,"SIT",0],
SKK => ["Slovak Koruna",2," ",","," ",undef,undef,"Sk",0],
SLL => ["Leone",0,undef,undef,"",undef,undef,undef,undef],
SOS => ["Somali Shilling",0,undef,undef,"",undef,undef,undef,undef],
SRG => ["Surinam Guilder",0,undef,undef,"",undef,undef,undef,undef],
STD => ["Dobra",0,undef,undef,"",undef,undef,undef,undef],
SVC => ["El Salvador Colon",2,",",".","","\x{20A1}","&#x20A1;","¢",1],
SYP => ["Syrian Pound",0,undef,undef,"","\x{00A3}","&#x00A3;",undef,undef],
SZL => ["Lilangeni",2,"",".","",undef,undef,"E",1],
THB => ["Baht",2,",","."," ","\x{0E3F}","&#x0E3F;","Bt",0],
TJR => ["Tajik Ruble",0,undef,undef,"",undef,undef,undef,undef],
TJS => ["Somoni",undef,undef,undef,undef,undef,undef,undef,undef],
TMM => ["Manat",0,undef,undef,"",undef,undef,undef,undef],
TND => ["Tunisian Dinar",3,undef,undef,"",undef,undef,undef,undef],
TOP => ["Pa'anga",2,",","."," ",undef,undef,"\$",1],
TPE => ["Timor Escudo",undef,undef,undef,undef,undef,undef,undef,undef],
TRL => ["Turkish Lira",0,",","","","\x{20A4}","&#x20A4;","TL",0],
TTD => ["Trinidad and Tobago Dollar",0,undef,undef,"","\x{0024}","&#x0024;",undef,undef],
TWD => ["New Taiwan Dollar",0,undef,undef,"","\x{0024}","&#x0024;",undef,undef],
TZS => ["Tanzanian Shilling",2,",","."," ",undef,undef,"TZs",0],
UAH => ["Hryvnia",2," ",",","",undef,undef,"???",0],
UGX => ["Uganda Shilling",0,undef,undef,"",undef,undef,undef,undef],
USD => ["US Dollar",2,",",".","","\x{0024}","&#x0024;","\$",1],
UYU => ["Peso Uruguayo",2,".",",","","\x{20B1}","&#x20B1;","\$",1],
UZS => ["Uzbekistan Sum",0,undef,undef,"",undef,undef,undef,undef],
VEB => ["Bolivar",2,".",","," ",undef,undef,"Bs.",1],
VND => ["Dong",0,".",""," ","\x{20AB}","&#x20AB;","Dong",0],
VUV => ["Vatu",0,",","","",undef,undef,"VT",0],
WST => ["Tala",0,undef,undef,"",undef,undef,undef,undef],
XAF => ["CFA Franc BEAC",0,undef,undef,"",undef,undef,undef,undef],
XCD => ["East Caribbean Dollar",2,",",".","","\x{0024}","&#x0024;","\$",1],
XOF => ["CFA Franc BCEAO",undef,undef,undef,undef,undef,undef,undef,undef],
XPF => ["CFP Franc",0,undef,undef,"",undef,undef,undef,undef],
YER => ["Yemeni Rial",0,undef,undef,"","\x{FDFC}","&#xFDFC;",undef,undef],
YUN => ["New Dinar",0,undef,undef,"",undef,undef,undef,undef],
ZAR => ["Rand",2," ","."," ","\x{0052}","&#x0052;","R",1],
ZMK => ["Kwacha",0,undef,undef,"",undef,undef,undef,undef],
ZRN => ["New Zaire",undef,undef,undef,undef,undef,undef,undef,undef],
ZWD => ["Zimbabwe Dollar ",2," ",".","","\x{0024}","&#x0024;","Z\$",1],
};


1;

__END__

=head1 NAME

Locale::Currency::Format - Perl functions for formatting monetary values

=head1 SYNOPSIS

  use Locale::Currency::Format;

  $amnt = currency_format('usd', 1000);             # => 1,000.00 USD
  $amnt = currency_format('eur', 1000, FMT_COMMON); # => EUR1.000,00
  $amnt = currency_format('usd', 1000, FMT_SYMBOL); # => $1,000.00

  $sym  = currency_symbol('usd');                   # => $
  $sym  = currency_symbol('gbp', SYM_HTML);         # => &#163;

  The following example illustrates how to use Locale::Currency::Format
  with Mason. Skip it if you are not interested in Mason. A simple Mason
  component might look like this: 

  Total: <% 123456789, 'eur' |c %> 

  <%init>
    use Locale::Currency::Format;

    $m->interp->set_escape(c => \&escape_currency);

    sub escape_currency {
      my ($amnt, $code) = ${$_[0]} =~ /(.*?)([A-Za-z]{3})/;
      ${$_[0]} = currency_format($code, $amnt, FMT_HTML);
    }
  </%init>

=head1 DESCRIPTION

B<Locale::Currency::Format> is a light-weight Perl module that allows one
to display monetary values in the formats recognized internationally or
locally depending on his wish.

=over 2

=item C<currency_format(CODE, AMOUNT [, FORMAT])>

B<currency_format> takes two mandatory parameters, namely currency code and 
amount respectively, and optionally a third parameter indicating which
format is desired. Upon failure, it returns I<undef> and an error message is
stored in B<$Locale::Currency::Format::error>.

  CODE   - A 3-letter currency code as specified in ISO 4217.
           Note that old code such as GBP, FRF and so on can also
           be valid.

  AMOUNT - A numeric value.

  FORMAT - There are five different format options FMT_STANDARD,
           FMT_COMMON, FMT_SYMBOL, FMT_HTML and FMT_NAME. If it is
           omitted, the default format is FMT_STANDARD.

           FMT_STANDARD Ex: 1,000.00 USD
           FMT_SYMBOL   Ex: $1,000.00
           FMT_COMMON   Ex: 1.000 Dong (Vietnam), BEF 1.000 (Belgium)
           FMT_HTML     Ex: &#xA3;1,000.00  (pound-sign HTML escape)
           FMT_NAME     Ex: 1,000.00 US Dollar

           By default the trailing zeros after the decimal point will
           be added. To turn it off, do a bitwise B<or> of FMT_NOZEROS
           with one of the five options above.
           Ex: FMT_STANDARD | FMT_NOZEROS  will give 1,000 USD
           
=item C<currency_symbol(CODE [, TYPE])>

For conveniences, the function B<currency_symbol> is provided for symbol
lookup given a 3-letter currency code. Optionally, one can specify which
format the symbol should be returned - Unicode-based character or HTML escape.
Default is a Unicode-based character. Upon failure, it returns I<undef> and an error message is stored in B<$Locale::Currency::Format::error>.

  CODE   - A 3-letter currency code as specified in ISO 4217
  TYPE   - There are two available types SYM_UTF and SYM_HTML
	   SYM_UTF returns the symbol (if exists) as an Unicode character
           SYM_HTML returns the symbol (if exists) as a HTML escape

=head2 A WORD OF CAUTION

Please be aware that some currencies might have missing common format. In that case, B<currency_format> will fall back to B<FMT_STANDARD> format.

Also, be aware that some currencies do not have monetary symbol.

As countries merge together or split into smaller ones, currencies can be added or removed by the ISO. Please help keep the list up to date by sending your feedback to the email address at the bottom.

To see the error, examine $Locale::Currency::Format::error

  use Locale::Currency::Format;
  my $value = currency_format('US', 1000);
  print $value ? $value : $Locale::Currency::Format::error
  OR
  use Locale::Currency::Format qw(:DEFAULT $error);
  my $value = currency_format('US', 1000);
  print $value ? $value : $error 

Lastly, please refer to L<perluniintro> and L<perlunicode> for displaying Unicode characters if you intend to use B<FMT_SYMBOL> and B<currency_symbol>. Otherwise, it reads "No worries, mate!"

=head1 SEE ALSO

L<Locale::Currency>, L<Math::Currency>, L<Number::Format>, L<perluniintro>, L<perlunicode>

=head1 BUGS

If you find any inaccurate or missing information, please send your comments to L<tnguyen@cpan.org>. Your effort is certainly appreciated!

=cut 
