#!/bin/sh
# https://ctarbide.github.io/pages/2024/2024-02-05_12h00m11_hello-worlds/
# https://github.com/ctarbide/coolscripts/blob/master/bin/nofake-exec.nw
set -eu; set -- "${0}" --ba-- "${0}" "$@" --ea--
SH=${SH:-sh -eu}; export SH
exec nofake-exec.sh --error -Rprog "$@" -- ${SH}
exit 1

This is a live literate program.

<<project name>>=
kawa
<<repos (optional local copy)>>=
${thisdir}/../kashell_Kawa.git
<<repos (official)>>=
https://gitlab.com/kashell/Kawa.git
<<branch>>=
master
@

<<prefix>>=
${HOME}/local-<<project name>>
@

<<main dir>>=
${HOME}/Ephemeral/build/<<project name>>
@

<<source dir>>=
<<main dir>>
@

<<build dir>>=
<<main dir>>
@

<<dist dir base>>=
${thisdir}/dist
@

for void-musl-builder:latest look at
https://github.com/ctarbide/docker-voidlinux

<<builder image SKIP>>=
void-musl-builder:latest
<<builder image>>=
docker.io/library/buildpack-deps:sid
@

<<project builder image>>=
builder_of_<<project name>>:latest
@

<<extract sources>>=
if [ ! -f "<<source dir>>/.git/config" ]; then
    if [ -d "<<repos (optional local copy)>>" ]; then
        git clone -b "<<branch>>" "<<repos (optional local copy)>>" "<<source dir>>"
    else
        git clone --depth 1 -b "<<branch>>" "<<repos (official)>>" "<<source dir>>"
    fi
fi
@

<<symlink sandbox>>=
if [ ! -d "<<source dir>>__git-sandbox" ]; then
    if [ -h "<<source dir>>__git-sandbox" ]; then
        rm -fv "<<source dir>>__git-sandbox"
    fi
    ln -s "${thisdir}/.git" "<<source dir>>__git-sandbox"
fi
@

<<checkout sidecar>>=
cd "<<build dir>>"
: git-sandbox.sh checkout some_asset_from_index
@

builds using a docker image

<<build on docker>>=
cd "<<build dir>>"
set --
set -- "$@" -e HOME=/tmp/docker
set -- "$@" -e PREFIX="<<prefix>>"
set -- "$@" -e thisdir="${thisdir}"
set -- "$@" -e thispath="${thispath}"
set -- "$@" -e stamp="${stamp}"
set -- "$@" -e distdir=/var/dist
set -- "$@" -v "${thisdir}:${thisdir}:ro"
set -- "$@" -v "${HOME}/Downloads/coolscripts:/opt/coolscripts:ro"
set -- "$@" -v "${distdir}:/var/dist:rw"
docker-cwd.sh --rm "$@" \
    "<<project builder image>>" \
    sh -eux -c '
        PATH=/opt/coolscripts/bin:${PATH};
        exec nofake-exec.sh --error -R"build and install" "${thispath}" -- sh -eux
    '
@

<<prog sanity check>>=
if ! docker image inspect '<<builder image>>' >/dev/null 2>&1; then
    echo 'Error, image "''<<builder image>>''" not found.'
    exit 1
fi
@

<<get absolute path>>=
perl -MFile::Spec::Functions=rel2abs,canonpath \
    -le'print canonpath(rel2abs(\$ARGV[0]))' --
@

<<prog>>=
thispath=`<<get absolute path>> "${1}"`; shift  # the initial script
thisprog=${thispath##*/}
thisdir=${thispath%/*}
cd "${thisdir}"

<<prog sanity check>>

<<function localstamp>>
stamp=`localstamp`
distdir="<<dist dir base>>/${stamp}"

mkdir -pv "<<main dir>>" "<<build dir>>" "<<source dir>>" "${distdir}<<prefix>>"

# for future reference
cp -av "${thispath}" "${distdir}<<prefix>>/${thisprog}.ref"
chmod 0444 "${distdir}<<prefix>>/${thisprog}.ref"

<<extract sources>>
<<symlink sandbox>>
<<checkout sidecar>>
<<build custom builder image>>
<<build on docker>>
<<cleanup>>
@

<<Dockerfile for void-musl-builder:latest>>=
FROM <<builder image>>
#RUN set -eux; xbps-install -Suy
@

<<Dockerfile for buildpack-deps:sid>>=
FROM <<builder image>>
ENV DEBIAN_FRONTEND=noninteractive
RUN set -eux; apt-get update; \
    apt-get install -y --no-install-recommends \
        texinfo cmake build-essential \
        openjdk-17-jdk-headless maven ant; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*
@

<<Dockerfile>>=
#@<<Dockerfile for void-musl-builder:latest>>
<<Dockerfile for buildpack-deps:sid>>
@

<<build custom builder image>>=
cd "${thisdir}"
nofake-exec.sh --error -RDockerfile -o00build_Dockerfile "${thispath}" --skip-append-output -- \
    docker image build --progress=plain -t '<<project builder image>>' -f 00build_Dockerfile .
@

<<function localstamp>>=
localstamp(){ date '+%Y-%m-%d_%Hh%Mm%S'; }
@

<<function are_we_good>>=
are_we_good(){ check=$1; shift; perl -wsle'
open(my $fh, q{|-}, @ARGV) or die $!;
select((select($fh),$|++)[0]);
my $last; while (<STDIN>) {
    chomp($last = $_);
    next if $last eq $check;
    print $fh $last;
}; exit 1 if $last ne $check;' -- -check="${check}" "$@"; }
@

<<autogen>>=
if [ ! -x configure ]; then
    sh ./autogen.sh
fi
@

<<configure>>=
if [ ! -x config.status ]; then
    ./configure --prefix="${PREFIX}"
fi
@

<<make SKIP>>=
make -j4
<<make>>=
make
@

<<install and package>>=
distprefix="${distdir}${PREFIX}"
cp -av "${buildlog}" "${distprefix}"
make DESTDIR="${distdir}" install
(
    cd "${distprefix}"
    tar -czf "${distdir}/<<project name>>_${stamp}.tar.gz" *
    cd "${distdir}"
    rm -rf "${distprefix}"
)
@

this runs inside docker, see 'build on docker' chunk for details

<<build and install>>=
set -x
<<function localstamp>>
<<function are_we_good>>
buildlog="00build_<<project name>>_${stamp}.log"
check="all good for $$"
(
    localstamp
    <<autogen>>
    localstamp
    <<configure>>
    localstamp
    <<make>>
    localstamp
    echo "${check}"
) 2>&1 | are_we_good "${check}" tee "${buildlog}"
localstamp
<<install and package>>
localstamp
@

this runs right after docker

<<cleanup>>=
(
    cd "<<dist dir base>>"
    mv "${stamp}/<<project name>>_${stamp}.tar.gz" .
    rm -f "<<project name>>_latest.tar.gz"
    ln -s "<<project name>>_${stamp}.tar.gz" "<<project name>>_latest.tar.gz"
    rm -rf "${stamp}"
)
@
