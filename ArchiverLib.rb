require 'digest/md5'
require 'fileutils'
require 'data_mapper'

DataMapper.setup(:default, 'sqlite://' + DB)

class ArchiveFileUtil
    def initialize(file, origin, target, options = OpenStruct.new)
        @file = file
        @origin = origin
        @target = target

        @options = options

        relative_file = file[(origin.length + 1)..-1]
        @target_file = File.join @target, relative_file
        @target_path = File.dirname @target_file
    end

    def md5sum
        puts "Calculating md5sum - #{@file}" if @options.verbose
        if @md5sum_cache.nil?
            File.open(@file, 'rb') do |io|
                @md5sum_cache = Digest::MD5.new
                buf = ""
                @md5sum_cache.update(buf) while io.read(4096, buf)
            end
        end
        @md5sum_cache
    end

    def size
        puts "Calculating size - #{@file}" if @options.verbose
        File.size(@file)
    end

    def create_target_path
        puts "Creating path - #{@target_path}" if @options.verbose
        FileUtils.mkdir_p(@target_path) unless @options.dry_run
    end

    def move
        create_target_path

        puts "Moving file - #{@file} => #{@target_file}" if @options.verbose
        FileUtils.mv(@file, @target_file) unless @options.dry_run
    end

    def copy
        create_target_path

        puts "Copying file - #{@file} => #{@target_file}" if @options.verbose
        FileUtils.cp(@file, @target_file) unless @options.dry_run
    end

    def remove
        puts "Removing file - #{@file}" if @options.verbose
        FileUtils.rm(@file) unless @options.dry_run
    end

    def add_to_db
        puts "Adding to DB - #{@target_file}" if @options.verbose

        ArchiveFile.create(
            :path   => @target_file,
            :md5sum => md5sum,
            :size   => size
        ) unless @options.dry_run
    end

    def in_db?
        !ArchiveFile.all(:size => size).empty? and
            !ArchiveFile.all(:md5sum => md5sum).empty?
    end
end


class ArchiveFile
    include DataMapper::Resource

    property    :id,     Serial
    property    :path,   FilePath, :key => true
    property    :md5sum, String,   :key => true, :length => 32
    property    :size,   Integer,  :key => true
end

DataMapper.finalize
DataMapper.auto_upgrade!
