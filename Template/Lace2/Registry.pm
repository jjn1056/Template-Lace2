package Template::Lace2::Registry;

use Module::Pluggable::Object;
use Template::Lace2::Zoom;
use Template::Lace2::FilterBuilder;
use Scalar::Util;
use Moo;

sub config { return %{+{}} }

has 'component_namespace' => (
  is=>'ro',
  required=>1,
  lazy=>1, 
  builder=>'_build_component_namespace');

  sub _default_component_namespace_part { 'Components' }

  sub _build_component_namespace {
    my $package = ref($_[0]);
    my @parts = split('::', $package);
    my @prefix = (@parts[0..($#parts-1)]);
    my $component_namespace = join('::',
      @prefix,
      $_[0]->_default_component_namespace_part);
    return $component_namespace;
  }

has 'component_packages' => (
  is=>'ro',
  required=>1,
  lazy=>1,
  builder=>'_build_component_packages');
  
  sub _build_component_packages {
    my $self = shift;
    my $search = ref($self->component_namespace) ?
      $self->component_namespace :
        [$self->component_namespace];
    my @packages = Module::Pluggable::Object->new(
      require => 1,
      search_path => $search,
    )->plugins;
    return \@packages;
  }

has 'components_by_ns' => (
  is=>'ro',
  required=>1,
  lazy=>1,
  builder=>'_build_components_by_ns');

  sub _build_components_by_ns {
    my $self = shift;
    my $component_namespace = $self->component_namespace;
    my %global_config = $self->config;
    my %names = map {
      #my ($ns) = ($_=~/^$component_namespace\:\:(.+)$/);
      my $ns = $_;
      $ns=~s/::/-/g;
      my $config = ($global_config{$ns}||+{});
      my $zoom = Template::Lace2::Zoom->new({ zconfig => $self->_zconfig })->from_html($_->html);
      $zoom = $_->init_zoom($zoom, $config);
      $ns => +{
        package => $_,
        events => $zoom->to_events,
        config => $config,
      };
    } @{$self->component_packages};
    return \%names;
  }

sub _zconfig {
  return +{
    registry => shift,
    parser => 'Template::Lace2::Parser',
    producer => 'Template::Lace2::Producer',
    filter_builder => 'Template::Lace2::FilterBuilder',
  };
}

sub _zoom {
  my ($self, $src) = @_;
  my $zoom = Template::Lace2::Zoom->new({ zconfig => $self->_zconfig })
    ->from_html($src);
  return $zoom;
}

sub create {
  my ($self, $ns, @proto) = @_;
  my %args = ref($proto[0]) ? %{$proto[0]} : @proto; # allow both hash and hashref
  my %info = %{ $self->components_by_ns->{$ns} || die "No component called '$ns'" };
  my $package = $info{package};
  my %config = $self->expand_config($info{config});
  my $zoom = Template::Lace2::Zoom->new({ zconfig => $self->_zconfig })->from_events($info{events});
  my %prepared_arguments = $self->process_component_args($package,
    registry=>$self, zoom=>$zoom, %config, %args);
  my $component = eval {
    $package->new(%prepared_arguments);
  } or die "Can't instantiate '$package', error: $@";
 
  return $component;
}

sub expand_config {
  my ($self, $config_proto) = @_;
  return unless $config_proto;
  if(ref($config_proto) eq 'CODE') {
    my $config = $config_proto->($self);
    return %{$config};
  } elsif(ref($config_proto) eq 'HASH') {
    return %{$config_proto};
  } else {
    die "Not sure how to resolve $config_proto";
  }
}

sub process_component_args {
  my ($self, $package, %args) = @_;
  return %args;
}

sub process {
  my ($self, $component) = @_;
  my $new_zoom = $component->process;

  die "Method 'process' does not return an object for component '${\ref $component}'"
    unless Scalar::Util::blessed $new_zoom;
  die "Method 'process' does not return an instance of 'HTML::Zoom' for component '${\ref $component}'"
    unless $new_zoom->isa('HTML::Zoom');

  $component->zoom($new_zoom);
}
  
1;
