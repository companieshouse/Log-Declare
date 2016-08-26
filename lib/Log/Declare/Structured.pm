package Log::Declare::Structured;
use strict;
use warnings;

use Log::Declare;
use Devel::Declare::Lexer;
use Devel::Declare::Lexer::Token::Raw;
use POSIX qw(strftime);
use Carp;
use DDP output => 'stdout';
use JSON;

our $VERSION = '0.1.0';

our $NAMESPACE; 

my $_HUMAN_READABLE = exists $ENV{'HUMAN_LOG'};

my $log_statement = "Log::Declare::Structured->log('%s', [%s], %s)%s";

BEGIN {
     my $callback = sub {
        my ($stream_r) = @_;
        my @stream = @$stream_r;

        # Get the declarator
        my $decl = Log::Declare->get_declarator(\@stream);

        # Remove any white space characters at the eol
        Log::Declare->remove_end_of_line_whitespace(\@stream);

        # Extract the conditional tokens
        my $condTokens = Log::Declare->get_conditional_tokens(\@stream);
        # Get the categories
        my $categories = Log::Declare->get_categories(\@stream);

        # Extract the anonymous hash
        # Work backwards from the end looking for categories
        my $nested = 0;
        my $hashStart = -1;
        for(my $i = $#stream; $i >= 0; $i--) {
            my ($token_type, $token_value) = (ref $stream[$i], $stream[$i]->{value});

            if($token_type eq 'Devel::Declare::Lexer::Token::RightBracket' &&
               $token_value eq '}') {
                $nested++;
                next;
            }
            if($token_type eq 'Devel::Declare::Lexer::Token::LeftBracket' &&
               $token_value eq '{') {
                $nested--;
                if($nested == 0) {
                    if($stream[$i-1] && ref($stream[$i-1]) ne 'Devel::Declare::Lexer::Token::Whitespace') {
                        next;
                    }
                    $hashStart = $i;
                    last;
                }
                next;
            }
        }

        # Convert the hash tokens into a string of hash key => values 
        my $hash;
        if($hashStart > -1) {
            for my $token (@stream[$hashStart .. $#stream-1]) {
                if (ref $token eq 'Devel::Declare::Lexer::Token::String'){
                    $hash .= "'$token->{value}'";
                }
                else {
                    $hash .= $token->{value};
                }
            }
        }

        # Reconstruct the log statement
        my $level = $decl->{value};
        my $cats = join ', ', @{$categories};
        my $cond = ' ' . join '', map { $_->get } @{$condTokens};

        my $output = Devel::Declare::Lexer::Token::Raw->new(
            value => sprintf($log_statement, $level, $cats, $hash, $cond)
        );

        return [
            $decl,
            Devel::Declare::Lexer::Token::Whitespace->new(value => ' '), $output,
            Devel::Declare::Lexer::Token::EndOfStatement->new,
            Devel::Declare::Lexer::Token::Newline->new
        ];
    };

    # Setup callbacks for each of the keywords
    Log::Declare->setup_callbacks($callback);
}

sub import {
    my ($class, @tags) = @_;

    $NAMESPACE = caller;

    Log::Declare->export_to_level(2, @tags);
}

sub log {
    my ($class, $level_name, $categories, $hash) = @_;


    $level_name = uc($level_name // '');

    # be forgiving if the log level is mistyped/invalid: it's going
    # to be easier to remove an unwanted log message than to track
    # down a bug that isn't being logged because of a typo
    my $level = $Log::Declare::LEVEL{$level_name} // $Log::Declare::LEVEL;

    return unless $level >= $Log::Declare::LEVEL;

    if(@$categories) {
        $hash->{categories} = sprintf '[%s]', join (', ', @$categories);
    }

    my ($event, $event_type) = ($level_name, q{});
    if (defined $hash->{context}){
        $event_type = 'C';
    }
    elsif (defined $hash->{request}){
        $event_type = 'R';
    }

    my $event_method = "__event${event_type}";

    return Log::Declare::Structured->$event_method( $event, $hash);
}

sub _event {
    my $event_type = shift;
    my $context    = shift;
    my $hash       = shift;

    my $data = {
                 created   => scalar gmtime,
                 event     => $event_type,
                 namespace => $NAMESPACE,
               };

    $data->{data}    = $hash;
    $data->{context} = $context if $context;

    p(%{$data})                     if $_HUMAN_READABLE;
    print STDOUT encode_json($data) if defined $data;

    return 1;
}

sub __eventR {
    my $class      = shift;
    my $event_type = shift;
    my $hash       = shift;

    _event($event_type, context(delete $hash->{request}), $hash);
}

sub __eventC {
    my $class      = shift;
    my $event_type  = shift;
    my $hash        = shift;

    _event($event_type, delete $hash->{context}, $hash);
} 

sub __event {
   my $class      = shift;
   my $event_type = shift;
   my $hash       = shift;

   _event($event_type, q{}, $hash);
}

sub context {
    my ($req) = @_;

    return $req->('X-Request-Id');
}

1;

__END__
 
=pod
 
=encoding UTF-8

=head1 NAME

Log::Declare::Structured - Structured logging based on Log::Declare

=head1 VERSION

version 0.1

=head1 SYNOPSIS

  ## in your script
  #!/usr/bin/perl

  use Log::Declare::Structured;

  Log::Declare->startup_level('ERROR');

  debug { message => 'log message' } [category];
  info  { context => { key => "value"} } [category];

=head1 DESCRIPTION 

This is a class which provides structured logging with an optional context.
It is based on the Log::Declare module and uses the same syntactic sugar
that C<Log::Declare> provides.

The same C<error>, C<debug>, C<trace>, C<info>, C<audit>, and C<warn> events are available as
provided in C<Log::Declare>.

    # log a debug message with context taken from a http request object
    debug { request => sub { return 'context' }, message => "example request log" } [DEBUG REQUEST]

    # log a trace message with context taken from a hash
    trace { context => { tag => 'value' }, message => "example context log" } [DEBUG CONTEXT]

The context from a http request logging message is used to maintain a link between related log events. Currently the
value for a http request log is taken from the C<X-Request-Id> header.

=head2 Log Output

Log output is written to the standard output stream. The default output format is structured as
JSON.

=head2 Human Readable Output

Setting the C<HUMAN_LOG> environment variable to any non-empty value will output
the log events in a human readable format:

   $ HUMAN_LOG=1 ./example-service
   {
      created     "Fri Jul  1 11:51:50 2016",
      data        {
         message   "trace output"
      },
      event       "trace",
      namespace   "service::human"
   }

=cut
