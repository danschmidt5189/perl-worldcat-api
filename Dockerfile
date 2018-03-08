FROM perl

WORKDIR /app

COPY dist.ini dist.ini
RUN cpanm -n Dist::Zilla
RUN dzil authordeps | cpanm -n

COPY . .
RUN dzil listdeps --all | cpanm -n

ENTRYPOINT ["/usr/local/bin/dzil"]
