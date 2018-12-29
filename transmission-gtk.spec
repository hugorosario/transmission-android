%define name transmission
%define version 2.94
%define release 1

Summary:   Transmission BitTorrent Client
Name:      %{name}
Version:   %{version}
Release:   %{release}
License:   MIT
Group:     Applications/Internet
URL:       https://transmissionbt.com/
Epoch:     1
Source0:   %{name}-%{version}.tar.bz2

BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-buildroot

# MANDATORY for libtransmission
BuildRequires: curl-devel >= 7.15.4
BuildRequires: libevent-devel >= 2.0.10
BuildRequires: openssl-devel >= 0.9.7
Requires: curl >= 7.15.4
Requires: libevent >= 2.0.10
Requires: openssl >= 0.9.7
# MANDATORY for the gtk+ client
BuildRequires: glib2-devel >= 2.32.0
BuildRequires: gtk2-devel >= 3.4.0
Requires: glib2 >= 2.32.0
Requires: gtk2 >= 3.4.0

Provides: %{name}

%description
A fast and easy BitTorrent client

%prep
%setup -q
%build
%configure --program-prefix="" 
make CFLAGS="$RPM_OPT_FLAGS"
%install
rm -rf $RPM_BUILD_ROOT
make DESTDIR=$RPM_BUILD_ROOT install
%find_lang %{name}-gtk
%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%doc AUTHORS NEWS README
%attr(755,root,root) %{_bindir}/%{name}*
%{_datadir}/applications/%{name}-gtk.desktop
%{_datadir}/pixmaps/*
%{_datadir}/icons/*
%{_datadir}/%{name}/web/*
%{_datadir}/man/man1/%{name}*
%{_datadir}/locale/*

%changelog

* Wed Jan 13 2010 Jordan Lee <jordan@transmissionbt.com>
- made the GConf dependency explicit
- annotated the Depends section to show which libraries are optional
* Thu Mar 5 2009 Gijs <info@bsnw.nl>
- fixed %files section
- added Source0
* Wed Jul 18 2006 Jordan Lee <jordan@transmissionbt.com>
- first draft at a spec file, cribbed from Pan's spec file
