use Tree::Binary::Search::File;

my $tf = Tree::Binary::Search::File->new("/tmp/test-bst");
$tf->write_file({ test => "blah" });

