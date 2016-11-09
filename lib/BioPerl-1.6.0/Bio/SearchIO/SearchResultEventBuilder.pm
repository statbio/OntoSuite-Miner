# $Id: SearchResultEventBuilder.pm 11782 2007-11-28 21:21:36Z cjfields $
#
# BioPerl module for Bio::SearchIO::SearchResultEventBuilder
#
# Cared for by Jason Stajich <jason@bioperl.org>
#
# Copyright Jason Stajich
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::SearchIO::SearchResultEventBuilder - Event Handler for SearchIO events.

=head1 SYNOPSIS

# Do not use this object directly, this object is part of the SearchIO
# event based parsing system.

=head1 DESCRIPTION

This object handles Search Events generated by the SearchIO classes
and build appropriate Bio::Search::* objects from them.

=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to
the Bioperl mailing list.  Your participation is much appreciated.

  bioperl-l@bioperl.org                  - General discussion
  http://bioperl.org/wiki/Mailing_lists  - About the mailing lists

=head2 Reporting Bugs

Report bugs to the Bioperl bug tracking system to help us keep track
of the bugs and their resolution. Bug reports can be submitted via the
web:

  http://bugzilla.open-bio.org/

=head1 AUTHOR - Jason Stajich

Email jason-at-bioperl.org

=head1 CONTRIBUTORS

Sendu Bala, bix@sendu.me.uk

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::SearchIO::SearchResultEventBuilder;
use vars qw(%KNOWNEVENTS);
use strict;

use Bio::Factory::ObjectFactory;

use base qw(Bio::Root::Root Bio::SearchIO::EventHandlerI);

=head2 new

 Title   : new
 Usage   : my $obj = Bio::SearchIO::SearchResultEventBuilder->new();
 Function: Builds a new Bio::SearchIO::SearchResultEventBuilder object 
 Returns : Bio::SearchIO::SearchResultEventBuilder
 Args    : -hsp_factory    => Bio::Factory::ObjectFactoryI
           -hit_factory    => Bio::Factory::ObjectFactoryI
           -result_factory => Bio::Factory::ObjectFactoryI

See L<Bio::Factory::ObjectFactoryI> for more information

=cut

sub new { 
    my ($class,@args) = @_;
    my $self = $class->SUPER::new(@args);
    my ($hspF,$hitF,$resultF) = $self->_rearrange([qw(HSP_FACTORY
                                                      HIT_FACTORY
                                                      RESULT_FACTORY)],@args);
    $self->register_factory('hsp', $hspF || 
                            Bio::Factory::ObjectFactory->new(
                                     -type      => 'Bio::Search::HSP::GenericHSP',
                                     -interface => 'Bio::Search::HSP::HSPI'));

    $self->register_factory('hit', $hitF ||
                            Bio::Factory::ObjectFactory->new(
                                      -type      => 'Bio::Search::Hit::GenericHit',
                                      -interface => 'Bio::Search::Hit::HitI'));

    $self->register_factory('result', $resultF ||
                            Bio::Factory::ObjectFactory->new(
                                      -type      => 'Bio::Search::Result::GenericResult',
                                      -interface => 'Bio::Search::Result::ResultI'));

    return $self;
}

# new comes from the superclass

=head2 will_handle

 Title   : will_handle
 Usage   : if( $handler->will_handle($event_type) ) { ... }
 Function: Tests if this event builder knows how to process a specific event
 Returns : boolean
 Args    : event type name


=cut

sub will_handle{
   my ($self,$type) = @_;
   # these are the events we recognize
   return ( $type eq 'hsp' || $type eq 'hit' || $type eq 'result' );
}

=head2 SAX methods

=cut

=head2 start_result

 Title   : start_result
 Usage   : $handler->start_result($resulttype)
 Function: Begins a result event cycle
 Returns : none 
 Args    : Type of Report

=cut

sub start_result {
   my ($self,$type) = @_;
   $self->{'_resulttype'} = $type;
   $self->{'_hits'} = [];   
   $self->{'_hsps'} = [];
   $self->{'_hitcount'} = 0;
   return;
}

=head2 end_result

 Title   : end_result
 Usage   : my @results = $parser->end_result
 Function: Finishes a result handler cycle 
 Returns : A Bio::Search::Result::ResultI
 Args    : none

=cut

# this is overridden by IteratedSearchResultEventBuilder
# so keep that in mind when debugging

sub end_result {
    my ($self,$type,$data) = @_;    

    if( defined $data->{'runid'} &&
        $data->{'runid'} !~ /^\s+$/ ) {        

        if( $data->{'runid'} !~ /^lcl\|/) { 
            $data->{"RESULT-query_name"}= $data->{'runid'};
        } else { 
            ($data->{"RESULT-query_name"},
	     $data->{"RESULT-query_description"}) = 
		 split(/\s+/,$data->{"RESULT-query_description"},2);
        }
        
        if( my @a = split(/\|/,$data->{'RESULT-query_name'}) ) {
            my $acc = pop @a ; # this is for accession |1234|gb|AAABB1.1|AAABB1
            # this is for |123|gb|ABC1.1|
            $acc = pop @a if( ! defined $acc || $acc =~ /^\s+$/);
            $data->{"RESULT-query_accession"}= $acc;
        }
        delete $data->{'runid'};
    }
    my %args = map { my $v = $data->{$_}; s/RESULT//; ($_ => $v); } 
               grep { /^RESULT/ } keys %{$data};
    
    $args{'-algorithm'} =  uc( $args{'-algorithm_name'} || 
                               $data->{'RESULT-algorithm_name'} || $type);
    $args{'-hits'}      =  $self->{'_hits'};
    my $result = $self->factory('result')->create_object(%args);
    $result->hit_factory($self->factory('hit'));
    $self->{'_hits'} = [];
    return $result;
}

=head2 start_hsp

 Title   : start_hsp
 Usage   : $handler->start_hsp($name,$data)
 Function: Begins processing a HSP event
 Returns : none
 Args    : type of element 
           associated data (hashref)

=cut

sub start_hsp {
    my ($self,@args) = @_;
    return;
}

=head2 end_hsp

 Title   : end_hsp
 Usage   : $handler->end_hsp()
 Function: Finish processing a HSP event
 Returns : none
 Args    : type of event and associated hashref


=cut

sub end_hsp {
    my ($self,$type,$data) = @_;

    if( defined $data->{'runid'} &&
        $data->{'runid'} !~ /^\s+$/ ) {        

        if( $data->{'runid'} !~ /^lcl\|/) { 
            $data->{"RESULT-query_name"}= $data->{'runid'};
        } else { 
            ($data->{"RESULT-query_name"},
	     $data->{"RESULT-query_description"}) = 
		 split(/\s+/,$data->{"RESULT-query_description"},2);
        }
        
        if( my @a = split(/\|/,$data->{'RESULT-query_name'}) ) {
            my $acc = pop @a ; # this is for accession |1234|gb|AAABB1.1|AAABB1
            # this is for |123|gb|ABC1.1|
            $acc = pop @a if( ! defined $acc || $acc =~ /^\s+$/);
            $data->{"RESULT-query_accession"}= $acc;
        }
        delete $data->{'runid'};
    }

    # this code is to deal with the fact that Blast XML data
    # always has start < end and one has to infer strandedness
    # from the frame which is a problem for the Search::HSP object
    # which expect to be able to infer strand from the order of 
    # of the begin/end of the query and hit coordinates
    if( defined $data->{'HSP-query_frame'} && # this is here to protect from undefs
        (( $data->{'HSP-query_frame'} < 0 && 
           $data->{'HSP-query_start'} < $data->{'HSP-query_end'} ) ||       
         $data->{'HSP-query_frame'} > 0 && 
         ( $data->{'HSP-query_start'} > $data->{'HSP-query_end'} ) ) 
        )
    { 
        # swap
        ($data->{'HSP-query_start'},
         $data->{'HSP-query_end'}) = ($data->{'HSP-query_end'},
                                      $data->{'HSP-query_start'});
    } 
    if( defined $data->{'HSP-hit_frame'} && # this is here to protect from undefs
        ((defined $data->{'HSP-hit_frame'} && $data->{'HSP-hit_frame'} < 0 && 
          $data->{'HSP-hit_start'} < $data->{'HSP-hit_end'} ) ||       
         defined $data->{'HSP-hit_frame'} && $data->{'HSP-hit_frame'} > 0 && 
         ( $data->{'HSP-hit_start'} > $data->{'HSP-hit_end'} ) )
        ) 
    { 
        # swap
        ($data->{'HSP-hit_start'},
         $data->{'HSP-hit_end'}) = ($data->{'HSP-hit_end'},
                                    $data->{'HSP-hit_start'});
    }
    $data->{'HSP-query_frame'} ||= 0;
    $data->{'HSP-hit_frame'} ||= 0;
    # handle Blast 2.1.2 which did not support data member: hsp_align-len
    $data->{'HSP-query_length'} ||= $data->{'RESULT-query_length'};
    $data->{'HSP-query_length'} ||= length ($data->{'HSP-query_seq'} || '');
    $data->{'HSP-hit_length'}   ||= $data->{'HIT-length'};
    $data->{'HSP-hit_length'}   ||= length ($data->{'HSP-hit_seq'} || '');
    
    $data->{'HSP-hsp_length'}   ||= length ($data->{'HSP-homology_seq'} || '');
    
    my %args = map { my $v = $data->{$_}; s/HSP//; ($_ => $v) } 
               grep { /^HSP/ } keys %{$data};
    
    $args{'-algorithm'} =  uc( $args{'-algorithm_name'} || 
                               $data->{'RESULT-algorithm_name'} || $type);
    # copy this over from result
    $args{'-query_name'} = $data->{'RESULT-query_name'};
    $args{'-hit_name'} = $data->{'HIT-name'};
    my ($rank) = scalar @{$self->{'_hsps'} || []} + 1;
    $args{'-rank'} = $rank;
    
    $args{'-hit_desc'} = $data->{'HIT-description'};
    $args{'-query_desc'} = $data->{'RESULT-query_description'};
    
    my $bits = $args{'-bits'};
    my $hsp = \%args;
    push @{$self->{'_hsps'}}, $hsp;
    
    return $hsp;
}


=head2 start_hit

 Title   : start_hit
 Usage   : $handler->start_hit()
 Function: Starts a Hit event cycle
 Returns : none
 Args    : type of event and associated hashref


=cut

sub start_hit{
    my ($self,$type) = @_;
    $self->{'_hsps'} = [];
    return;
}


=head2 end_hit

 Title   : end_hit
 Usage   : $handler->end_hit()
 Function: Ends a Hit event cycle
 Returns : Bio::Search::Hit::HitI object
 Args    : type of event and associated hashref


=cut

sub end_hit{
    my ($self,$type,$data) = @_;   
    my %args = map { my $v = $data->{$_}; s/HIT//; ($_ => $v); } grep { /^HIT/ } keys %{$data};

    # I hate special cases, but this is here because NCBI BLAST XML
    # doesn't play nice and is undergoing mutation -jason
    if(exists $args{'-name'} && $args{'-name'} =~ /BL_ORD_ID/ ) {
        ($args{'-name'}, $args{'-description'}) = split(/\s+/,$args{'-description'},2);
    }
    $args{'-algorithm'} =  uc( $args{'-algorithm_name'} || 
                               $data->{'RESULT-algorithm_name'} || $type);
    $args{'-hsps'}      = $self->{'_hsps'};
    $args{'-query_len'} =  $data->{'RESULT-query_length'};
    $args{'-rank'}      = $self->{'_hitcount'} + 1;
    unless( defined $args{'-significance'} ) {
        if( defined $args{'-hsps'} && 
            $args{'-hsps'}->[0] ) {
            # use pvalue if present (WU-BLAST), otherwise evalue (NCBI BLAST)
            $args{'-significance'} = $args{'-hsps'}->[0]->{'-pvalue'} || $args{'-hsps'}->[0]->{'-evalue'};
        }
    }
    my $hit = \%args;
    $hit->{'-hsp_factory'} = $self->factory('hsp');
    $self->_add_hit($hit);
    $self->{'_hsps'} = [];
    return $hit;
}

# TODO: Optionally impose hit filtering here
sub _add_hit {
    my ($self, $hit) = @_;
    push @{$self->{'_hits'}}, $hit;
    $self->{'_hitcount'} = scalar @{$self->{'_hits'}};
}

=head2 Factory methods

=cut

=head2 register_factory

 Title   : register_factory
 Usage   : $handler->register_factory('TYPE',$factory);
 Function: Register a specific factory for a object type class
 Returns : none
 Args    : string representing the class and
           Bio::Factory::ObjectFactoryI

See L<Bio::Factory::ObjectFactoryI> for more information

=cut

sub register_factory{
   my ($self, $type,$f) = @_;
   if( ! defined $f || ! ref($f) || 
       ! $f->isa('Bio::Factory::ObjectFactoryI') ) { 
       $self->throw("Cannot set factory to value $f".ref($f)."\n");
   }
   $self->{'_factories'}->{lc($type)} = $f;
}


=head2 factory

 Title   : factory
 Usage   : my $f = $handler->factory('TYPE');
 Function: Retrieves the associated factory for requested 'TYPE'
 Returns : a Bio::Factory::ObjectFactoryI 
 Throws  : Bio::Root::BadParameter if none registered for the supplied type
 Args    : name of factory class to retrieve

See L<Bio::Factory::ObjectFactoryI> for more information

=cut

sub factory{
   my ($self,$type) = @_;
   return $self->{'_factories'}->{lc($type)} || 
       $self->throw(-class=>'Bio::Root::BadParameter',
                    -text=>"No factory registered for $type");
}

=head2 inclusion_threshold

See L<Bio::SearchIO::blast::inclusion_threshold>.

=cut

sub inclusion_threshold {
    my $self = shift;
    return $self->{'_inclusion_threshold'} = shift if @_;
    return $self->{'_inclusion_threshold'};
}

1;
