#!/usr/bin/env ruby
# typed: false
# frozen_string_literal: true

require 'openssl'
require 'resolv'
require 'socket'
require 'svcb_rr_patch'

SERVER = '1.1.1.1'
PORT = 853
HOSTNAME = 'cloudflare-dns.com'

def resolve(name, server, port, hostname)
  sess = gen_session(server, port, hostname)
  sess.write(build_query(name, Resolv::DNS::Resource::IN::HTTPS))
  l = sess.read(2).unpack1('n')
  resp = Resolv::DNS::Message.decode(sess.read(l))
  sess.close
  result = resp.answer.map(&:last)
  if result.empty?
    warn "error: #{name} is not found"
    exit 1
  end

  result
end

def build_query(name, typeclass)
  q = Resolv::DNS::Message.new
  q.rd = 1 # recursion desired
  q.add_question(name, typeclass)
  # The message is prefixed with a two byte length field
  [q.encode.length].pack('n') + q.encode
end

def gen_session(server, port, hostname)
  sock = TCPSocket.new(server, port)
  ctx = OpenSSL::SSL::SSLContext.new
  ctx.min_version = OpenSSL::SSL::TLS1_2_VERSION
  ctx.max_version = OpenSSL::SSL::TLS1_2_VERSION
  ctx.max_version = OpenSSL::SSL::TLS1_3_VERSION \
    if defined? OpenSSL::SSL::TLS1_3_VERSION
  ctx.alpn_protocols = ['dot']
  sess = OpenSSL::SSL::SSLSocket.new(sock, ctx)
  sess.sync_close = true
  sess.hostname = hostname
  sess.connect
  sess.post_connection_check(hostname)
  sess
end

if ARGV.empty?
  warn 'error: not specified name with ARGV'
  exit 1
end

resolve(ARGV[0], SERVER, PORT, HOSTNAME).each do |rr|
  unless rr.is_a?(Resolv::DNS::Resource::IN::HTTPS)
    warn 'warn: fetched rr is not HTTPS'
    next
  end

  unless rr.svc_params.keys.include?('ech')
    warn 'warn: rr does not have `ech`'
    next
  end

  echconfiglist = rr.svc_params['ech'].echconfiglist
  puts '---------- hex dump ----------'
  echconfiglist.each do |c|
    puts c.encode.unpack1('H*').scan(/.{2}/).each_slice(8).map { |a| a.join(' ') }.each_slice(2).map { |a| a.join('      ') + "\n" }.join
  end

  puts '----------- fields -----------'
  # https://www.ietf.org/archive/id/draft-ietf-tls-esni-15.html#section-4-2
  echconfiglist.each do |c|
    puts 'ECHConfig:'
    puts "  version(uint16):\t\t\t#{c.version.unpack1('H4').scan(/.{2}/).join(' ')}"
    echconfig_contents = c.echconfig_contents
    puts "  length(uint16):\t\t\t#{echconfig_contents.encode.length}"
    puts '  contents(ECHConfigContents):'
    puts '    key_config(HpkeKeyConfig):'
    key_config = echconfig_contents.key_config
    puts "      config_id(uint8):\t\t\t#{key_config.config_id}"
    puts "      kem_id(uint16):\t\t\t#{key_config.kem_id.encode.unpack1('H4').scan(/.{2}/).join(' ')}"
    puts "      public_key(opaque):\t\t#{key_config.public_key.opaque.unpack1('H*').scan(/.{2}/).join(' ')}"
    puts '      cipher_suites(HpkeSymmetricCipherSuite):'
    key_config.cipher_suites.each do |cs|
      puts "        kdf_id(uint16):\t\t\t#{cs.kdf_id.encode.unpack1('H4').scan(/.{2}/).join(' ')}"
      puts "        aead_id(uint16):\t\t#{cs.aead_id.encode.unpack1('H4').scan(/.{2}/).join(' ')}"
    end
    puts "    maximum_name_length(uint8):\t\t#{echconfig_contents.maximum_name_length}"
    puts "    public_name(opaque):\t\t#{echconfig_contents.public_name}"
    puts "    extensions(opaque):\t\t\t#{echconfig_contents.extensions.octet.unpack1('H*').scan(/.{2}/).join(' ')}"
  end
end
