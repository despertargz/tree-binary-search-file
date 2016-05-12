package Tree::Binary::Search::File;

my $KEY_SIZE = 50;

#left_pos, right_pos, val_length all 4 byte integers
my $HEADER_SIZE = 4 + 4 + 4 + $KEY_SIZE;

sub new {
    my $class = shift;  
    my $file = shift;

    return bless { file => $file };
}

sub write_file {
    my $self = shift;
    my $data = shift;

    my $hash_list = [];
    foreach my $key (sort keys %{$data}) {
        push(@$hash_list, { key => $key, val => $data->{$key} });
    }

    $self->{_list} = [];
    $self->{_cur_pos} = 0;

    my $tree = $self->build_tree($hash_list);
    $tree->{pos} = 0;

    $self->add_to_list($tree);
    $self->_write_file();
}

sub _write_file {
    my $self = shift;

    open my $fh, ">:raw", $self->{file} or die("Could not open file " . $self->{file});
    $self->{_fh} = $fh;

    foreach my $node (@{$self->{_list}}) {
        $self->write_node($node);
    }
    close $fh;
}

sub get {
    my $self = shift;
    my $key = shift;

    open my $fh, "<:raw", $self->{file} or die("Could not open file " . $self->{file});
    $self->{_fh} = $fh;

    my $result = $self->find_key($key, 0);
    close $fh;

    return $result;
}

sub serialize_node {
    my $self = shift;
    my $node = shift;

    my $padding = $KEY_SIZE - length($node->{key});

    my $buffer = "";

    $buffer .= pack("V", $node->{left_position} // 0);
    $buffer .= pack("V", $node->{right_position} // 0);
    $buffer .= pack("V", $node->{val_length});

    $buffer .= $node->{key};
    $buffer .= "\0" x $padding;
    $buffer .= $node->{val};

    return $buffer;
}

sub write_node {
    my $self = shift;
    my $node = shift;

    my $padding = $KEY_SIZE - length($node->{key});

    my $fh = $self->{_fh};
    seek $fh, $node->{pos}, 0;
    print $fh pack("V", $node->{left_position} // 0);
    print $fh pack("V", $node->{right_position} // 0);
    print $fh pack("V", $node->{val_length});

    print $fh $node->{key};
    print $fh "\0" x $padding;
    print $fh $node->{val};

    my $fh = $self->{_fh};
    seek $fh, $node->{pos}, 0;
}

sub find_key {
    my $self = shift;
    my $key = shift;
    my $pos = shift;

    my $padding = $KEY_SIZE - length($key);
    my $fh = $self->{_fh};

    $key = $key . ("\0" x $padding); 
    seek $fh, $pos, 0; 

    my $header;
    read $fh, $header, $HEADER_SIZE;

    my $file_key = substr($header, 12, $KEY_SIZE);
    my $val_len  = unpack("V", substr($header, 8, 4));
    my $right    = unpack("V", substr($header, 4, 4));
    my $left     = unpack("V", substr($header, 0, 4));

    my $comp = $key cmp $file_key;

    if ($comp == 0) {
        my $val; read $fh, $val, $val_len;
        return $val;
    }
    elsif ($comp == -1) {
        if ($left == 0) {
            return undef;
        }

        $self->find_key($key, $left);
    }
    else {
        if ($right == 0) {
            return undef;
        }

        $self->find_key($key, $right);
    }
}

sub add_to_list {
    my $self = shift;
    my $node = shift;

    push(@{$self->{_list}}, {
        key => $node->{key},
        val => $node->{val},
        pos => $node->{pos},
        val_length => length($node->{val}), 
        left_position => $node->{left_position},
        right_position => $node->{right_position} 
    });
}

sub build_tree {
    my $self = shift;
    my $list = shift;

    my $size = @$list;
    if ($size == 0) {
        return undef;
    }
    elsif ($size == 1) {
        my $tree = { 
            key => $list->[0]->{key},
            val => $list->[0]->{val},
            val_length => length($list->[0]->{val}),
        };
        $self->{_cur_pos} += $HEADER_SIZE + $tree->{val_length};
        return $tree;
    }

    my $mid = int($size / 2);
    my $tree = { 
        val => $list->[$mid]->{val}, 
        val_length => length($list->[$mid]->{val}),
        key => $list->[$mid]->{key} 
    };

    $self->{_cur_pos} += $HEADER_SIZE + $tree->{val_length};
    $self->{_val_pos} += $tree->{val_length};
    $tree->{left_position} = $self->{_cur_pos};

    my $left_end = $mid-1;
    my @left = @{$list}[0..$left_end];
    $tree->{left} = $self->build_tree(\@left);
    $tree->{left}->{pos} = $tree->{left_position};

    if ($size > 2) {
        my $right_start = $mid+1;
        my $right_end = $size-1;
        my @right = @{$list}[$right_start..$right_end];
        $tree->{right} = $self->build_tree(\@right);

        $tree->{right_position} = $self->{_cur_pos};
        $tree->{right}->{pos} = $tree->{right_position};
        $self->{_cur_pos} += $HEADER_SIZE + $tree->{right}->{val_length};
    }

    if ($tree->{left}) {
        $self->add_to_list($tree->{left});
    }

    if ($tree->{right}) {
        $self->add_to_list($tree->{right});
    }

    return $tree;
}

1
