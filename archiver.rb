#!/usr/bin/env ruby

require 'optparse'
require 'ostruct'
require 'find'

################################################################################
# Command parser
################################################################################

options = OpenStruct.new

opts = OptionParser.new do |opts|
  opts.banner = "Usage: archiver.rb [options] <origin> [<origin> ...] <target>"

  opts.on("-n", "--dry-run", "Show what would be done.") do |n|
    options.dry_run = n
  end

  opts.on("-v", "--verbose", "Be verbose.") do |v|
    options.verbose = v
  end
end

usage = opts.help

opts.parse!

if ARGV.length < 2
    puts usage
    exit 1
end

paths = ARGV.map {|p| File.absolute_path(p)}
origins, target = paths[0..-2], paths[-1]

DB = File.join target, 'files.db'

################################################################################
# Libs
################################################################################

$: << ?.

require 'ArchiverLib'

origins.each do |origin|
  Find.find(origin) do |path|
      next unless File.file? path

      file = ArchiveFileUtil.new(path, origin, target, options)

      if file.in_db?
          file.remove
      else
          file.add_to_db
          file.move
      end
  end
end