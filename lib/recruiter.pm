package recruiter;
use Dancer ':syntax';

use URI;
use URI::QueryParam;
use Data::Dumper;
use LWP::UserAgent;
use HTTP::Request::Common qw(POST);
use Net::GitHub::V3;
use URI::Escape;
use Dancer::Plugin::Database;
use SQL::Maker;

our $VERSION = '0.1';

get '/' => sub {
    template 'index';
};

get '/oauth_github' => sub {
    my $uri = URI->new("https://github.com/login/oauth/authorize");
    $uri->query_form(
        client_id    => config->{gh_client_id},
        redirect_uri => config->{gh_redirect}
    );
    redirect $uri->as_string;
};

get '/ghregist' => sub {
    my $code = param('code');
    my %data = (
        client_id     => config->{gh_client_id},
        client_secret => config->{gh_secret},
        code          => $code
    );
    my $req = POST( "https://github.com/login/oauth/access_token", \%data );
    my $ua  = LWP::UserAgent->new;
    my $res = $ua->request($req);
    if ( $res->is_success ) {
        my $u = URI->new( "", "http" );
        $u->query( $res->content );
        my $token = $u->query_param("access_token");
        session access_token => $token;
    }
    template 'confirm';
};

post '/complete' => sub {
    my $token = session 'access_token';
    my $gh    = Net::GitHub::V3->new(
        access_token => $token,
        RaiseError   => 0,
        raw_string   => 1
    );
    my $user = from_json( $gh->user->show() );
    my $name = $user->{login};

    my $repos    = from_json( $gh->repos->list );
    my $issues   = from_json( $gh->issue->issues() );
    my @allpulls = ();
    for my $repo (@$repos) {
        if ( $name && $repo->{name} ) {
            my $u =
                "/repos/"
              . uri_escape($name) . "/"
              . uri_escape( $repo->{name} )
              . '/pulls';
            my $pulls = from_json( $gh->query($u) );
            push @allpulls, $pulls;
        }
    }

    my $gists = from_json( $gh->gist->gists );

    my $builder = SQL::Maker->new( driver => 'mysql' );
    my $u       = to_json($user);
    my $r       = to_json($repos);
    my $i       = to_json($issues);
    my $p       = to_json( \@allpulls );
    my $g       = to_json($gists);

    my ( $sql, @binds ) = $builder->insert(
        'recruits',
        {
            user         => $u,
            repos        => $r,
            issues       => $i,
            pullrequests => $p,
            gists        => $g,
            created_at   => \'now()',
            updated_at   => \'now()'
        }
    );

    my $sth = database->prepare($sql);
    $sth->execute(@binds);

    template 'complete';
};

true;
