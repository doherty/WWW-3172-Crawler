package WWW::3172::Crawler;
use v5.10.1;
use strict;
use warnings;
# ABSTRACT: A simple web crawler for CSCI 3172 Assignment 1
# VERSION

use Data::Validate::URI qw(is_web_uri);
use List::UtilsBy qw(nsort_by);
use HTML::TokeParser::Simple ();
use LWP::RobotUA ();
use Time::HiRes qw(time);
use namespace::autoclean;
use Moose;
use Moose::Util::TypeConstraints;

=head1 SYNOPSIS

    use WWW::3172::Crawler;
    my $crawler = WWW::3172::Crawler->new(host => 'http://hashbang.ca', max => 50);
    $crawler->crawl;
    # ... prints out some stats when it is done

=cut

has 'host' => (
    is      => 'rw',
    isa     => subtype(as 'Str', where { is_web_uri($_) }),
    required=> 1,
);

has 'max' => (
    is      => 'ro',
    isa     => 'Num',
    default => 2,
);

has 'ua' => (
    is      => 'ro',
    isa     => 'LWP::UserAgent',
    required=> 1,
    default => sub {
        my $ua = LWP::RobotUA->new(
            agent   => (__PACKAGE__ . '/' . (defined __PACKAGE__->VERSION ? __PACKAGE__->VERSION : 'dev')),
            from    => 'doherty@cs.dal.ca',
            timeout => 30,
        );
        $ua->delay(0);#1/60); # crawl delay of only 1s
        return $ua;
    },
    lazy    => 1,
    handles => ['get'],
);

has 'data' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} },
);

has 'debug' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

=head1 METHODS

=cut

sub _fetch {
    my $self = shift;
    my $uri  = shift;

    my $start = time;
    my $page = $self->get($uri);
    my $elapsed = time - $start;

    $self->{crawled}->{$uri}++;
    return unless $page->is_success;

    $self->data->{$uri}->{size} = $page->headers->content_length || length $page->decoded_content;
    # If there are headers, but no Content-Length header, then we'll
    # get undef, which is wrong, so we need the extra fallback. The
    # first fallback is for if there aren't headers for some reason
    # (which I did encounter, surprisingly).
#    $self->data->{$uri}->{size} = (defined $page->headers
#        ? $page->headers->content_length
#        : length $page->decoded_content) || length $page->decoded_content;

    $self->data->{$uri}->{speed}= $elapsed;
    return $page->decoded_content;
}

sub _parse {
    my $self = shift;
    my $uri  = shift;
    my $html = shift;

    my $parser = HTML::TokeParser::Simple->new(string => $html);

    PARSE: while (my $token = $parser->get_token) {
        if ($token->is_tag('meta')) {
            my $attr = $token->get_attr || next PARSE;
            my $type = $attr->{name}    || next PARSE;
            next PARSE unless $type =~ m/description|keywords/;

            $self->data->{$uri}->{$type} = $attr->{content};
        }
        elsif ($token->is_tag('a')) { # something to crawl in the future
            my $attr = $token->get_attr || next PARSE;
            my $href = $attr->{href}    || next PARSE;
            is_web_uri($href)           || next PARSE;

            $self->{to_crawl}->{ $href }++
                unless $self->{crawled}->{ $href }; # We can track what pages are popular
        }
        else {
            next PARSE;
        }
    }

    return;
}

sub _next_uri_to_crawl {
    my $self = shift;

    if ( $self->{crawled}->{ $self->host } ) {
        my @links = nsort_by { $self->{to_crawl}->{$_} } keys %{ $self->{to_crawl} };

        my $url = pop @links;
        my $uri = URI->new($url);
        delete $self->{to_crawl}->{$url};

        return $uri;
    }
    else {
        return $self->host;
    }
}

=head2 crawl

Begins crawling at the provided link, collecting statistics as it goes. The
robot respects F<robots.txt>. At the end of the crawling run, reports some
basic statistics for each page crawled:

=over 4

=item *

description meta tag

=item *

keywords meta tag

=item *

page size

=item *

load times

=item *

TODO: W3C validation report from http://validator.w3.org/

=item *

TODO: Accessibility validation report from http://achecker.ca/checker/index.php

=item *

TODO: Fetch and parse pages in parallel.

=back

The data is returned as a hash keyed on URL.

=cut
# Hash page content to detect aliases
# Multithreading

sub crawl {
    my $self = shift;

    my $pages_crawled = 0;
    CRAWL: while ( my $uri = $self->_next_uri_to_crawl() ) {
        last CRAWL if $pages_crawled >= $self->max;
        next CRAWL if $self->{crawled}->{$uri};
        say STDERR 'Crawling #' . ($pages_crawled+1) . '/' . $self->max . ": $uri" if $self->debug;

        my $html = $self->_fetch($uri) || next CRAWL;
        $self->_parse($uri, $html);
        $pages_crawled++;
    }

    return $self->data;
}

__PACKAGE__->meta->make_immutable;

1;

