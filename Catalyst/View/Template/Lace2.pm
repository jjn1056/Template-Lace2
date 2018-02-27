package Catalyst::View::Template::Lace2;

use Moo;
use Template::Tiny;
use Template::Lace2::Registry;
use Module::Runtime;

extends 'Catalyst::Model';

our $VERSION = '0.001';

has _application => (is => 'ro', required=>1);

sub default_registry { 'Template::Lace2::Registry' }

has registry => (is=>'ro', required=>1);

has 'template_string' => (
  is=>'ro',
  required=>1,
  lazy=>1,
  builder=>'_build_template_string');
 
  sub _build_template_string { local $/; return <DATA> }
 
has 'template_processor' => (
  is=>'ro',
  required=>1,
  lazy=>1,
  builder=>'_build_template_processor');
 
  sub _build_template_processor { return Template::Tiny->new(TRIM => 1) }

sub COMPONENT {
  my ($class, $app) = (shift,shift);
  my $args = $class->merge_config_hashes($class->config, shift);
  my $registry_package = delete($args->{registry}) || $class->default_registry;
  unless($args->{component_namespace}) {
    $args->{component_namespace} = $app .'::'.$class_part;
  }
  my $registry = Module::Runtime::use_module($registry_package)->new($args);
  return $class->new(registry=>$registry, _application=>$app);
}

sub create { shift->registry->create(@_) }

sub expand_modules {
  my ($self, $config) = @_;
  my @packages = ();
  foreach my $view (keys %{$self->registry->components_by_ns}) {
    my $package = ref($self) .'::'. $view;
    my $registry = (ref($self) =~m/${\$self->_application}::View::(.+$)/)[0];
    my $input = $self->template_string;
    
    my $output = '';
    $self->template_processor->process(
      \$input,
      +{
        view=>$view,
        registry=>$registry,
        package=>$package,
      },
      \$output );

    eval $output;
    die $@ if $@;
    push @packages, $package;
  }
  return @packages;
}

1;

__DATA__
package [% package %];
 
use warnings;
use strict;
use base 'Catalyst::Model';
use Catalyst::Utils;

my $inject_http_status_helpers = sub {
  my ($class, @status) = @_;
  return unless @status;
  foreach my $helper( grep { $_=~/^http/i} @HTTP::Status::EXPORT_OK) {
    my $subname = lc $helper;
    my $code = HTTP::Status->$helper;
    my $codename = "http_".$code;
    if(grep { $code == $_ } @status) {
       eval "sub ${\$class}::${\$subname} { return shift->respond(HTTP::Status::$helper,\@_) }";
       eval "sub ${\$class}::${\$codename} { return shift->respond(HTTP::Status::$helper,\@_) }";
    }
  }
};
  
sub COMPONENT {
  my ($class, $app, $args) = @_;
  my $merged_args = $class->merge_config_hashes($class->config, $args);
  my @returns_status = delete $merged_args->{returns_status} || 200;
  my $content_type = delete $merged_args->{content_type} || 'text/html';
  my $catalyst_component_name = delete $merged_args->{catalyst_component_name};
  $class->$inject_http_status_helpers(@returns_status);
  return bless +{
    _args => $merged_args,
    _returns_status => \@returns_status,
    _content_type => $content_type,
    _catalyst_component_name => $catalyst_component_name,
    _class => $class,
  }, "Factory::$class";
}

sub respond {
  my ($self, $status, $headers) = @_;
  $self->_profile(begin => "=> ".Catalyst::Utils::class2classsuffix($self->{_catalyst_component_name})."->respond($status)");
  for my $r ($self->{_ctx}->res) {
    $r->status($status) if $r->status != 200; # Catalyst sets 200
    $r->content_type($self->{_content_type}) if !$r->content_type;
    $r->headers->push_header(@{$headers}) if $headers;
    $r->body($self->{_view}->to_html);
  }
  $self->_profile(end => "=> ".Catalyst::Utils::class2classsuffix($self->{_catalyst_component_name})."->respond($status)");
  return $self;
}
 
sub _profile {
  my $self = shift;
  $self->{_ctx}->stats->profile(@_)
    if $self->{_ctx}->debug;
}
 
# Support old school Catalyst::Action::RenderView for example (
# you probably also want the ::ArgsFromStash role).
 
sub process {
  my ($self, $c, @args) = @_;
  $self->respond(200, @args);
}

# proxy methods 
 
sub detach { shift->{_ctx}->detach(@_) }
 
sub view { shift->{_ctx}->view(@_) }

package Factory::[% package %];

use warnings;
use strict;

sub ACCEPT_CONTEXT {
  my $self = shift;
  my $c = shift;
  my @args = (ref($_[0])||'') eq 'HASH' ? %{$_[0]}: @_; # allow 
  my %args = (@args, %{$self->{_args}||+{}}, ctx=>$c);
  my $registry = $c->view('[% registry %]');
  return bless +{
    _ctx => $c,
    _content_type => $self->{_content_type},
    _catalyst_component_name => $self->{_catalyst_component_name},
    _view => $registry->create('[% view %]', %args),
  }, $self->{_class};
}
 
1;
