# fetch_ech_config

`fetch_ech_config` fetches ECHConfig using DNS over TLS.

You can run test client the following:

```sh-session
$ gem install bundler

$ bundle install

$ bundle exec fetch.rb $NAME
```

For example:

```sh-session
$ bundle exec fetch.rb crypto.cloudflare.com
---------- hex dump ----------
fe 0d 00 59 34 00 20 00      20 d1 0d 44 cc 9b d3 97
00 b3 63 39 e5 4e ae e2      4c c8 fc c5 52 d7 3b 69
f7 54 ac 4c a9 c0 2f c2      51 00 04 00 01 00 01 00
13 63 6c 6f 75 64 66 6c      61 72 65 2d 65 73 6e 69
2e 63 6f 6d 00 17 00 13      63 6c 6f 75 64 66 6c 61
72 65 2d 65 73 6e 69 2e      63 6f 6d 00 00
----------- fields -----------
ECHConfig:
  version(uint16):			fe 0d
  length(uint16):			89
  contents(ECHConfigContents):
    key_config(HpkeKeyConfig):
      config_id(uint8):			52
      kem_id(uint16):			00 20
      public_key(opaque):		d1 0d 44 cc 9b d3 97 00 b3 63 39 e5 4e ae e2 4c c8 fc c5 52 d7 3b 69 f7 54 ac 4c a9 c0 2f c2 51
      cipher_suites(HpkeSymmetricCipherSuite):
        kdf_id(uint16):			00 01
        aead_id(uint16):		00 01
    maximum_name_length(uint8):		0
    public_name(opaque):		cloudflare-esni.com
    extensions(opaque<0..2^16-1>):	00 17 00 13 63 6c 6f 75 64 66 6c 61 72 65 2d 65 73 6e 69 2e 63 6f 6d 00 00
```
