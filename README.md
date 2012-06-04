# buffered_job

Buffering jobs for a certain period and invoke specific method if two or more similer jobs in 
a buffer.

## Scenario

Supposing that you are running sort of social media that has user articles which has comments from his/her
friends. You probably want to have email notification for incomming comments on a article. 
If you implement straightforward, the auther of popular article would receive tons of email for a article.
That must be bothering. To avoid sending too many mails to a receipient, you can merge multiple 
notificaiton messages into one another method (in this casse that would be sending method) .

That mean, if a user gets a comment notification for her blog article as follows:

```
 @article = Article.create(:user => @user,:text => "my blog article here")
 c = @article.comments.create(:user => @jon, :text => "i love this article!")
 @user.notify(c)
```

Then. With this module,you can buffer `notify` method 

```
 c1 = @article.comments.create(:user => @jon, :text => "i love this article!")
 c2 = @article.comments.create(:user => @ken, :text => "i hate this article!")

 @user.buffer.notify(c1)
 @user.buffer.notify(c2)
 # these two methods would be translated to
 @user.merge_notify([c1,c2])
 # then you can build other notification email with arryed comment objects
```


## Install

in Gemfile

```
gem 'buffered_job',:git => 'git://github.com/sawamur/buffered_job.git'
```

then, `bundle install`


## Peparation

```
$ (bundle exec) rails generate buffered_job
$ (bundle exec) rake db:migrate
```


## Dependancies

This module depends on delayed_job.Set up delayed_job and intended to use in rails
applications. You have to run delayed_job worker.


## Usage

```
@user.buffer.post_to_twitter(@article1)
@user.buffer.post_to_twitter(@aritcle2)
``` 
 
invoke merge_* method in User model,so you must define

```
def merge_post_to_twitter(articles)
 ..
end
```


## Configuration 

default buffering time is tree munites. To modify,

```
BufferedJob.delay_time = 30.seconds
```


## Copyright

Copyright (c) 2012 Masaki Sawamura. See LICENSE.txt for
further details.

