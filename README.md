# NAME

WorldCat::API - Fetch MARC::Records from OCLC's WorldCat API

# VERSION

version 1.002

# SYNOPSIS

```perl
my $api = WorldCat::API->new(
  institution_id         => "...",
  principle_id           => "...",
  principle_id_namespace => "...",
  secret                 => "...",
  wskey                  => "...",
);

my $marc_record = $api->find_by_oclc_number("123") or die "Not Found!";
```

# CONTRIBUTING

This project uses Dist::Zilla to set things up. You can run that directly or (more easily) by using Docker. For starters, create the build container:

```
$ docker build -t worldcatapi .
```

The container contains Perl, cpanm, dzil, and all of the build dependencies. Shell into it to use it as a dev environment:

```
$ docker run --volume="$PWD:/app" --entrypoint=/bin/bash worldcatapi
```

The "volume" flag syncs your local directory into the container, allowing you to develop interactively. That also means that if you build the app within the container, the build products will be reflected on your host machine:

```
$ docker run --volume="$PWD:/app" worldcatapi build
$ ls -l
…
WorldCat-API-1.002
WorldCat-API-1.002.tar.gz
…
```

# TESTING

To test, you must set (staging!) API credentials in the container environment. An easy solution is to add them to a .env file at the root of the project, which you can load with Docker:

```
$ cat <<EOF > .env
WORLDCAT_API_INSTITUTION_ID="..."
WORLDCAT_API_PRINCIPLE_ID="..."
WORLDCAT_API_PRINCIPLE_ID_NAMESPACE="..."
WORLDCAT_API_SECRET="..."
WORLDCAT_API_WSKEY="..."
EOF
$ docker run --volume="$PWD:/app" --env-file=.env worldcatapi test
```

# AUTHOR

Daniel Schmidt <danschmidt5189@gmail.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Daniel Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
