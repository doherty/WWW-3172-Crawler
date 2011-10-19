package WWW::3172::Crawler;
use strict;
use warnings;
# ABSTRACT: A simple web crawler for CSCI 3172 Assignment 1
# VERSION

use URI::WithBase;
use Data::Validate::URI qw(is_web_uri);
use List::UtilsBy qw(nsort_by);
use List::MoreUtils qw(uniq);
use HTML::TokeParser::Simple ();
use HTML::TreeBuilder ();
use Lingua::Stem::Snowball ();
use Lingua::StopWords qw(getStopWords);
use Text::Unidecode qw(unidecode);
use LWP::RobotUA ();
use Time::HiRes qw(time);
use namespace::autoclean;
use Moose;
use Moose::Util::TypeConstraints;

=head1 SYNOPSIS

    use WWW::3172::Crawler;
    my $crawler = WWW::3172::Crawler->new(host => 'http://hashbang.ca', max => 50);
    my $stats = $crawler->crawl;
    # Present the stats however you want

=cut

has 'host' => (
    is      => 'rw',
    isa     => subtype(as 'Str', where { _fix_url($_) }),
    required=> 1,
);

has 'max' => (
    is      => 'ro',
    isa     => 'Num',
    default => 200,
);

has 'delay' => (
    is      => 'ro',
    isa     => 'Num',
    default => 1/60,
);

has 'ua' => (
    is      => 'ro',
    isa     => 'LWP::UserAgent',
    required=> 1,
    default => sub {
        LWP::RobotUA->new(
            agent   => (__PACKAGE__ . '/' . (defined __PACKAGE__->VERSION ? __PACKAGE__->VERSION : 'dev')),
            from    => 'doherty@cs.dal.ca',
            timeout => 30,
            delay   => shift->delay,
        );
    },
    lazy    => 1,
    handles => ['get'],
);

has 'data' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} },
);

has 'crawled' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} },
);

has 'to_crawl' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { return { shift->host => 1 }; },
    lazy    => 1,
);

has 'debug' => (
    is      => 'rw',
    isa     => (subtype as 'Int', where { defined $_ and $_ >= 0 }),
    default => 0,
);

has 'stemmer' => (
    is      => 'ro',
    isa     => 'Lingua::Stem::Snowball',
    default => sub {
        return Lingua::Stem::Snowball->new(
            lang        => 'en',
            encoding    => 'UTF-8',
        );
    },
    lazy    => 1,
    required=> 1,
);

has 'stopwords' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { getStopWords('en', 'UTF-8'); },
    lazy    => 1,
    required=> 1,
);

has 'callback' => (
    is          => 'rw',
    isa         => 'CodeRef',
    clearer     => 'clear_callback',
    predicate   => 'has_callback',
);

=head1 METHODS

=head2 new

The constructor takes a mandatory 'host' parameter, which specifies the starting
point for the crawler. The 'max' parameter specifies how many pages to visit,
defaulting to 200.

Additional settings are:

=over 4

=item * debug - whether to print debugging information

=item * ua - a L<LWP::UserAgent> object to use to crawl. This can be used to
provide a mock useragent which doesn't connect to the internet for testing.

=item * callback - a coderef which gets called for each page crawled. The
coderef is called with two parameters: the URL and a hashref of data. This can
be used to do incremental processing, instead of doing the crawl run all at once
and returning a large hashref of data. This also reduces memory requirements.

    WWW::3172::Crawler->new(
        host    => 'http://google.com',
        callback=> sub {
            my $url  = shift;
            my $data = shift;
            print "Got data about $url:\n";
            print "Stems: @{ $data->{stems} }\n";
        },
    )->crawl;

=back

=cut

sub _fetch {
    my $self = shift;
    my $uri  = shift;

    my $start = time;
    my $page = $self->get($uri);
    return unless $page->is_success;

    $self->crawled->{$uri}++;
    $self->data->{$uri}->{speed} = time - $start - $self->delay; # Don't forget to account for the wait time;
    $self->data->{$uri}->{size} = $page->content_length
        || length $page->decoded_content;

    return $page;
}

sub _parse {
    my $self = shift;
    my $uri  = shift;
    my $html = shift;

    return unless $html;

    my $parser = HTML::TokeParser::Simple->new(string => $html);
    PARSE: while (my $token = $parser->get_token) {
        if ($token->is_tag('meta')) { # a meta tag! - something to remember & report back later
            my $attr = $token->get_attr || next PARSE;
            my $type = $attr->{name}    || next PARSE;
            next PARSE unless $type =~ m/^(?:description|keywords)$/;

            $self->data->{$uri}->{$type} = $attr->{content};
        }
        elsif ($token->is_tag('a')) { # a link! - something to crawl in the future
            my $attr = $token->get_attr             || next PARSE;
            my $href = _fix_url($attr->{href}, $uri)|| next PARSE;

            $self->to_crawl->{ $href }++ # We can track what pages are popular
                unless $self->crawled->{ $href };
        }
        elsif ($token->is_tag('img')) { # an image! - something to... download?! O.o
            my $attr = $token->get_attr             || next PARSE;
            my $href = _fix_url($attr->{src}, $uri) || next PARSE;

            $self->to_crawl->{ $href }++
                unless $self->crawled->{ $href };
        }
        elsif ($token->is_tag('source')) { # HTML5 audio/video
            my $attr = $token->get_attr             || next PARSE;
            my $href = _fix_url($attr->{src}, $uri) || next PARSE;

            $self->to_crawl->{ $href }++
                unless $self->crawled->{ $href };
        }
        else {
            next PARSE;
        }
    }

    return;
}

sub _fix_url {
    my $url     = shift;
    my $source  = shift;

    return $url if is_web_uri($url);

    my $fixed_url = URI::WithBase->new($url, $source);
    return $fixed_url->abs->as_string
        if defined is_web_uri($fixed_url->abs->as_string);

    return;
}

sub _next_uri_to_crawl {
    my $self = shift;

    my @links = nsort_by { $self->to_crawl->{$_} } keys %{ $self->to_crawl };

    my $url = pop @links;
    return unless $url;
    delete $self->to_crawl->{$url};

    print STDERR "Next URL: $url\n" if $self->debug and $self->debug > 1;
    return $url;
}

sub _stem {
    my $self = shift;
    my $url  = shift;

    my $text;
    {
        my $tree = HTML::TreeBuilder->new();
        $tree->parse_content(shift);
        $tree->elementify();
        $text = $tree->as_text;
        $tree->delete;
    }

    my $punct = quotemeta q{.,[]()<>{}+-=_'"\|};
    my @split = map { ## no critic (ControlStructures::ProhibitMutatingListFunctions)
        s{\A[$punct]}{};
        s{[$punct]\Z}{};

        length($_) < 2 || exists $self->stopwords->{$_}
            ? ()
            : unidecode($_)
    } split /\s+|\b/, $text;
    my @words = $self->stemmer->stem(\@split);

    my %stems;
    $stems{$_}++ for @words;

    $self->data->{$url}->{stems} = \%stems;
}

=head2 crawl

Begins crawling at the provided link, collecting statistics as it goes. The
robot respects F<robots.txt>. At the end of the crawling run, reports some
basic statistics for each page crawled:

=over 4

=item *

Description meta tag

=item *

Keywords meta tag

=item *

Page size

=item *

Load time

=item *

Page text

=item *

Keywords extracted from page text using the following technique:

=over 4

=item 1)

Split page text on whitespace

=item 2)

Skip L<stopwords|Lingua::Stopwords>

=item 3)

L<"Normalize"|Text::Unidecode> to remove non-ASCII characters

=item 4)

Run L<Porter's stemming algorithm|Lingua::Stem::Snowball>

=back

=back

The data is returned as a hash keyed on URL.

Image, video, and audio are also fetched, evaluated for size and speed.

Crawling ends when there are no more URLs in the crawl queue, or the maximum
number of pages is reached.

URLs are crawled in order of the number of appearances the crawler has seen.
This is somewhat similar to Google's PageRank algorithm, where popularity of a
page, as measured by inbound links, is a major factor in a page's ranking in
search results.

=cut

sub crawl {
    my $self = shift;

    my $pages_crawled = 0;
    CRAWL: while ( my $uri = $self->_next_uri_to_crawl() ) {
        last CRAWL if !defined($uri);
        next CRAWL if $self->crawled->{$uri};
        print STDERR 'Crawling #' . ($pages_crawled+1) . '/' . $self->max . ": $uri\n" if $self->debug;

        my $res = $self->_fetch($uri) || next CRAWL;

        if ($res->content_type eq 'text/html') {
            $self->_parse($uri, $res->decoded_content);
            $self->_stem($uri, $res->decoded_content);
        }
        elsif ($res->content_type =~ m{^(?:image|audio|video)/}) {
            print STDERR "$uri is a binary format: " . $res->content_type . "\n" if $self->debug and $self->debug > 1;
            $self->_parse($uri);
        }
        else {
            warn "$uri is an unknown type: " . $res->content_type;
        }

        $self->callback->($uri, delete $self->data->{$uri}) if $self->has_callback;

        last CRAWL if ++$pages_crawled >= $self->max;
    }

    return if $self->has_callback;
    return $self->data;
}

__PACKAGE__->meta->make_immutable;

1;

