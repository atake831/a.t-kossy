package secondapp::Web;

use strict;
use warnings;
use utf8;
use Kossy;

use DBI;
use DBIx::Custom;

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
    my $dbi = DBIx::Custom->connect(
	dsn => "dbi:mysql:database=kossy",
	user => "kossyuser", 
	password => "kossypass",
	option => {mysql_enable_utf8 => 1});
    my $content = $dbi->select(table => 'content');
    $c->render('db.tx', { 
	greeting => "Hello", 
	content => $content ,
	       }
	);
};

sub write{
    my $self = shift;
    my ( $title, $memo, $priority, $status, $deadline ) = @_;
    $title = "" if ! defined $title;
    $memo = "" if ! defined $memo;
    $priority = "" if ! defined $priority;
    $status = "" if ! defined $status;
    $deadline = "" if ! defined $deadline;

    if (length($memo) < 255){ 
	my $dbi = DBIx::Custom->connect(
	    dsn => "dbi:mysql:database=kossy",
	    user => "kossyuser", 
	    password => "kossypass",
	    option => {mysql_enable_utf8 => 1});
	my $insert_todo = $dbi->insert({
	    title => $title,
	    memo => $memo,
	    priority => $priority,
	    status => $status,
	    deadline => $deadline,
				       }, table => 'content');
    }
};

post '/write' => sub {
    my ( $self, $c ) = @_;
    my $result = $c->req->validator([
    'title' => {	rule => [ ['NOT_NULL','empty title'],],},
    'memo' => {	rule => [ ['NOT_NULL','empty memo'],],},
    'priority' => {	rule => [ ['NOT_NULL','empty priority'],],},
    'status' => {	rule => [ ['NOT_NULL','empty status'],],},
    'deadline' => {	rule => [ ['NOT_NULL','empty deadline'],],},
				]);
    $self->write(map {$result->valid($_)} qw/title memo priority status deadline/);
    $c->redirect($c->req->uri_for("/db"));
};

1;

