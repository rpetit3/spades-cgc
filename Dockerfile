FROM rpetit3/nextconda-base

MAINTAINER robbie.petit@gmail.com

# SPAdes via Bioconda
RUN conda install -y spades==3.11.1
COPY spades.nf spades-interleave.nf /usr/local/bin
RUN chmod 755 /usr/local/bin/spades*.nf

# Modified version of assemblathon-stats.pl
RUN cd /tmp/ \
    && curl -sSL https://github.com/staphopia/assemblathon2-analysis/archive/0.2.tar.gz -o assemblathon-stats-0.2.tar.gz \
    && tar -xzf assemblathon-stats-0.2.tar.gz \
    && mv assemblathon2-analysis-0.2 /opt/assemblathon-stats \
    && sed -i 's=^use strict;=use lib "/opt/assemblathon-stats";\nuse strict;=' /opt/assemblathon-stats/assemblathon_stats.pl \
    && ln -s /opt/assemblathon-stats/assemblathon_stats.pl /usr/local/bin/assemblathon_stats.pl

RUN mkdir /data
WORKDIR /data

CMD ["spades.nf", "--help"]
