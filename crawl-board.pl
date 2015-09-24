#!/usr/bin/env perl6
use v6;

use File::Directory::Tree;
use HTTP::UserAgent;
use HTML::Parser::XML;

my constant PTT_URL = "https://www.ptt.cc";

sub ptt_get($url) {
    state $ua = HTTP::UserAgent.new;
    my $res = $ua.get($url);
    if $res.is-success {
        return $res
    } else {
        die $res.status-line
    }
}

sub download_articles(@articles, $output_dir) {
    for @articles -> $a {
        say $a;
    }
}

sub harvest_articles(Str $url, Str $board_name) {
    say "$url == $board_name";
    my $res = ptt_get($url);
    my $html = $res.content;
    my $dom = HTML::Parser::XML.new.parse($html);
    my @articles;
    for $dom.elements(:TAG<a>, :RECURSE<99>, :href) -> $el {
        if (my $href = $el.attribs<href>) ~~ rx/ M \. <[0..9]>+ \. A \. <[A..Z0..9]>**3 \.html $/ {
            @articles.push: ${ :subject($el.contents.join), :url(PTT_URL ~ $href) };
        }
    }
    return @articles;
}

sub harvest_board_indices(Str $board_url, Str $board_name) {
    my $res = ptt_get($board_url);
    my $html = $res.content;
    my $dom = HTML::Parser::XML.new.parse($html);

    my @boards;
    for $dom.elements(:TAG<a>, :RECURSE<99>, :href) -> $el {
        if (my $href = $el.attribs<href>) ~~ rx/index (<[0..9]>+) \.html $/ {
            @boards.push: ${ :page_number($0), :url(PTT_URL ~ $href) };
        }
    };
    @boards = @boards[1,0] if @boards[0]<page_number> > @boards[1]<page_number>;
    for @boards[0]<page_number> .. @boards[1]<page_number> -> $n {
        @boards.push: ${ :page_number($n), :url( PTT_URL ~ "/bbs/$board_name/index$n.html" ) }
    }
    return @boards;
}

sub main(Str $board_name, Str $output_dir) {
    my $board_url = PTT_URL ~ "/bbs/{ $board_name }/index.html";
    my $output_board_dir = "{ $output_dir }/{ $board_name }";

    mktree( $output_board_dir );

    my @board_indices = harvest_board_indices($board_url, $board_name);
    for @board_indices.sort({ $^b.<page_number> <=> $^a.<page_number> }) -> $board {
        my @articles = harvest_articles($board.<url>, $board_name);
        download_articles(@articles, $output_board_dir);
    }
}

main(@*ARGS[0], @*ARGS[1]);
