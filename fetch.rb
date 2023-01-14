#!/usr/bin/env ruby
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
    warn 'error: not found'
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
  warn 'error: not specified name'
  exit 1
end

resolve(ARGV[0], SERVER, PORT, HOSTNAME).each do |rr|
  next until rr.kind_of?(Resolv::DNS::Resource::IN::HTTPS)
  next until rr.svc_params.keys.include?('ech')

  pp rr.svc_params['ech']
end

# TODO: refine ech_config to pp
