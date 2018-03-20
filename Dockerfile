FROM lambci/lambda:build-python3.6

RUN yum -y install perl-Digest-MD5 && \
    yum -y install wget

RUN mkdir /var/src
WORKDIR /var/src

ADD http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz /var/src/

COPY texlive.profile /var/src/

RUN tar xf install*.tar.gz

RUN cd install-tl-* && \
    ./install-tl --profile ../texlive.profile


FROM lambci/lambda:build-python3.6

ENV PATH=/var/task/texlive/2017/bin/x86_64-linux/:$PATH

COPY --from=0 /var/task/ /var/task/
COPY lambda_main.py /var/task

WORKDIR /var/task
