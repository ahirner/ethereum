require 'time'
require 'fileutils'

file = ARGV[0]

def git_hash
  hash = `git rev-parse HEAD`
  hash[0..9]
end

if File.exists?(file)

  lines = File.open(file).readlines

  time = Time.now.utc.iso8601.gsub(':', '-').gsub('-','')

  NAMES = %w(script app style)

  FileUtils.cp(file, "/tmp")

  File.open(file, 'w') do |f|
    for line in lines
      for name in NAMES
        if line.include?("#{name}.js")
          if file =~ /\.haml$/
            line = "    %script{src: 'javascripts/#{name}.js?v=#{git_hash}-#{time}'}"
          else
            line =  "  <script src='javascripts/script.js?v=#{git_hash}-#{time}'></script>"
          end
        end
        if line.include?("#{name}.css")
          if file =~ /\.haml$/
            line = "    %link{rel: 'stylesheet', href: 'stylesheets/#{name}.css?v=#{git_hash}-#{time}'}"
          else
            line = "  <link rel='stylesheet' href='stylesheets/#{name}.css?v=#{git_hash}-#{time}' />"
          end
        end
      end
      f.puts(line)
    end
  end

  #FileUtils.mv("#{file}.bak", file)

  #puts "cachified"
end
