#!/usr/bin/env raku
use File::Directory::Tree;
use HTTP::UserAgent;
use HTTP::Request;
use HTML::Parser::XML;

my constant PTT_URL = "https://www.ptt.cc";

sub ptt_get($url) {
    state $ua = HTTP::UserAgent.new;
    state $req = HTTP::Request.new(GET => $url, Cookie => "over18=1");
    return $ua.request($req);
}

sub download_articles(@articles, $output_dir) {
    for @articles -> $a {
        my $save_as = $output_dir ~ "/" ~ $a.<id> ~ ".html";
        next if $save_as.IO ~~ :f;
        my $res = ptt_get($a.<url>);
        if $res.is-success {
            spurt($save_as, $res.content);
            say "==> $save_as";
        }
    }
}

sub harvest_articles(Str $url, Str $board_name) {
    say "$url == $board_name";
    my $res = ptt_get($url);
    die $res.status-line unless $res.is-success;

    my $html = $res.content;
    my $dom = HTML::Parser::XML.new.parse($html);
    my @articles;
    for $dom.elements(:TAG<a>, :RECURSE<99>, :href) -> $el {
        if (my $href = $el.attribs<href>) ~~ rx/ (M \. <[0..9]>+ \. A \. <[A..Z0..9]>**3) \.html $/ {
            @articles.push: ${ :subject($el.contents.join), :id($0), :url(PTT_URL ~ $href) };
        }
    }
    return @articles;
}

sub harvest_board_indices(Str $board_url, Str $board_name) {
    my $res = ptt_get($board_url);
    die $res.status-line unless $res.is-success;

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

sub MAIN(Str $board_name, Str $output_dir) {
    my $board_url = PTT_URL ~ "/bbs/{ $board_name }/index.html";
    my $output_board_dir = "{ $output_dir }/{ $board_name }";

    mktree( $output_board_dir );

    my @board_indices = harvest_board_indices($board_url, $board_name);
    for @board_indices.sort({ $^b.<page_number> <=> $^a.<page_number> }) -> $board {
        my @articles = harvest_articles($board.<url>, $board_name);
        download_articles(@articles, $output_board_dir);
    }
}

