%include        /usr/lib/rpm/macros.perl
Summary:	LDAP query script for Mutt
Summary(pl):	Skrypt odpytuj±cy LDAP do Mutta
Name:		mutt_ldap_query
Version:	0.9
Release:	2
License:	GPL
Group:		Applications/Mail
Group(de):	Applikationen/Post
Group(pl):	Aplikacje/Poczta
Group(pt):	Aplicações/Correio Eletrônico
Source0:	%{name}.pl
#Source0:	ftp://ftp.mutt.org//pub/mutt/contrib/%{name}-3.0.pl.gz
BuildArch:	noarch
Requires:	mutt
Requires:	iconv
Requires:	openldap
BuildRequires:	rpm-perlprov
Prereq:		/bin/egrep
BuildRoot:	%{tmpdir}/%{name}-%{version}-root-%(id -u -n)

%description
This is a simple script, which can be used as Mutt external query
command. After installing this package you can use Mutt's "Q" command
to query LDAP database, or "^T" when Mutt asks you for email address.

%description -l pl
To jest prosty skrypt, który mo¿e byæ u¿ywany jako komenda
zewnêtrznego zapytania. Po zainstalowaniu tego pakietu mo¿esz u¿ywaæ
komendy Mutta "Q" do odpytania bazy LDAP lub "^T" kiedy Mutt pyta 
o adres e-mail.

%prep

%install
rm -rf $RPM_BUILD_ROOT

install -d $RPM_BUILD_ROOT%{_bindir}
install %{SOURCE0} $RPM_BUILD_ROOT%{_bindir}

%clean
rm -rf $RPM_BUILD_ROOT

%post
# check if any query_command is already set
if ! egrep -q "^[[:space:]]*set[[:space:]]+query_command" /etc/Muttrc ; then
	cat >> /etc/Muttrc <<EOF;
set query_command="%{_bindir}/mutt_ldap_query.pl \"\`echo '%s'| iconv -f iso-8859-2 -t utf-8\`\" | iconv -f utf8 -t iso-8859-2"
EOF
fi

%preun
# check if query command is set to mutt_ldap_query
if egrep -q "^[[:space:]]*set[[:space:]]+query_command.*%{_bindir}/mutt_ldap_query.pl" /etc/Muttrc ; then
	mv -f /etc/Muttrc /etc/Muttrc.bak && \
	egrep -v "^[[:space:]]*set[[:space:]]+query_command.*%{_bindir}/mutt_ldap_query.pl" \
		/etc/Muttrc.bak > /etc/Muttrc
fi

%files
%defattr(644,root,root,755)
%attr(755,root,root) %{_bindir}/*
