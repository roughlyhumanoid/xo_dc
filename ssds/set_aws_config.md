# aws cli notes
```
aws configure set default.s3.max_concurrent_requests 20
aws configure set default.s3.max_queue_size 10000
aws configure set default.s3.multipart_threshold 64MB
aws configure set default.s3.multipart_chunksize 16MB
aws configure set default.s3.max_bandwidth 50MB/s
aws configure set default.s3.use_accelerate_endpoint true
aws configure set default.s3.addressing_style path
```

## target_bandwidth
- target_bandwidth configuration option to 10000000000b/s). To set a specific target bandwith, explicitly configure the target_bandwidth configuration option. Its value can be specified as:

- An integer in terms of bytes per second. For example, 1073741824 would set the target bandwidth to 1 gibibyte per second.
- A rate suffix. This can be expressed in terms of either bytes per second (B/s) or bits per second (b/s). You can specify rate suffixes using: KB/s, MB/s, GB/s, Kb/s, Mb/s, Gb/s etc. For example: 200MB/s, 10GB/s, 200Mb/s, 10Gb/s. When specifying rate suffixes, values are expanded using powers of 2 instead of 10. For example, specifying 1KB/s is equivalent to specifying 1024B/s instead of 1000B/s

.aws/config
```
[profile development]
aws_access_key_id=foo
aws_secret_access_key=bar
s3 =
  max_concurrent_requests = 20
  max_queue_size = 10000
  multipart_threshold = 64MB
  multipart_chunksize = 16MB
  max_bandwidth = 50MB/s
  use_accelerate_endpoint = true
  addressing_style = path
```
