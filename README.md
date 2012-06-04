# buffered_job

Buffering jobs for specific period. Do other method when two or more similer jobs in 
a buffer.

## When to use

If you implement email notification. You can merge multiple notificaiton in one mail with


## Install

```Gemfile
gem 'buffered_job',:git => 'git://github.com/sawamur/buffered_job.git'
```


## Peparation

```
$ (bundle exec) rails generate buffered_job
$ (bundle exec) rake db:migrate
```


include utils to models you want to use

```
include BufferedJob::Util
```


## Dependancies

This module depends on delayed_job.Set up delayed_job and run delayed_job worker


## Usage

```
@user.buffer.post_to_twitter(@article1)
@user.buffer.post_to_twitter(@aritcle2)
``` 
 
invoke merge_* medtho in User mode

```
def merge_post_to_twitter(@articles)
 ..
end
```

 

## Copyright

Copyright (c) 2012 Masaki Sawamura. See LICENSE.txt for
further details.

