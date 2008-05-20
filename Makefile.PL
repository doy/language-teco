# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name           'Language-TECO';
all_from       'lib/Language/TECO.pm';

requires       '';

build_requires 'Test::More';

auto_install;
WriteAll;

