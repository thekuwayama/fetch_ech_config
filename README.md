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
fe 0d 00 42 d2 00 20 00      20 0d 07 c7 94 d3 58 f1
0b 6c ee 6c 70 b5 64 80      41 28 51 a0 ac 98 ec 67
99 55 91 e3 64 70 96 69      73 00 04 00 01 00 01 00
13 63 6c 6f 75 64 66 6c      61 72 65 2d 65 73 6e 69
2e 63 6f 6d 00 00
----------- fields -----------
ECHConfig:
  version(uint16):                      fe 0d
  length(uint16):                       66
  contents(ECHConfigContents):
    key_config(HpkeKeyConfig):
      config_id(uint8):                 210
      kem_id(uint16):                   00 20
      public_key(opaque):               0d 07 c7 94 d3 58 f1 0b 6c ee 6c 70 b5 64 80 41 28 51 a0 ac 98 ec 67 99 55 91 e3 64 70 96 69 73
      cipher_suites(HpkeSymmetricCipherSuite):
        kdf_id(uint16):                 00 01
        aead_id(uint16):                00 01
    maximum_name_length(uint8):         0
    public_name(opaque):                cloudflare-esni.com
    extensions(opaque):
```
