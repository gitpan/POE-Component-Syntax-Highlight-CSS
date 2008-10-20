package POE::Component::Syntax::Highlight::CSS;

use warnings;
use strict;

our $VERSION = '0.0102';

use POE;
use base 'POE::Component::NonBlockingWrapper::Base';
use Syntax::Highlight::CSS;

sub _methods_define {
    return ( parse => '_wheel_entry' );
}

sub parse {
    $poe_kernel->post( shift->{session_id} => parse => @_ );
}

sub _process_request {
    my ( $self, $in_ref ) = @_;
    my $obj = Syntax::Highlight::CSS->new(
        ( defined $in_ref->{nnn} ? ( nnn => $in_ref->{nnn} ) : () ),
        ( defined $in_ref->{pre} ? ( pre => $in_ref->{pre} ) : () ),
    );

    $in_ref->{out} = $obj->parse( $in_ref->{in} );
}

1;
__END__

=head1 NAME

POE::Component::Syntax::Highlight::CSS - non-blocking wrapper around Syntax::Highlight::CSS

=head1 SYNOPSIS

    use strict;
    use warnings;
    use POE qw/Component::Syntax::Highlight::CSS/;

    my $poco = POE::Component::Syntax::Highlight::CSS->spawn;

    POE::Session->create( package_states => [ main => [qw(_start results)] ], );

    $poe_kernel->run;

    sub _start {
        $poco->parse({
                event => 'results',
                in    => 'a:hover { font-weight: bold; }',
            }
        );
    }

    sub results {
        print "$_[ARG0]->{out}\n";
        $poco->shutdown;
    }

Using event based interface is also possible of course.

=head1 DESCRIPTION

The module is a non-blocking wrapper around L<Syntax::Highlight::CSS> (although the
major intention was to create event based interface) which provides interface to
highlight CSS code by wrapping syntax elements into HTML C<< <span> >> elements with
different class names.

=head1 CONSTRUCTOR

=head2 C<spawn>

    my $poco = POE::Component::Syntax::Highlight::CSS->spawn;

    POE::Component::Syntax::Highlight::CSS->spawn(
        alias => 'highlighter',
        options => {
            debug => 1,
            trace => 1,
            # POE::Session arguments for the component
        },
        debug => 1, # output some debug info
    );

The C<spawn> method returns a
POE::Component::Syntax::Highlight::CSS object. It takes a few arguments,
I<all of which are optional>. The possible arguments are as follows:

=head3 C<alias>

    ->spawn( alias => 'highlighter' );

B<Optional>. Specifies a POE Kernel alias for the component.

=head3 C<options>

    ->spawn(
        options => {
            trace => 1,
            default => 1,
        },
    );

B<Optional>.
A hashref of POE Session options to pass to the component's session.

=head3 C<debug>

    ->spawn(
        debug => 1
    );

When set to a true value turns on output of debug messages. B<Defaults to:>
C<0>.

=head1 METHODS

=head2 C<parse>

    $poco->parse( {
            event       => 'event_for_output',
            nnn         => 1,
            pre         => 1,
            _blah       => 'pooh!',
            session     => 'other',
        }
    );

Takes a hashref as an argument, does not return a sensible return value.
See C<parse> event's description for more information.

=head2 C<session_id>

    my $poco_id = $poco->session_id;

Takes no arguments. Returns component's session ID.

=head2 C<shutdown>

    $poco->shutdown;

Takes no arguments. Shuts down the component.

=head1 ACCEPTED EVENTS

=head2 C<parse>

    $poe_kernel->post( highlighter => parse => {
            event       => 'event_for_output',
            in          => 'a:hover { font-weight: bold; }',
            nnn         => 1,
            pre         => 1,
            _blah       => 'pooh!',
            session     => 'other',
        }
    );

Instructs the component to parse given CSS code. Takes a hashref as an
argument, the possible keys/value of that hashref are as follows:

=head3 C<event>

    { event => 'results_event', }

B<Mandatory>. Specifies the name of the event to emit when results are
ready. See OUTPUT section for more information.

=head3 C<in>

    { in => 'a:hover { font-weight: bold; }', }

B<Mandatory>. Takes a string as a value which represents CSS code to syntax-highlight.

=head3 C<nnn>

    { nnn => 1, }

B<Optional>. Takes either true or false values. When set to a true value will insert line
numbers into the highlighted CSS code. B<Defaults to:> C<0>

=head3 C<pre>

    { pre => 1, }

B<Optional>. Takes either true or false values. When set to a true value will wrap
highlighted CSS code into a C<< <pre> >> element. B<Defaults to:> C<1>

=head3 C<session>

    { session => 'other' }

    { session => $other_session_reference }

    { session => $other_session_ID }

B<Optional>. Takes either an alias, reference or an ID of an alternative
session to send output to.

=head3 user defined

    {
        _user    => 'random',
        _another => 'more',
    }

B<Optional>. Any keys starting with C<_> (underscore) will not affect the
component and will be passed back in the result intact.

=head2 C<shutdown>

    $poe_kernel->post( highlighter => 'shutdown' );

Takes no arguments. Tells the component to shut itself down.

=head1 OUTPUT

    $VAR1 = {
        'out' => '<pre class="css-code"><span class="ch-l">  0</span> <span
                class="ch-sel">a<span class="ch-ps">:hover</span></span> { <span
                class="ch-p">font-weight</span>: <span class="ch-v">bold</span>; }</pre>',
        'in' => 'a:hover { font-weight: bold; }',
        'nnn' => 1,
        'pre' => 1,
        '_blah' => 'foos'
    };

The event handler set up to handle the event which you've specified in
the C<event> argument to C<parse()> method/event will recieve input
in the C<$_[ARG0]> in a form of a hashref. The possible keys/value of
that hashref are as follows:

=head2 C<out>

    {
        'out' => '<pre class="css-code"><span class="ch-l">  0</span> <span
                class="ch-sel">a<span class="ch-ps">:hover</span></span> { <span
                class="ch-p">font-weight</span>: <span class="ch-v">bold</span>; }</pre>',
    }

The C<out> key will contain a string representing highlighted CSS code. See
documentation for L<Syntax::Highlight::CSS> for explanation of each of the possible
C<class=""> names on the generated C<< <span> >>s.

=head2 C<in>

    { 'in' => 'a:hover { font-weight: bold; }', }

The C<in> key will contain the original CSS code.

=head2 C<nnn> and C<pre>

    {
        'nnn' => 1,
        'pre' => 1,
    }

If you specified either C<nnn> or C<pre> arguments to the C<parse()> event/method they will
be present in the output with the values that you set to them.

=head2 user defined

    { '_blah' => 'foos' }

Any arguments beginning with C<_> (underscore) passed into the C<parse()>
event/method will be present intact in the result.

=head1 SEE ALSO

L<POE>, L<Syntax::Highlight::CSS>

=head1 AUTHOR

'Zoffix, C<< <'zoffix at cpan.org'> >>
(L<http://zoffix.com/>, L<http://haslayout.net/>, L<http://zofdesign.com/>)

=head1 BUGS

Please report any bugs or feature requests to C<bug-poe-component-syntax-highlight-css at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Component-Syntax-Highlight-CSS>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc POE::Component::Syntax::Highlight::CSS

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=POE-Component-Syntax-Highlight-CSS>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/POE-Component-Syntax-Highlight-CSS>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/POE-Component-Syntax-Highlight-CSS>

=item * Search CPAN

L<http://search.cpan.org/dist/POE-Component-Syntax-Highlight-CSS>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 'Zoffix, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

