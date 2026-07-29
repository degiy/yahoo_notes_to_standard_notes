#!/bin/perl

# parse yahoo notes export and convert them to std notes imports
# need to be in Notepad dir
# 
use strict;
use warnings;
use File::Spec;

my $verbose=0;


my %httags=();

my $dir = ".";

print '{
  "version": "004",
  "items": [
    {
      "content_type": "SN|UserPreferences",
      "content": {
        "references": [],
        "appData": {
          "org.standardnotes.sn": {
            "client_updated_at": "Fri Jul 17 2026 14:54:56 GMT+0200"
          }
        }
      },
      "created_at_timestamp": 1784292896423000,
      "created_at": "2026-07-17T12:54:56.423Z",
      "deleted": false,
      "duplicate_of": null,
      "updated_at_timestamp": 1784293144867457,
      "updated_at": "2026-07-17T12:59:04.867Z",
      "uuid": "48077fe0-514e-41c8-871e-db81f01f2fea"
    },
';

opendir(my $dh, $dir) or die "Impossible d'ouvrir $dir: $!";

while (my $subdir = readdir($dh))
{
    next if $subdir eq "." or $subdir eq "..";
    my @fids=();
    $httags{$subdir}=\@fids;

    my $path = File::Spec->catdir($dir, $subdir);
    next unless -d $path;   # uniquement les répertoires

    print "Dir : $path\n" if $verbose>1;
    opendir(my $fh, $path) or die "Impossible d'ouvrir $path: $!";

    while (my $file = readdir($fh))
    {
        next if $file eq "." or $file eq "..";
        my $filepath = File::Spec->catfile($path, $file);
        next unless -f $filepath;  # uniquement les fichiers
        print "  File: $filepath\n" if $verbose>2;
        my $id=&uuid_v4_st($file);
        print "    id=$id\n" if $verbose>3;
        push @fids,$id;
        my $txt;
        open FF,$filepath or die "fichier non ouvrable";
        read FF,$txt,100000;
        close FF;
        $txt=~s/[^A-Za-z0-9 ]//g;
        #$txt=~s/\n/\\n/g;
        #$txt=~s/"/\\"/g;
        #$txt=~s/[^\x20-\x7E]//g;
        &new_note($file,$txt,$id);
    }

    closedir($fh);
}
closedir($dh);

my @kk=sort keys %httags;
for (my $i=0;$i<=$#kk;$i++)
{
    &new_tag($kk[$i]);
    print ',' unless $i==$#kk;
    print "\n";
}

print '  ]
}
';


sub new_note
{
    my ($titre,$txt,$uid)=@_;
   print '    {
      "content_type": "Note",
      "content": {';
   print "
        \"text\": \"$txt\",
        \"title\": \"$titre\",";
   print '
        "noteType": "plain-text",
        "editorIdentifier": "com.standardnotes.plain-text",
        "references": [],
        "appData": {
          "org.standardnotes.sn": {
            "client_updated_at": "2026-07-17T13:09:41.779Z"
          }
        },
        "preview_plain": "<>"
      },
      "created_at_timestamp": 1784293701890000,
      "created_at": "2026-07-17T13:08:21.890Z",
      "deleted": false,
      "duplicate_of": null,
      "updated_at_timestamp": 1784293782080693,
      "updated_at": "2026-07-17T13:09:42.080Z",';
   print "
      \"uuid\": \"$uid\"
    },
";
}

sub new_tag
{
    my ($tag)=@_;
    print '
    {
      "content_type": "Tag",
      "content": {';
    print "
        \"title\": \"$tag\",
        \"references\": [";
    my $nids=$httags{$tag};
    for (my $i=0;$i<=$#{$nids};$i++)
    {
        print "
          {
            \"uuid\": \"",${$nids}[$i],"\",
            \"content_type\": \"Note\"
          }";
        print "," unless $i==$#{$nids};
    }
    print '
        ],
        "appData": {
          "org.standardnotes.sn": {
            "client_updated_at": "2026-07-17T13:11:57.540Z"
          }
        }
      },
      "created_at_timestamp": 1784293674481000,
      "created_at": "2026-07-17T13:07:54.481Z",
      "deleted": false,
      "duplicate_of": null,
      "updated_at_timestamp": 1784293917842994,
      "updated_at": "2026-07-17T13:11:57.842Z",';
    my $tid=&uuid_v4_st($tag);
    print "
      \"uuid\": \"$tid\"
    }";

}

sub uuid_v4_st {
    my ($s) = @_;

    $s .= pack("C*", map { int(rand(256)) } 1..15);
    $s = substr($s, 0, 15);

    my $hex = unpack("H*", $s);

    $hex=~s/^(........)(....)(...)(...)(............)/$1-$2-4$3-8$4-$5/;
    return $hex;
}
