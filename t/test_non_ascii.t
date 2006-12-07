#!/usr/bin/perl -w
use strict;

# $Id: test_non_ascii.t,v 1.2 2005/10/18 08:37:22 mrodrigu Exp $


use Test::More tests => 10;
use XML::DOM::XPath;

use utf8;

{ 
  my $dom = XML::DOM::Parser->new();
  my $doc = $dom->parsefile( "t/non_ascii.xml");
  is( $doc->toString, qq{<doc><ent>aü</ent><char>bü</char></doc>\n},'toString (on file)');
  is( $doc->findvalue( '//char'), "bü", "findvalue( '//char') (on file)");
  is( $doc->findnodes_as_string( '//char'), qq{<char>bü</char>}, "findnodes_as_string( '//char') (on file)");
  is( $doc->findvalue( '//ent'), qq{aü}, "findvalue( '//ent') (on file)");
  is( $doc->findnodes_as_string( '//ent'), qq{<ent>aü</ent>}, "findnodes_as_string( '//ent') (on file)");
}


{ 
  my $xmlStr = q{<doc><ent>a&#252;</ent><char>bü</char></doc>};
  my $dom = XML::DOM::Parser->new();
  my $doc = $dom->parse($xmlStr);
  is( $doc->toString, qq{<doc><ent>aü</ent><char>bü</char></doc>\n},'toString (on string)');
  is( $doc->findvalue( '//char'), 'bü', "findvalue( '//char') (on string)");
  is( $doc->findnodes_as_string( '//char'), qq{<char>bü</char>}, "findnodes_as_string( '//char') (on string)");
  is( $doc->findvalue( '//ent'), qq{aü}, "findvalue( '//ent') (on string)");
  is( $doc->findnodes_as_string( '//ent'), qq{<ent>aü</ent>}, "findnodes_as_string( '//ent') (on string)");
}


