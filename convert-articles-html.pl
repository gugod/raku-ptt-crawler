#!/usr/bin/env perl6
use v6;

use JSON::Tiny;
use File::Find;
use XML::Query;
use HTML::Parser::XML;

sub convert_and_save(IO::Path $file) {
    say $file;
    my $parser = HTML::Parser::XML.new;
    my $html = $file.slurp-rest;
    $parser.parse($html);
    my $dom = $parser.xmldoc;
    my $xq = XML::Query.new($dom);

    say $xq("#main-content").first.elem;
}

sub main(Str $input_dir) {
    my $i = 0;
    my $files = find( :dir($input_dir), :type('file'), :name( / \. html $/ ) );
    for @$files {
        convert_and_save($_);
    }
}

main(@*ARGS[0]);
