#!/usr/bin/perl

use strict;
use warnings;

my $kernel_src = "/home/gd/workspace/linux";
my $my_git_repo = "/home/gd/workspace/linux-kernel-10x";
my $output_dir = "$my_git_repo/output";

my $date = `date -d '1 year ago' +%Y-%m-%d`;
chomp($date);

sub run_git_command {
    my ($command) = @_;
    my @result = `$command`;
    die "Error running command '$command': $!\n" if $? != 0;

    @result;
}

sub chdir_git {
    my ($dir) = @_;
    die "The specified directory '$dir' does not exist.\n" if !-d $dir;

    chdir $dir or die "Could not change to directory '$dir': $!\n";
    die "The specified directory '$dir' is not a Git repository.\n" if !-d '.git';
}

chdir_git($kernel_src);

run_git_command("git reset --hard");
run_git_command("git checkout master");
run_git_command("git pull origin master");

my $shortlog = "git shortlog -s -n --all --no-merges --after=$date | head -n 100";
my @output = run_git_command($shortlog);

my $html_file = "$output_dir/index.html";
open my $fh, '>', $html_file or die "Could not open '$html_file' for writing: $!";

print $fh <<HTML;
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Top Linux Kernel Contributors Since $date</title>
    <link rel="stylesheet" href="10x.css" />
</head>
<body>
    <h1>Top Linux Kernel Contributors</h1>
    <h2>Since $date</h2>
    <table>
    <thead>
        <tr>
            <th>&num;</th>
            <th>Contributor</th>
            <th>Commits</th>
        </tr>
    </thead>
    <tbody>
HTML

my $x = 1;

foreach my $line (@output) {
    if ($line =~ /^\s*(\d+)\s+(.+)$/) {
        print $fh <<HTML;
        <tr>
            <td>$x</td>
            <td>$2</td>
            <td>$1</td>
        </tr>
HTML
        $x++;

    }
}

print $fh <<HTML;
    </tbody>
    </table>
    <p>$shortlog</p>
    <p><a href="https://github.com/gdonald/linux-kernel-10x">https://github.com/gdonald/linux-kernel-10x</a></p>
</body>
</html>
HTML

close $fh;

print "HTML report generated successfully: $html_file\n";

chdir_git($my_git_repo);

run_git_command('git add .');
run_git_command("git commit -m 'Build for $date'");
run_git_command('git push origin HEAD');

