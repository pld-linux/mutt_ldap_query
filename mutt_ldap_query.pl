#!/usr/bin/perl -w
#
# LDAP external address query for Mutt v. 0.9
# (c) Jacek Konieczny <jajcus@pld.org.pl>
#
# $Revision$
#
# $Log$
# Revision 1.2  2000/09/12 14:18:11  jajcus
# - fixed Revision CVS tag
#
# Revision 1.1  2000/09/12 14:16:42  jajcus
# - first version
#
#

use MIME::Base64 qw(decode_base64);
require 'getopt.pl';

sub usage(){

print STDERR <<'EOF';
LDAP external address query for Mutt v. 0.9
(c) Jacek Konieczny <jajcus@pld.org.pl>

Usage:
	mutt_ldap_query.pl [OPTION ...] <query> [<attr> ...]

	<query> is ldap query in parenthesis (see ldap_search(3)) or
		any other string for substring search (uid, cn and sn
		attributes are searched)

	<attr> 	attributes which should be output 

	Options:

	-C		Automatically chase referrals.
	-S <attribute>	Sort the entries returned based on <attribute>.
	-H <ldapuri> 	Specify URI(s) referring to the ldap server(s).
        -b <searchbase> Use <searchbase> as the starting point for the search.
	-a never|always|search|find
			Specify how aliases dereferencing is done (default: always).
	-P 2|3		Specify the LDAP protocol version to use.
	-l <timelimit>	Wait at most <timelimit> seconds for a search to complete. 
	-z <sizelimit>	Retrieve at most sizelimit entries for a search.
	-h		Show this message.

	To use it with mutt you should have something like that in your muttrc:
	set query_command="/usr/local/bin/mutt_ldap_query.pl \
	     \"\`echo '%s'| iconv -f iso-8859-1 -t utf-8\`\" \
	     | iconv -f utf8 -t iso-8859-1"
EOF
	exit 1;
}

sub print_error{
my ($err)=@_;

	print "$err\n";
	exit 2;
}

my ($query,$ldapsearchflags,$attrs);
my ($nrentries,$entries);
my ($field,$value);
my (@mails,$cn,$uid,$mail);

$ldapsearchflags="-x";

($opt_C,$opt_h)=(undef,undef);
Getopt('SHbaPlz');
$ldapsearchflags.=" -C" if defined($opt_C);
$ldapsearchflags.=" -S '$opt_S'" if defined($opt_S);
$ldapsearchflags.=" -H '$opt_H'" if defined($opt_H);
$ldapsearchflags.=" -b '$opt_b'" if defined($opt_b);
$ldapsearchflags.=" -a '$opt_a'" if defined($opt_a);
$ldapsearchflags.=" -P '$opt_P'" if defined($opt_P);
$ldapsearchflags.=" -l '$opt_l'" if defined($opt_l);
$ldapsearchflags.=" -z '$opt_z'" if defined($opt_z);
usage if defined($opt_h);

$query=shift @ARGV;
usage() unless defined ($query);

$attrs=join(" ",@ARGV);
$attrs="mail cn uid" unless defined ($attrs) && $attrs ne "";

$query=~s/\(/\\(/g;
$query=~s/\)/\\)/g;

$query="(|(uid=*$query*)(cn=*$query*)(sn=*query*))" unless $query=~/^\(.*\)$/;

print "Searching LDAP database...";
$nrentries=0;
open RESULT,"ldapsearch $ldapsearchflags '$query' $attrs|" || print_error("$!");
while(<RESULT>){
	next unless /^dn: /;
	@mails=undef;
	($cn,$uid)=(undef,undef);
	while(<RESULT>){
		last unless /^([^:]+:?): (.*)$/;
		$field=$1; $value=$2;
		if ($field=~/^(.+):$/){
			$field=$1;
			$value=decode_base64($value);
			$value=~s/\x00/\\x00/g;
			$value=~s/\n/\\n/g;
			$value=~s/\t/\\t/g;
		}
		$cn=$value if $field eq "cn";
		$uid=$value if $field eq "uid";
		push @mails,$value if $field eq "mail";
	}
	if (defined($cn)) {
		while(($mail=pop @mails)){
			$entries.="$mail\t$cn";
			$entries.="\t$uid" if defined($uid);
			$entries.="\n";
			$nrentries++;
		}
	}
}
close RESULT;
print "$nrentries matching entries found\n";
print "$entries" if $entries;

0;
