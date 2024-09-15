#!/usr/bin/perl
use strict;
use warnings;
use feature 'say';
use File::Find;
use Getopt::Long;
use Pod::Usage;
use CPAN;
use Carp;

=head1 NAME

make_cpanfile.pl - Script to generate a cpanfile from Perl modules

=head1 SYNOPSIS

perl make_cpanfile.pl [options]

=head1 OPTIONS

=over 8

=item B<--folder>

Path to the folder containing Perl modules (default: perl5/lib/perl5).

=item B<--cpanfile>

Name of the output cpanfile (default: cpanfile).

=item B<--help>

Show this help message and exit.

=back

=head1 DESCRIPTION

This script scans the specified folder for Perl modules and generates a cpanfile 
with the required modules listed. It uses the CPAN module to verify the existence 
of modules.

=head1 USAGE

    perl make_cpanfile.pl
    perl make_cpanfile.pl --folder=perl5/lib/perl5 --cpanfile=my_cpanfile

=cut

our $VERSION = '0.1.1';

# default values
my $module_folder = 'perl5/lib/perl5';
my $cpanfile_name = 'cpanfile';
my $help;

my @xs_path_regexes = (
    qr/^x86_64-linux-thread-multi::/msx,
);

GetOptions(
    'folder=s'   => \$module_folder,
    'cpanfile=s' => \$cpanfile_name,
    'help'       => \$help,
) or pod2usage(2);

pod2usage(1) if $help;

my @modules;

sub collect_modules {
    my ($folder) = @_;

    find(sub {
        return unless -f && /\.pm$/x;

        my $file = $File::Find::name;
        $file =~ s/^$folder\///x;
        $file =~ s/\.pm$//x;
        $file =~ s/\//::/gx;

        foreach my $regex (@xs_path_regexes) {
            $file =~ s/$regex//x;
        }

        push @modules, $file if $file;
        
    }, $folder);

    return;
}

sub exists_module {
    my ($module) = @_;
    my $result = CPAN::Shell->expand('Module', $module);
    return defined $result;
}

sub write_cpanfile {
    my ($cpanfile, $modules_ref) = @_;

    my $module_count = 0;

    open my $fh, '>', $cpanfile or croak "Cannot open '$cpanfile': $!";

    foreach my $module (@$modules_ref) {
        if (exists_module($module)) {
            my ($name, $version) = ($module =~ /^(.+)::(\d+\.\d+\.\d+)$/x);

            if (defined $version) {
                say $fh "requires '$name', '$version'";
            } else {
                say $fh "requires '$module'";
            }
            $module_count++;
        }
    }

    close $fh or croak "Cannot close '$cpanfile': $!";

    if ($module_count) {
        say 'cpanfile has been created.';
    } else {
        say 'No valid modules found. No cpanfile created.';
    }

    return;
}

sub main {
    collect_modules($module_folder);
    write_cpanfile($cpanfile_name, \@modules);
    return;
}

main();
