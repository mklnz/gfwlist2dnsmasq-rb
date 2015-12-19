#!/usr/bin/env ruby

require 'optparse'
require 'open-uri'
require 'yaml'
require 'base64'
require 'set'

class GFWListConverter
  COMMENT_PATTERN = /^\!|\[|^@@|^\d+\.\d+\.\d+\.\d+/
  DOMAIN_PATTERN = /([\w\-\_]+\.[\w\.\-\_]+)[\/\*]*/

  attr_accessor :config

  def initialize(config)
    self.config = config
  end

  def run
    outfile = config["out_file"]
    base_url = config["base_url"]
    dns_host = config["dns_host"]
    dns_port = config["dns_port"]
    extras = config["extras"]
    ipset_name = config["ipset_name"]
    domains = Set.new

    data = open(base_url) { |io| io.read }
    Base64.decode64(data).lines.each do |l|
      l.chomp!

      if COMMENT_PATTERN.match(l)
        puts "Comment: #{l}"
      elsif match = DOMAIN_PATTERN.match(l)
        domains << match[0]
        puts "Added: #{l}"
      else
        puts "No valid domain: #{l}"
      end
    end

    domains += extras

    File.open(outfile, 'w') do |f|
      domains.each do |d|
        f.puts "server=/.#{d}/#{dns_host}##{dns_port}"
        f.puts "ipset=/.#{d}/#{ipset_name}"
      end
    end
  end

end

options = { config: nil, output: nil }

parser = OptionParser.new do|opts|
	opts.banner = "Usage: gfwlist2dnsmasq.rb [options]"
	opts.on('-c', '--config name', 'Config file') do |config|
		options[:config] = config
	end
	opts.on('-h', '--help', 'Displays Help') do
		puts opts
		exit
	end
end

parser.parse!

if options[:config] == nil
  puts "Need config path"
  exit
else
  config = YAML.load(File.open(options[:config]))

  c = GFWListConverter.new(config)
  c.run
end
