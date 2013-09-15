package secondapp::Web;

use strict;
use warnings;
use utf8;
use Kossy;

use DBI;

filter 'set_title' => sub {
    my $app = shift;
    sub {
        my ( $self, $c )  = @_;
        $c->stash->{site_name} = __PACKAGE__;
        $app->($self,$c);
    }
};

get '/' => [qw/set_title/] => sub {
    my ( $self, $c )  = @_;
    $c->render('index.tx', { greeting => "Hello" });
};

get '/json' => sub {
    my ( $self, $c )  = @_;
    my $result = $c->req->validator([
        'q' => {
            default => 'Hello',
            rule => [
                [['CHOICE',qw/Hello Bye/],'Hello or Bye']
            ],
        }
    ]);
    $c->render_json({ greeting => $result->valid->get('q') });
};

get '/db' => sub{
    my ( $self, $c ) = @_;
    my $dbh = DBI->connect("DBI:mysql:kossydb", "kossyuser", "kossypass");
    my $user = $dbh->prepare("select * from user");
    my $says = $dbh->prepare("select name,say from says inner join user on user.id = says.id_user");
    $user->execute;
    $says->execute;
    $c->render('db.tx', { 
	greeting => "Hello", 
	user => $user->fetchall_arrayref ,
	says => $says->fetchall_arrayref ,
	       }
	);
};

sub write{
    my $self = shift;
    my ( $body, $user_id ) = @_;
    $body = "" if ! defined $body;
    $user_id = "" if ! defined $user_id;
    if (length($body) < 255){ 
	my $dbh = DBI->connect("DBI:mysql:kossydb", "kossyuser", "kossypass");
	my $insert_say = $dbh->prepare("insert into says values(" . $user_id . ",'" . $body . "')");
	$insert_say->execute;
	$insert_say->finish();
	$dbh->disconnect();
    }
};


post '/write' => sub {
    my ( $self, $c ) = @_;
    my $result = $c->req->validator([
    'body' => {
	rule => [ ['NOT_NULL','empty body'],],
    },
    'user' => {
	rule => [ ['NOT_NULL','empty user'],],
    }
				]);
    $self->write(map {$result->valid($_)} qw/body user/);
    #$c->render_json({ body=>$self->write(map {$result->valid($_)} qw/body user/),error => 0, location => $c->req->uri_for("/db")->as_string});
    $c->redirect($c->req->uri_for("/db"));
};

1;

