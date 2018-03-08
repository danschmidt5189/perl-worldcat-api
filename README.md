# NAME

WorldCat::API - Moo bindings for the OCLC WorldCat API

# VERSION

version 1.001

# Synopsis

```perl
my $api = WorldCat::API->new(
  institution_id => "...",
  principle_id => "...",
  principle_id_namespace => "...",
  secret => "...",
  wskey => "...",
);

my $marc_record = $api->find_by_oclc_number("123") or die "Not Found!";
```

## Configuration

Attributes default to using environment variables of the form "WORLDCAT\_API\_&lt;upper-case-attr-name>". If testing with Docker, you can add these values to a .env file at the root of the project, then load that file when running Docker:

```
$ cat <<-EOF > .env
WORLDCAT_API_INSTITUTION_ID="..."
WORLDCAT_API_PRINCIPLE_ID="..."
WORLDCAT_API_PRINCIPLE_ID_NAMESPACE="..."
WORLDCAT_API_SECRET="..."
WORLDCAT_API_WSKEY="..."
EOF
```

## Development, Builds, and Testing

The included Dockerfile sets you up to run Dist::Zilla, which makes basic development tasks pretty easy:

```
$ docker build -t worldcat .

# Develop interactively
$ docker run -it --entrypoint=/bin/bash --volume "$PWD:/app" worldcat

# Build the dist
$ docker run --volume "$PWD:/app" worldcat build

# Test it
$ docker run --volume "$PWD:/app" worldcat test
```

# AUTHOR

Daniel Schmidt <danschmidt5189@gmail.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Daniel Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
