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

sub harvest_board_indices(Str $board_url, Str $board_name) {
    my $res = ptt_get($board_url);
    my $html = $res.content;
    my $dom = HTML::Parser::XML.new.parse($html);

    my @boards;
    for $dom.elements(:TAG<a>, :RECURSE<99>, :href) -> $el {
        if (my $href = $el.attribs<href>) ~~ rx/index (<[0..9]>+) \.html $/ {
            @boards.push: ${ :page_number($0), :url($href) };
        }
    };
    @boards = @boards[1,0] if @boards[0]<page_number> > @boards[1]<page_number>;
    for @boards[0]<page_number> .. @boards[1]<page_number> -> $n {
        @boards.push: ${ :page_number($n), :url("/bbs/$board_name/index$n.html" ) }
    }
    return @boards;
}

sub main(Str $board_name, Str $output_dir) {
    my $board_url = PTT_URL ~ "/bbs/{ $board_name }/index.html";
    my $output_board_dir = "{ $output_dir }/{ $board_name }";

    mktree( $output_board_dir );

    my @board_indices = harvest_board_indices($board_url, $board_name);

    .say for @board_indices;
}

main(@*ARGS[0], @*ARGS[1]);
