# $Id: xmlxpath_20axisa_or_s.t,v 1.1.1.1 2003/12/04 20:40:43 mrodrigu Exp $

use Test;
plan( tests => 4);
use XML::DOM::XPath;
ok(1);

my $parser= XML::DOM::Parser->new;
my $t= $parser->parse( \*DATA); 

ok( $t);

my @nodes;
@nodes = $t->findnodes( '/AAA/XXX/DDD/EEE/ancestor-or-self::*');
ok(@nodes, 4);

@nodes = $t->findnodes( '//GGG/ancestor-or-self::*');
ok(@nodes, 5);

__DATA__
<AAA>
<BBB><CCC/><ZZZ><DDD/></ZZZ></BBB>
<XXX><DDD><EEE/><DDD/><CCC/><FFF/><FFF><GGG/></FFF></DDD></XXX>
<CCC><DDD/></CCC>
</AAA>
