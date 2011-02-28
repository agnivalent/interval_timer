require 'optparse'
# require 'optparse/time'
require 'ostruct'
require 'highline/system_extensions'
require 'pp'

class IntervalTimer

  SEQ_NUMBER_FORMAT = /^\s*\d+\s*\./
  
  SOUND_BETWEEN_STEPS = "sound/bell.wav"


  attr_accessor :options

  def initialize options
    @options = options
  end

  def self.parse_options(args)
    options = OpenStruct.new

    #defaults
    #options.silent = false
    #options.show_progress_bar = true

    OptionParser.new do |opts|
      opts.banner = "Usage: interval_timer.rb [OPTIONS] [COMMAND]"
      opts.separator ""
      opts.separator "Options:"
      opts.on("-f", "--file FILENAME", "file with commands to execute") {|filename| options.filename = filename}
      opts.on("-s", "--silent",        "do not use audio signals")      {options.silent = true}
      opts.on("-v", "--verbose",       "speak all commands")            {options.verbose = true}
      #todo other options here
      opts.on_tail("-h", "--help", "Show this message")                 {puts opts; exit}

    end.parse! args

    options.commands = args.join ' '

    options
  end

  def self.parse_time time_string
    total = 0
    string = time_string.clone
    hours = $1.to_i if string.sub!(/^(\d+)\s*h(ours?)?/, '')
    hours = 1  if string.sub!(/^(an)?\s*hour/, '')
    total += hours*60*60 if hours

    minutes = $1.to_i if string.sub!(/^(\d+)\s*m(in(ours?)?)?/, '')
    minutes = 1  if string.sub!(/^a?\s*minute/, '')
    total += minutes*60 if minutes
    string.sub! /\s*,?\s*/, ''

    seconds = $1.to_i if string.sub!(/^(\d+)\s*s(ec(onds?)?)?/, '')
    seconds = 1  if string.sub!(/^a?\s*second/, '')
    total += seconds if seconds
    string.sub! /\s*,?\s*/, ''

    raise "non-valid time format: \"#{time_string}\"" if not string.empty?

    total

  end

  def execute_line line
    #remove number
    line.sub!(SEQ_NUMBER_FORMAT, '')
    line.strip!

    p " --- #{line}"

    if (line =~ /^(.+):/)
      start_time = Time.now

      end_time = start_time + IntervalTimer.parse_time($1) 
      say line.sub(/^(.+):/, '').strip if not options.silent and options.verbose

      #todo progress bar
      sleep end_time - Time.now if end_time > Time.now

      #todo play sound
      play SOUND_BETWEEN_STEPS if not options.silent


    else
      #todo execute until anykey
      say line.strip if not options.silent and options.verbose
      p 'press any key when done'
      HighLine::SystemExtensions.get_character
    end
  end
  
  def say phrase
    #todo make cross-platform
    `say #{phrase}`
  end
  
  def play filename
    #todo make crossplatform
    `afplay #{filename}`
  end

  def start
    if @options.filename 
      File.new(options.filename).each_line do |line|
        execute_line line.strip!
      end
    end

    if not @options.commands.empty?
      execute_line @options.commands
    end
  end
end

timer = IntervalTimer.new IntervalTimer.parse_options(ARGV)
timer.start
