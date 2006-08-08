#!/usr/bin/perl -w
use strict;

# $Id: test_bugs.t,v 1.6 2005/03/08 09:08:42 mrodrigu Exp $


use Test::More tests => 13;

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

# RT #8977 : could not call XPath methods on an XML::DOM::Document before the parse
# because new did not create the xp object attached to the XML::DOM::Document
{ my $xml = XML::DOM::Document->new;
  my $root = $xml->createElement('root');
  $xml->appendChild($root);
  ok( $xml->exists('root'), "can call XPath methods on an XML::DOM::Document before the parse");
}

# RT#11648: some xpath expressions containing '>', '>=', '<', '<=' operators trigger an error:
# Can't locate object method "to_number" via package "XML::DOM::Element" ...
# found and test case by a guest on RT
{ my $xmlStr = q{<d><e id="e1" nb="1"><f>1</f></e><e id="e2" nb="2"><f>3</f></e><e id="e3" nb="3"><f>1</f></e>
                    <e id="e4" nb="4"><f>2</f></e><e id="e5" nb="5"><f>5</f></e><e id="e6" nb="6"><f>10</f></e></d>
                };
    my $dom = XML::DOM::Parser->new();
    my $doc = $dom->parse($xmlStr);
    my @prices= map { $_->getAttribute( 'id')} $doc->findnodes('/d/e[f<1.9]');
    is( join( ':' => @prices), 'e1:e3', "using number comparison on elements");
    my $prices= $doc->findvalue('/d/e[f<2]/@id');

    if( $prices eq 'e1e3e4')
      { warn "  warning: the version of XPath you are using has a bug in the way it\n",
             "  handles numeric comparisons.\n",
             "  read the bug description: http://rt.cpan.org/NoAuth/Bug.html?id=6363\n",
						 "  if an XML::XPath version with a fix for the bug is not yet available,\n",
             "  you can get a patched version: http://xmltwig.com/xml-xpath-patched/\n",
             ;
        ok( 1, "using number comparison on elements (XPath bug found)"); 
      }
    else
      { is( $prices, 'e1e3', "using number comparison on elements"); }

    $prices= $doc->findvalue('/d/e[f<2.5]/@id');
    is( $prices, 'e1e3e4', "using number comparison on elements");
    is( $doc->findvalue('/d/e[@nb>=2]/@id'), 'e2e3e4e5e6', "using number comparison on attributes");
    my @nodes= $doc->findnodes( '/d/e/@id');
}

{ #RT 20884: //@* dies (needed getAttributes on XML::DOM::Document node type)
  my $res= XML::DOM::Parser->new
                          ->parse('<root a="e0"><element1 att="e1"/><element2 att="e3" aa="e2"/></root>')
                          ->findvalue('//@*');
  is( $res, 'e0e1e2e3', '//@*');
}
{ #RT 20884: //comment() dies (missing is<Type>Node methods)
  my $doc= XML::DOM::Parser->new
                          ->parse('<root><!--c1--><?t1 d1?><!--c2--><?t2 d2?><?t1 d3?></root>');
  is( $doc->findvalue( '//comment()'), 'c1c2', '//comment()');
  is( $doc->findvalue( '//processing-instruction("t1")'), 'd1d3', '//processing-instruction( "t1")');

  # bug in XML::XPath
  my $pis= $doc->findvalue( '//processing-instruction()');
    if( $pis eq '')
      { warn "  warning: the version of XPath you are using has a bug in the way it\n",
             "  handles the processing-instruction() selector'.\n",
             "  if an XML::XPath version with a fix for the bug is not yet available,\n",
             "  you can get a patched version: http://xmltwig.com/xml-xpath-patched/\n",
             ;
        ok( 1, "testing '//processing-instruction()' (XPath bug found)"); 
      }
    else
      { is( $doc->findvalue( '//processing-instruction()'), 'd1d2d3', '//processing-instruction()'); }
}

