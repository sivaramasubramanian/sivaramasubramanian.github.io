---
layout: post
title:  "Hello World!"
date:   2022-07-24 17:07:41 +0530
categories: java go postgres
---

Hello World! This is my first blog post.

In this post we'll just be testing if I have setup the blog properly.
So if you want to read something more interesting checkout my [latest blogs](/) or you can stay with me so I don't have to test this all alone.

### Code Snippets

Let's check if code snippets are working properly.

I am a [Gopher](https://go.dev/blog/gopher), I fell in love with [Golang](https://go.dev/) at my first job where we used it to build micro-services, I will be rooting for `Go` wherever I go, so lets start with that...

{% highlight golang %}
func main(){
  fmt.Println("Hello World!!")
}
// prints 'Hello World!!' to STDOUT.
{% endhighlight %}


Go is good for so many things but the Java & JVM ecosystem contains a treasure trove of frameworks and libraries that have been built over the decades. I have extensively used Java in every one of my jobs and I will continue to use it and write about, let's check that too...

{% highlight java %}
class Hello{
  public static void main (String[] args)}{
    System.out.println("Hello World!!");
  }
}

// prints 'Hello World!!' to STDOUT.
{% endhighlight %}

The core purpose of all software applications is to Create, Read, and Modify data in some form or another. It all just boils down to this. 

Modern Databases systems do a tremendous job of making these operations efficient. Especially the [1.3M LOC behemoth](https://www.reddit.com/r/PostgreSQL/comments/jhe661/why_postgresql_has_13m_line_of_code/) called PostgreSQL, which is super-extensible and allows to add [hooks](https://arctype.com/blog/postgresql-hooks/), extensions and even control [how and where the data is stored](https://wiki.postgresql.org/wiki/Foreign_data_wrappers). 
As such I have been writing and analyzing SQL queries quite a bit so lets test that too.

{% highlight sql %}
CREATE TABLE messages(id int, message text);

INSERT INTO messages VALUES(1, 'Hello World!!');

SELECT message FROM messages WHERE id = 1;

-- prints 'Hello World!!' to STDOUT.
{% endhighlight %}

Now that we have tested the code snippets, lets try creating a Heading or have we already created [one](#code-snippets)? 

Did you just click on that link and then scroll back?

!["Why would you do that?"](/assets/why-would-you-do-that.gif "Why would you do that?")


Well, that should be enough for now. All I will be needing is code snippets, text, heading, links and images.
Thanks for testing this with me.