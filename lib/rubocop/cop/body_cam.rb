# encoding: utf-8
# frozen_string_literal: true

require 'set'
require 'English'
require 'rubocop'

all_dependencies = Set.new
equipped_cops = Set.new

body_cam = Module.new do
  define_method :initialize do |config = nil, options = nil|
    super(config, options)

    return unless equipped_cops.add?(@config)

    name = self.class.cop_name

    @config.define_singleton_method(:for_cop) do |cop|
      depends_on = cop.respond_to?(:cop_name) ? cop.cop_name : cop
      all_dependencies.add([name, depends_on]) unless name == depends_on
      super(cop)
    end
  end
end

RuboCop::Cop::Cop.prepend(body_cam)

def print_all_dependencies(dependencies)
  require 'fileutils'
  dir = 'tmp'
  dot_file = "#{dir}/dependencies.dot"
  png_file = "#{dir}/dependencies.png"

  FileUtils.mkpath(dir)

  generate_dot(dependencies, dot_file)

  generate_png(dot_file, png_file)
end

def generate_dot(dependencies, dot_file)
  File.open(dot_file, 'w') do |f|
    f.puts('digraph Rubocop {')
    f.puts('  rankdir=RL')
    dependencies.sort.each do |cop, depends_on|
      f.puts(%(  "#{cop}" -> "#{depends_on}"))
    end
    f.puts('}')
  end
end

def generate_png(dot_file, png_file)
  if system('dot -V')
    system "dot -Tpng #{dot_file} -o #{png_file}"
    if $CHILD_STATUS.success?
      puts "Dependency report generated at #{png_file}"
    else
      puts 'Failed to generate PNG dependency report. ' \
           "You can preview raw Graphviz file at #{dot_file}, or " \
           'use http://www.webgraphviz.com/ to generate an image from the file.'
    end
  else
    puts 'It looks like Graphviz is not installed. ' \
         "You can preview raw Graphviz file at #{dot_file}, or " \
         'use http://www.webgraphviz.com/ to generate an image from the file.'
  end
end

at_exit do
  print_all_dependencies(all_dependencies)
end
