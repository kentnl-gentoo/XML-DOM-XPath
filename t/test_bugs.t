#!/usr/bin/perl -w
use strict;

# $Id: test_bugs.t,v 1.1 2004/07/21 12:21:31 mrodrigu Exp $


use Test::More tests => 4;

use XML::DOM::XPath;
ok(1, "use XML::DOM::XPath");

{
# bug 1
# bug on getAttributes: problem when an element has no attribute
# found by Harry Moreau
my $parser= XML::DOM::Parser->new;
my $dom= $parser->parse( '<doc><elt/><elt id="elt1">elt 1</elt><elt id="elt2">elt 2</elt></doc>');
my @nodes= $dom->findnodes( '//elt[@id="elt1"]');
is( scalar @nodes => 1, "bug 1: result number");
is( $nodes[0]->toString => '<elt id="elt1">elt 1</elt>', "bug 1: result content"); 
}
{
# RT #8167 : toString did not work on a document
# found by Ben Hsing
my $parser= XML::DOM::Parser->new;
my $xml= "<doc>foo</doc>\n";
my $dom= $parser->parse( $xml);
is( $dom->toString, $xml, "toString on a whole document");
}
