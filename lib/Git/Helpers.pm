use strict;
use warnings;

package Git::Helpers;

use Carp qw( croak );
use File::pushd qw( pushd );
use Git::Sub;
use Sub::Exporter -setup => { exports =>
        [ 'checkout_root', 'https_remote_url', 'remote_url', 'travis_url', ]
};
use Try::Tiny qw( catch try );
use URI ();
use URI::FromHash qw( uri );
use URI::Heuristic qw(uf_uristr);
use URI::git ();

sub checkout_root {
    my $dir = shift;

    my $new_dir;
    $new_dir = pushd($dir) if $dir;

    my $root;
    try {
        $root = scalar git::rev_parse qw(--show-toplevel);
    }
    catch {
        $dir ||= '.';
        croak "Error in $dir $_";
    };
    return $root;
}

sub https_remote_url {
    my $remote_url = remote_url(shift);

    # remove trailing .git
    $remote_url =~ s{\.git\z}{};

    # remove 'git@' from git@github.com:username/repo.git
    $remote_url =~ s{\w*\@}{};

    # remove : from git@github.com:username/repo.git
    $remote_url =~ s{(\w):(\w)}{$1/$2};

    my $uri = URI->new( uf_uristr($remote_url) );
    $uri->scheme('https');
    return $uri;
}

sub remote_url {
    my $remote = shift || 'origin';
    return git::remote( 'get-url', $remote );
}

sub travis_url {
    my $remote_url = https_remote_url(shift);
    my $url        = URI->new($remote_url);
    return uri(
        scheme => 'https',
        host   => 'travis-ci.org',
        path   => $url->path,
    );
}

1;

#ABSTRACT: Shortcuts for common Git commands

=pod

=head1 SYNOPSIS

    use Git::Helpers qw( checkout_root remote_url);
    my $root = checkout_root();

    my $remote_url = remote_url('upstream');
    my $https_remote_url = https_remote_url();
    my $travis_url = travis_url();

=head2 checkout_root( $dir )

Gives you the root level of the git checkout which you are currently in.
Optionally accepts a directory parameter.  If you provide the directory
parameter, C<checkout_root> will temporarily C<chdir> to this directory and
find the top level of the repository.

This method will throw an exception if it cannot find a git repository at the
directory provided.

=head2 https_remote_url( $remote_name )

This is a browser-friendly URL for the remote, fixed up in such a way that
GitHub (hopefully) doesn't need to redirect your URL.

Turns git@github.com:oalders/git-helpers.git into https://github.com/oalders/git-helpers

Turns https://github.com/oalders/git-helpers.git into https://github.com/oalders/git-helpers

Defaults to using C<origin> as the remote if none is supplied.

=head2 remote_url( $remote_name )

Returns a URL for the upstream you've requested by name.  Defaults to 'origin'.
Provides you with the exact URL which git returns. Nothing is fixed up for you.

    # defaults to 'origin'
    my $remote_url = remote_url();
    # $remote_url is now possibly something like one of the following:
    # git@github.com:oalders/git-helpers.git
    # https://github.com/oalders/git-helpers.git

    # get URL for upstream remote
    my $remote_url = remote_url('upstream');

=head2 travis_url( $remote_name )

Returns a L<travis-ci.org> URL for the upstream you've requested by name.  Defaults to 'origin'.

    # get Travis URL for remote named "origin"
    my $origin_travis_url = travis_url();

    # get Travis URL for remote named "upstream"
    my $upstream_travis_url = travis_url('upstream');

=cut
