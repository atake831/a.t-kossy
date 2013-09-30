package secondapp::Web;

use strict;
use warnings;
use utf8;
use Kossy;

use Data::Dumper;
use DateTime;
use Encode qw(encode_utf8);
use DateTime::Format::Strptime;
use Time::Piece;
use Time::Seconds;
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

get '/' => sub{
    my ( $self, $c ) = @_;
    my $dbi = get_dbi();
    my $content = $dbi->select(table => 'content');
    print Dumper "-----------";
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
	my $dbi = get_dbi();
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
    $c->redirect($c->req->uri_for("/"));
};

sub delete{
    my $self = shift;
    my ( $delete_id ) = @_;
    $delete_id = "" if ! defined $delete_id;
    my $dbi = get_dbi();
    my $delete_todo = $dbi->delete(
	where => {id => $delete_id}, 
	table => 'content'
	);
};

post '/delete' => sub{
    my ($self, $c) = @_;
    my $result = $c->req->validator([
	'delete_id' => { rule => [ ['NOT_NULL', 'empty delete_id'],],},
				    ]);
    $self->delete(map {$result->valid($_)} qw/delete_id/);
    $c->redirect($c->req->uri_for("/"));
};

get '/edit' => sub{
    my ( $self, $c ) = @_;
    my $result = $c->req->validator([
	'update_id' => {rule => [ ['NOT_NULL','empty update_id'],],},]);
    my $update_id = $result->valid->get('update_id');
    my $dbi = get_dbi();
    $dbi->order->prepend();
    my $update_data = $dbi->select(
	where => {id => $update_id}, 
	table => 'content'
	);
    print Dumper $update_id;
    $c->render('edit.tx',{
	    update_data => $update_data,
	       }
	);
};

sub update{
    my $self = shift;
    my ( $update_id, $title, $memo, $priority, $status, $deadline ) = @_;
    $update_id = "" if ! defined $update_id;
    $title = "" if ! defined $title;
    $memo = "" if ! defined $memo;
    $priority = "" if ! defined $priority;
    $status = "" if ! defined $status;
    $deadline = "" if ! defined $deadline;

    if (length($memo) < 255){
	print Dumper $deadline;
	my $dbi = get_dbi();
	my $update_todo = $dbi->update({
	    title => $title,
	    memo => $memo,
	    priority => $priority,
	    status => $status,
	    deadline => $deadline,
				       }, 
		 		       table => 'content',
				       where =>{id => $update_id});
    }
};

post '/update' => sub {
    my ( $self, $c ) = @_;
    my $result = $c->req->validator([
    'update_id' => {	rule => [ ['NOT_NULL','empty update_id'],],},
    'title' => {	rule => [ ['NOT_NULL','empty title'],],},
    'memo' => {	rule => [ ['NOT_NULL','empty memo'],],},
    'priority' => {	rule => [ ['NOT_NULL','empty priority'],],},
    'status' => {	rule => [ ['NOT_NULL','empty status'],],},
    'deadline' => {	rule => [ ['NOT_NULL','empty deadline'],],},
				]);
    $self->update(map {$result->valid($_)} qw/update_id title memo priority status deadline/);
    $c->redirect($c->req->uri_for("/"));
};

get '/graph' => sub{
    my ( $self, $c ) = @_;
    my $dbi = get_dbi();
    my $content = $dbi->select(table => 'content');
    my $dt = localtime;
    my @view_week;
    my @busy_point;
    for (my $i = 0 ; $i < 7 ; $i++){
	$busy_point[$i] = 0;
	$content = $dbi->select(table => 'content');
	while (my $row = $content->fetch_hash){
	    if ($row->{status} == 1) {
		my $deadline = 
		    Time::Piece->strptime(
			$row->{deadline}, 
			'%Y-%m-%d %H:%M:%S');
		my $sub_date = $deadline - $dt;
		#print Dumper $deadline->ymd;
		#print Dumper $dt->ymd;
		#print Dumper int($sub_date->days);
		#print Dumper "*********";
		
		if ($sub_date->days > 0){
		    my $rest_days = int($sub_date->days);
		    if( $rest_days > 9 ) {
			$rest_days = 9;
		    }
		    $busy_point[$i] += $row->{priority}*(10 - $rest_days);
		}
	    } 
	}
	$view_week[$i] = $dt->strftime('%A');
	$dt += ONE_DAY;
	print Dumper $view_week[$i];
	print Dumper $busy_point[$i];
	print Dumper "--------";
    }
    $c->render('graph.tx',{week => \@view_week,busy_point => \@busy_point});
};

sub get_dbi {
	my $dbi = DBIx::Custom->connect(
	    dsn => "dbi:mysql:database=kossy",
	    user => "kossyuser", 
	    password => "kossypass",
	    option => {mysql_enable_utf8 => 1});
	return $dbi;
}

1;

