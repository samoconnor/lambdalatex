FROM lambci/lambda:build-python3.6

# The TeXLive installer needs md5 and wget.
RUN yum -y install perl-Digest-MD5 && \
    yum -y install wget

RUN mkdir /var/src
WORKDIR /var/src

# Download TeXLive installer.
ADD http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz /var/src/

# Minimal TeXLive configuration profile.
COPY texlive.profile /var/src/

# Intstall base TeXLive system.
RUN tar xf install*.tar.gz
RUN cd install-tl-* && \
    ./install-tl --profile ../texlive.profile

ENV PATH=/var/task/texlive/2017/bin/x86_64-linux/:$PATH

# Install extra packages.
RUN tlmgr install xcolor \
                  tcolorbox \
                  pgf \
                  environ \
                  trimspaces \
                  etoolbox \
                  booktabs \
                  lastpage \
                  pgfplots \
                  marginnote \
                  tabu \
                  varwidth \
                  makecell \
                  enumitem \
                  setspace \
                  xwatermark \
                  catoptions \
                  ltxkeys \
                  framed \
                  parskip \
                  endnotes \
                  footmisc \
                  zapfding \
                  symbol \
                  lm \
                  sectsty \
                  stringstrings \
                  koma-script \
                  multirow \
                  calculator \
                  adjustbox \
                  xkeyval \
                  collectbox \
                  siunitx \
                  l3kernel \
                  l3packages \
                  helvetic \
                  charter

# Remove large unneeded files.
RUN rm -rf /var/task/texlive/2017/bin/x86_64-linux/lua* \
           /var/task/texlive/2017/tlpkg/texlive.tlpdb* \
           /var/task/texlive/2017/texmf-dist/source/latex/koma-script/doc \
           /var/task/texlive/2017/texmf-dist/doc


FROM lambci/lambda:build-python3.6

WORKDIR /var/task

ENV PATH=/var/task/texlive/2017/bin/x86_64-linux/:$PATH

COPY --from=0 /var/task/ /var/task/
COPY lambda_main.py /var/task
