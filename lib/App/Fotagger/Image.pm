package App::Fotagger::Image;

use strict;
use warnings;
use 5.010;

use Moose;
use DateTime;
use DateTime::Format::Strptime;
use Image::ExifTool;

has 'file' => ( isa => 'Str', is => 'ro', required=>1 );
has 'exif' => (isa=>'Image::ExifTool',is=>'rw');
has 'tags' => (isa=>'Str',is=>'rw');
has 'stars' => (isa=>'Int',is=>'rw');
has 'create_date' => (isa=>'Str',is=>'rw');
has 'width' => (isa=>'Int',is=>'rw');
has 'dateparser' => (isa=>'DateTime::Format::Strptime',is=>'ro',required=>1,default=>sub {DateTime::Format::Strptime->new(pattern=>'%Y:%m:%d %H:%M:%S');
});


sub read {
    my $self = shift;
    
    my $exif = $self->exif(Image::ExifTool->new);
    $exif->ExtractInfo($self->file);
    $self->tags($exif->GetValue('Keywords') || '');
    $self->stars($exif->GetValue('UserComment') || 0);
    $self->create_date($exif->GetValue('CreateDate'));
    $self->width($exif->GetValue('ImageWidth'));
    

}

sub write {
    my $self = shift;
    my $tags = $self->tags;
    $tags=~s/,(\S)/, $1/g;
    $self->exif->SetNewValue('Keywords',$tags);
    $self->exif->SetNewValue('UserComment',$self->stars);
    my $created = $self->dateparser->parse_datetime($self->create_date)->epoch;
    $self->exif->WriteInfo($self->file);

    utime($created,$created,$self->file);

}

sub deleted {
    my $self = shift;
    $self->tags =~ /TO_DELETE/ ? 1 : undef;
}

sub delete {
    my $self = shift;
    $self->tags($self->tags.', TO_DELETE');
    $self->write;
}

q{ listeing to:
    Grandmaster Flash: The Bridge
};
