package MyApp;
use Catalyst;

__PACKAGE__->inject_components(
  'View::HTML' => { from_component => 'Catalyst::View::Template::Lace2' },
);

MyApp->config(
  'View::HTML' => {
    component_namespace=>[
      'MyApp::UI::CommonX',
      'MyApp::UI::Components',
    ],
    config => {
      'Hello' => sub {
        my ($registry) = @_;
        return +{
          footer => $registry->create('Footer', copyright=>2010),
        };
      },
    },
  },
  'View::HTML::Hello' => { age => 22 },
);

MyApp->setup;
