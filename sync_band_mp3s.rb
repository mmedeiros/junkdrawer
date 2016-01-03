#!/usr/bin/env ruby
# rubocop:disable LineLength

# description: Script to sync all the current works in progress
require 'English'
require 'optparse'
cleanup = false
debug   = false

# parse arguments
OptionParser.new do |opt|
  opt.on('-c', '--cleanup') { cleanup = true }
  opt.on('-d', '--debug')   { debug   = true }
end.parse!

itunes_basedir     = '/Volumes/External_2TB/mp3s/iTunes\\ Music'
dropbox_basedir    = '/Users/matt/Dropbox/band\\ stuff'

if cleanup == true
  rsync_with_options = 'nice rsync -avz --delete --exclude \'.DS_Store\''
else
  rsync_with_options = 'nice rsync -avz --exclude \'.DS_Store\''
end

band_info = {
  'kalopsia' => {
    'band_name'    => 'Kalopsia',
    'fs_band_name' => 'kalopsia',
    'itunes_dir'   => "#{itunes_basedir}/Kalopsia\\ Demoz\\ -\\ New",
    'dropbox_dir'  => "#{dropbox_basedir}/kalopsia/Kalopsia\\ Demoz\\ -\\ New"
  },
  'ruinous' => {
    'band_name'    => 'Ruinous',
    'fs_band_name' => 'ruinous',
    'itunes_dir'   => "#{itunes_basedir}/Ruinous\\ Demoz\\ -\\ New",
    'dropbox_dir'  => "#{dropbox_basedir}/ruinous/Ruinous\\ Demoz\\ -\\ New"
  },
  'ruinous clicks' => {
    'band_name'    => 'Ruinous',
    'fs_band_name' => 'ruinous',
    'itunes_dir'   => "#{itunes_basedir}/Ruinous\\ -\\ Click\\ Tracks",
    'dropbox_dir'  => "#{dropbox_basedir}/ruinous/Ruinous\\ -\\ Click\\ Tracks"
  }
}

band_info.each do |_band, params|
  sync_command = "#{rsync_with_options} #{params['itunes_dir']}/  #{params['dropbox_dir']}"
  puts sync_command if debug == true
  system("#{sync_command}")
  abort('Dropbox sync failed. Please try again later') unless $CHILD_STATUS == 0
end
