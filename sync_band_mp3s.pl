#!/usr/bin/perl

my $rsync_with_options="nice rsync -avz --delete --exclude '.DS_Store'";
#my $rsync_with_options="nice rsync --dry-run -avz --delete --exclude '.DS_Store'";
my $itunesdir="/Volumes/External_2TB/mp3s/iTunes\\ Music";
my $demopath="\\ Demoz\\ -\\ New";
my $dropbox_path = "~/Dropbox/band\\ stuff";
my @bands = ('Kalopsia', 'Ruinous',);

foreach my $band (@bands) {
  my $lcband = lc($band);
  my $synccommand = "$rsync_with_options ${itunesdir}/${band}${demopath} ${dropbox_path}/${lcband}/";
  print "$synccommand\n";
  #system ($synccommand);
}
