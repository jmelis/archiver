#!/usr/bin/env ruby

require 'optparse'
require 'ostruct'
require 'find'

################################################################################
# Command parser
################################################################################

options = OpenStruct.new

opts = OptionParser.new do |opts|
  opts.banner = "Usage: archiver.rb [options] <origin> <target>"

  opts.on("-n", "--dry-run", "Show what would be done.") do |n|
    options.dry_run = n
  end

  opts.on("-v", "--verbose", "Be verbose.") do |v|
    options.verbose = v
  end
end

usage = opts.help

opts.parse!

# if ARGV.length != 2
#     puts usage
#     exit 1
# __END__

origin, target = ARGV

ORIGIN = File.absolute_path origin
TARGET = File.absolute_path target
DB     = File.join TARGET, 'files.db'

################################################################################
# Libs
################################################################################

$: << ?.

require 'ArchiverLib'

Find.find(ORIGIN) do |path|
    next unless File.file? path

    file = ArchiveFileUtil.new(path, ORIGIN, TARGET, options)

    if file.in_db?
        file.remove
    else
        file.add_to_db
        file.move
    end
end
