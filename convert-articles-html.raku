#!/usr/bin/env raku
use JSON::Fast;
use File::Find;
use HTML::Parser::XML;

sub convert_and_save(IO::Path $file) {
    my %article = ( meta => [], push => [], body => "" );
    my $html = slurp $file;
    my $dom = HTML::Parser::XML.new.parse($html);
    my $node-main-content = $dom.getElementById("main-content");
    return unless $node-main-content;

    for $node-main-content.elements(:TAG<div>, :RECURSE<9>, :class<article-metaline>) -> $node {
        my @meta-tags   = $node.elements(:TAG("span"), :class("article-meta-tag"));
        my @meta-values = $node.elements(:TAG("span"), :class("article-meta-value"));
        for zip(@meta-tags; @meta-values) -> ($t, $v) {
            my $h = {
                tag   => $t[0].contents.join,
                value => $v[0].contents.join,
            };
            %article<meta>.push($h);
        }
        $node.remove();
    }

    for $node-main-content.elements(:TAG<div>, :class<push>) -> $node {
        my $tag        = $node.elements(:TAG<span>, :SINGLE(True), :class(/tag/));
        my $userid     = $node.elements(:TAG<span>, :SINGLE(True), :class(/userid/));
        my $content    = $node.elements(:TAG<span>, :SINGLE(True), :class(/content/));
        my $ipdatetime = $node.elements(:TAG<span>, :SINGLE(True), :class(/ipdatetime/));

        my $h = {
            :tag($tag.contents.join),
            :userid($userid.contents.join),
            :content($content.contents.join),
            :ipdatetime($ipdatetime.contents.join),
        };
        %article<push>.push($h);
        $node.remove();
    }

    %article<body> = $node-main-content.contents.join;

    my $output_file = "$file";
    $output_file ~~ s/ \.html $/.json/;
    spurt $output_file, to-json(%article);
    say "DONE $output_file ";
}

sub main(Str $input_dir) {
    my $i = 0;
    my $files = find( :dir($input_dir), :type('file'), :name( / \. html $/ ) );
    for @$files {
        convert_and_save($_);
    }
}

main(@*ARGS[0]);
