#!perl
use strict;
use warnings;
use Test::More tests => 3;
use Test::Mock::LWP::Dispatch ();
use HTTP::Response;
use HTTP::Headers;
use WWW::3172::Crawler;

sub mock_response {
    my $req = shift;
    die 'Unsupported method: ' . $req->method unless $req->method eq 'GET';

    my $uri     = $req->uri;
    my ($file)  = $uri =~ m{\Qhttp://127.0.0.1/\E(.*)$};
    my ($ext)   = $file =~ m{\.(.*)$};

    my $html    = do { open my $in, '<', "t/$file" or die $!; local $/; <$in> };
    my $res     = HTTP::Response->new(
        200,
        'OK',
        HTTP::Headers->new(
            'Content-Length'    => length $html,
            'Content-Type'      => ($ext eq 'html' ? 'text/html' : "audio/$ext"),
        ),
        $html
    );
    return $res;
}

my $url = 'http://127.0.0.1/html5audio.html';

my $mock_ua = LWP::UserAgent->new(); # Mocked LWP::UserAgent!
$mock_ua->map(
    qr{http://127.0.0.1/.*},
    \&mock_response,
);

my $crawler = WWW::3172::Crawler->new(
    host    => $url,
    ua      => $mock_ua,
    max     => 2,
);
my $data = $crawler->crawl;

isa_ok($data, 'HASH');
isa_ok($crawler->to_crawl, 'HASH');

my @is = (keys %$data, keys %{ $crawler->to_crawl });
my @ought = ('http://127.0.0.1/horse.mp3', 'http://127.0.0.1/horse.ogg', $url);

is_deeply( [sort @is], [sort @ought], 'Audio URLs added to crawl list')
    or diag explain {is => \@is, ought => \@ought};

