# $Id: XPath.pm,v 1.9 2005/02/24 12:35:31 mrodrigu Exp $

package XML::DOM::XPath;

use strict;

use XML::XPath;
use XML::DOM;

use vars qw($VERSION);
$VERSION="0.08";

my $xp_field;     # the field in the document that contains the XML::XPath object
my $parent_field; # the field in an attribute that contains the parent element

BEGIN 
  { # this is probably quite wrong, I have to figure out the internal structure of nodes better
    $xp_field     = 11; 
    $parent_field = 12;
  }

BEGIN
{ package XML::XPath::NodeSet;
  no warnings; # to avoid the "Subroutine sort redefined" message
  # replace the native sort routine by a custom one
  sub sort 
    { my $self = CORE::shift;
      @$self = CORE::sort { $a->cmp( $b) } @$self;
      return $self;
    }
}

package XML::DOM::Document;

sub findnodes           { my( $dom, $path)= @_; return $dom->xp->findnodes(           $path, $dom); }
sub findnodes_as_string { my( $dom, $path)= @_; return $dom->xp->findnodes_as_string( $path, $dom); }
sub findvalue           { my( $dom, $path)= @_; return $dom->xp->findvalue(           $path, $dom); }
sub exists              { my( $dom, $path)= @_; return $dom->xp->exists(              $path, $dom); }
sub find                { my( $dom, $path)= @_; return $dom->xp->find(                $path, $dom); }
sub matches             { my( $dom, $path)= @_; return $dom->xp->matches( $dom, $path, $dom); }
sub set_namespace       { my $dom= shift; $dom->xp->set_namespace( @_); }

sub getRootNode { return $_[0]; }
sub xp { return $_[0]->[$xp_field] }

{ no warnings;
  # copied from the original DOM packege, with the addition of the creation of the XML::XPath object
  sub new
    { my ($class) = @_;
      my $self = bless [], $class;

      # keep Doc pointer, even though getOwnerDocument returns undef
      $self->[_Doc] = $self;
      $self->[_C] = new XML::DOM::NodeList;
      $self->[$xp_field]= XML::XPath->new();
      $self;
    }
}

package XML::DOM::Node;

sub findnodes           { my( $node, $path)= @_; return $node->xp->findnodes(           $path, $node); }
sub findnodes_as_string { my( $node, $path)= @_; return $node->xp->findnodes_as_string( $path, $node); }
sub findvalue           { my( $node, $path)= @_; return $node->xp->findvalue(           $path, $node); }
sub exists              { my( $node, $path)= @_; return $node->xp->exists(              $path, $node); }
sub find                { my( $node, $path)= @_; return $node->xp->find(                $path, $node); }
sub matches             { my( $node, $path)= @_; return $node->xp->matches( $node->getOwnerDocument, $path, $node); }

sub to_number { return XML::XPath::Number->new( shift->string_value); }

sub getParent   { return $_[0]->getParentNode; }
sub getRootNode { return $_[0]->getOwnerDocument; }

sub xp { return $_[0]->getOwnerDocument->xp; }

sub cmp
  { my( $a, $b)=@_;

    # easy cases
    return  0 if( $a == $b);    
    return -1 if( $a->isAncestor($b)); # a starts before b 
    return  1 if( $b->isAncestor($a)); # a starts after b

    # special case for 2 attributes of the same element
    # order is dictionary order of the attribute names
    if( $a->isa( 'XML::DOM::Attr') && $b->isa( 'XML::DOM::Attr')
        && ($a->getParent == $b->getParent)
      )
      { return $a->getName cmp $b->getName }

    # ancestors does not include the element itself
    my @a_pile= ($a->ancestors_or_self); 
    my @b_pile= ($b->ancestors_or_self);

    # the 2 elements are not in the same twig
    return undef unless( $a_pile[-1] == $b_pile[-1]);

    # find the first non common ancestors (they are siblings)
    my $a_anc= pop @a_pile;
    my $b_anc= pop @b_pile;

    while( $a_anc == $b_anc) 
      { $a_anc= pop @a_pile;
        $b_anc= pop @b_pile;
      }

    # from there move left and right and figure out the order
    my( $a_prev, $a_next, $b_prev, $b_next)= ($a_anc, $a_anc, $b_anc, $b_anc);
    while()
      { $a_prev= $a_prev->getPreviousSibling || return( -1);
        return 1 if( $a_prev == $b_next);
        $a_next= $a_next->getNextSibling || return( 1);
        return -1 if( $a_next == $b_prev);
        $b_prev= $b_prev->getPreviousSibling || return( 1);
        return -1 if( $b_prev == $a_next);
        $b_next= $b_next->getNextSibling || return( -1);
        return 1 if( $b_next == $a_prev);
      }
  }

sub ancestors_or_self
  { my $node= shift;
    my @ancestors= ($node);
    while( $node= $node->getParent)
      { push @ancestors, $node; }
    return @ancestors;
  }

sub getNamespace
  { my $node= shift;
    my $prefix= shift() || $node->ns_prefix;
    if( my $expanded= $node->get_namespace( $prefix))
      { return XML::DOM::Namespace->new( $prefix, $expanded); }
    else
      { return XML::DOM::Namespace->new( $prefix, ''); }
  }

sub getLocalName
  { my $node= shift;
    (my $local= $node->getName)=~ s{^[^:]*:}{};
    return $local;
  }

sub ns_prefix
  { my $node= shift;
    if( $node->getName=~ m{^([^:]*):})
      { return $1; }
    else
      { return( '#default'); } # should it be '' ?
  }

BEGIN 
  { my %DEFAULT_NS= ( xml   => "http://www.w3.org/XML/1998/namespace",
                      xmlns => "http://www.w3.org/2000/xmlns/",
                    );
 
    sub get_namespace
      { my $node= shift;
        my $prefix= defined $_[0] ? shift() : $node->ns_prefix;
        if( $prefix eq "#default") { $prefix=''}
        my $ns_att= $prefix ? "xmlns:$prefix" : "xmlns";
        my $expanded= $DEFAULT_NS{$prefix} || $node->inherit_att( $ns_att) || '';
        return $expanded;
      }
  }

sub inherit_att
  { my $node= shift;
    my $att= shift;

    do 
      { if( ($node->getNodeType == ELEMENT_NODE) && ($node->getAttribute( $att)))
          { return $node->getAttribute( $att); }
      } while( $node= $node->getParentNode);
    return undef;
  }
  
package XML::DOM::Element;

sub getName { return $_[0]->getTagName; }

{ no warnings;

# this method exists in XML::DOM but it returns a NamedNodeMap object
# XML::XPath needs it, but wants an array... bother!
sub getAttributes
  { # in any case we need $_[0]->[_A]  to be filled
    $_[0]->[_A] ||= XML::DOM::NamedNodeMap->new (Doc  => $_[0]->[_Doc], Parent  => $_[0]);

    unless( caller(0)=~ m{^XML::XPath})
      { # the original XML::DOM value
        return $_[0]->[_A]; 
      }
    else
      { # this is what XML::XPath needs
        my $elt= shift;
        my @atts= grep { ref $_ eq 'XML::DOM::Attr' } values %{$elt->[1]};
        $_->[$parent_field]= $elt foreach (@atts);
        return wantarray ? @atts : \@atts;
      }
  }

}

# nearly straight from XML::XPath
sub string_value
  { my $self = shift;
    my $string = '';
    foreach my $kid ($self->getChildNodes) 
      { if ($kid->getNodeType == ELEMENT_NODE || $kid->getNodeType == TEXT_NODE) 
          { $string .= $kid->string_value; }
      }
    return $string;
  }


  
package XML::DOM::Attr;

# needed for the sort
sub getParent
  { return $_[0]->[$parent_field]; }

sub string_value
  { return $_[0]->getValue; }


sub inherit_att
  { return $_[0]->getParent->inherit_att( @_); }

package XML::DOM::Text;
sub string_value
  { return $_[0]->getData; }

package XML::DOM::Namespace;

sub new
  { my( $class, $prefix, $expanded)= @_;
    bless { prefix => $prefix, expanded => $expanded }, $class;
  }

sub isNamespaceNode { 1; }

sub getPrefix   { $_[0]->{prefix};   }
sub getExpanded { $_[0]->{expanded}; }
sub getValue    { $_[0]->{expanded}; }
sub getData     { $_[0]->{expanded}; }


1;
__END__

=head1 NAME

XML::DOM::XPath - Perl extension to add XPath support to XML::DOM, using XML::XPath engine

=head1 SYNOPSIS

  use XML::DOM::XPath;

  my $parser= XML::DOM::Parser->new();
  my $doc = $parser->parsefile ("file.xml");

  # print all HREF attributes of all CODEBASE elements
  # compare with the XML::DOM version to see how much easier it is to use
  my @nodes = $doc->findnodes( '//CODEBASE[@HREF]/@HREF');
  print $_->getValue, "\n" foreach (@nodes);

=head1 DESCRIPTION

XML::DOM::XPath allows you to use XML::XPath methods to query
a DOM. This is often much easier than relying only on getElementsByTagName.

It lets you use all of the XML::DOM methods.

=head1 METHODS

Those methods can be applied to a whole dom object or to a node.

=head2 findnodes($path)

return a list of nodes found by $path.

=head2 findnodes_as_string($path)

return the nodes found reproduced as XML. The result is not guaranteed
to be valid XML though.

=head2 findvalue($path)

return the concatenation of the text content of the result nodes

=head2 exists($path)

return true if the given path exists.

=head2 matches($path)

return true if the node matches the path.


=head1 SEE ALSO

  XML::DOM

  XML::XPath

=head1 AUTHOR

Michel Rodriguez, mirod@cpan.org

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Michel Rodriguez

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
