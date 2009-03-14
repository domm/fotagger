package App::Fotagger::Display::SDL;
use strict;
use warnings;
use 5.010;

use Moose;
use SDL;
use SDL::App;
use SDL::Surface;
use SDL::Tool::Graphic;
use SDL::TTFont;
use SDL::Rect;
use SDL::Event;
use SDL::Color;

has 'width' => (isa=>'Int',is=>'ro',default=>'1000');
has 'height' => (isa=>'Int',is=>'ro',default=>'750');
has 'black'  => (isa=>'SDL::Color',is=>'ro',default=>sub {SDL::Color->new(-r=>0, -g=>0, -b=>0)});
has 'grey'  => (isa=>'SDL::Color',is=>'ro',default=>sub {SDL::Color->new(-r=>50, -g=>50, -b=>50)});
has 'white'  => (isa=>'SDL::Color',is=>'ro',default=>sub {SDL::Color->new(-r=>255, -g=>255, -b=>255)});
has 'blank_tags' => (isa=>'SDL::Rect',is=>'rw');

has 'font' => (isa=>'SDL::TTFont',is=>'rw');
has 'event' => (isa=>'SDL::Event',is=>'rw');
has 'window'=> (isa=>'SDL::App',is=>'rw');
has 'app' => (isa=>'App::Fotagger',is=>'ro');

sub run {
    my ($class, $app) = @_;
    my $self = $class->new(
        app=>$app
        );
    
    my $window = SDL::App->new(
        -width  => $self->width,
        -height => $self->height,
        -depth  => 16,
    );
    $self->window($window);
    $self->font(SDL::TTFont->new(-name=>'/usr/share/fonts/truetype/ttf-liberation/LiberationSans-Regular.ttf', -size=>12,-bg=>$self->black,  -fg=>$self->white));
    $self->event(SDL::Event->new);
    $self->event->set_unicode(1);
    $self->blank_tags(SDL::Rect->new(-width=>$self->width, -height=>20, -y=>680, -x=>0));

    my $event = $self->event;
    
    $self->draw_image;
    while (1) {
        MAIN: while ($event->poll) {
            my $type = $event->type();
            exit if ($type == SDL_QUIT);
            exit if ($type == SDL_KEYDOWN && $event->key_name() eq 'escape');
        
            my $key = $event->key_name();
            if ($type == SDL_KEYDOWN && !$app->tagging) {
                given($key) {
                    when (['n','return']) {
                        $app->next_image;
                        $self->draw_image;
                    }
                    when (['p','backspace']) {
                        $app->prev_image;
                        $self->draw_image;
                    }
                    when ('page down') {
                        $app->next_image(10);
                        $self->draw_image;
                    }
                    when ('page up') {
                        $app->prev_image(10);
                        $self->draw_image;
                    }

                    when ('d') {
                        # TODO add delete tag
                        $app->next_image;
                        $self->draw_image;
                    }
                    when ('t') {
                        $app->tagging(1);
                        if (my $old_tags=$app->current_image->tags) {
                            $app->current_image->tags($old_tags.', ');
                            $self->draw_tags();
                        }
                    }
                }
            } elsif ($type == SDL_KEYDOWN && $app->tagging) {
                my $image = $app->current_image;
                my $tags = $image->tags;
                my $update_tags_display=1;
                given($key) {
                    when (length == 1) {
                        my $uni = $event->key_unicode;
                        $tags.=chr($uni);
                    }
                    when('space') {
                        $tags.=' ';
                    }
                    when('backspace') {
                        $tags=~s/.$//;
                    }
                    when('return') {
                        $app->tagging(0);
                        $image->write();
                        $app->next_image;
                        $self->draw_image;
                        $update_tags_display=0;
                    }
                }
                $image->tags($tags);
                $self->draw_tags($image) if $update_tags_display;
            }
        }
    }
}

sub draw_image {
    my $self = shift;
    my $image = $self->app->current_image;
    my $frame = SDL::Surface->new( -name => $image->file );
    my $factor = $self->width/$image->width;

    SDL::Tool::Graphic->zoom($frame,$factor,$factor);

    $frame->blit( undef, $self->window, undef );

    my $blank = new SDL::Rect(-width=>1000, -height=>20, -y=>730, -x=>0);
    $self->window->fill($blank,$self->black);
    $self->window->update($blank);
    $self->font->print($self->window, 5, $self->height-15, sprintf("File: %s (%s)",$image->file,$image->create_date));

    $self->draw_tags($image);

    $self->window->sync;
}

sub draw_tags {
    my $self = shift;
    my $image = shift || $self->app->current_image;

    $self->window->fill($self->blank_tags,$self->app->tagging ? $self->grey : $self->black);
    $self->window->update($self->blank_tags);

    $self->font->print($self->window, 5, 682, "Tags: ".$image->tags);
    $self->window->sync;


}

q{ listeing to:
    Peter Fox - Stadtaffen
};


