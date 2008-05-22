# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name           'Language-TECO';
all_from       'lib/Language/TECO.pm';

feature 'Command line te script' =>
        -default => 1,
        'Term::ReadKey' => '0';

feature 'IRC evalbot' =>
        -default => 0,
        'Bot::BasicBot' => '0';

build_requires 'Test::More';
build_requires 'Test::Exception';

install_script('bin/te');
install_script('bin/tecobot');

tests          't/*.t';

auto_install;
WriteAll;
