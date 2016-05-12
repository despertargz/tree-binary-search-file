package LinearSearch;

use v5.10;

sub get {
    my $file = shift;
    my $search_key = shift;

    open $fh, "<", $file or die("could not open file: $file");

    my $found_value = undef;

    #say "looking for $key";    

    while (<$fh>) {
#        print "LINE: $_\n";
        my ($key, $value) = split /,/;
        if ($search_key eq $key) {
            $found_value = $value;
        }
    }
#    print "Done searching\n";

    close $fh; return $found_value;
}

sub write {
    my $file = shift;
    my $hash = shift;
    
    open my $fh, ">", $file;
    foreach (sort keys $hash) {
        print $fh "$_," . $hash->{$_} . "\n";     
    }     
    close $fh;
}

1;
