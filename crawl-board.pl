#!/usr/bin/env perl6
use v6;

use File::Directory::Tree;
use HTTP::UserAgent;

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

    say $res.perl;

    my Hash @boards;
    my %h;
    @boards.push: ${ :page_number<1>, :url<"/foobar1"> };

    %h = :page_number<2>, :url<"/foobar2">;
    @boards.push: $%h;
    return @boards;
}

sub main(Str $board_name, Str $output_dir) {
    my $board_url = PTT_URL ~ "/bbs/{ $board_name }/index.html";
    my $output_board_dir = "{ $output_dir }/{ $board_name }";

    mktree( $output_board_dir );

    my @board_indices = harvest_board_indices($board_url, $board_name);
    say "---";
    say @board_indices.perl;
    my $i = 0;
    for @board_indices {
        say $i++;
        say .<page_number>;
        say .<url>;
    }
}

main(@*ARGS[0], @*ARGS[1]);
