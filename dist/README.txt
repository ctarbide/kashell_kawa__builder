
nofake README.txt

**************** install

<<install>>=
<<sh preamble>>
latest=`ls -1 kawa_*.tar.gz | tail -1`
prefix="<<prefix>>"
echo
echo 'run the command below to inspect tarball contents:'
echo
echo "    tar -tvzf '"${latest}"' | less"
echo
echo
echo 'run the command below to install to prefix defined at ../00build.sh:'
echo
echo "    mkdir -pv \"${prefix}\""
echo "    tar -C \"${prefix}\" -xvzf '${latest}'"
echo
echo
@

****************

<<create profile>>=
cat@<<'EOF'>"<<prefix>>/profile"
if [ x"`command -v is_path_element`" != x"is_path_element" ]; then
    is_path_element(){
        perl -e'do { exit(0) if $_ eq $ARGV[0] } for split(q{:}, $ENV{PATH}); exit(1)' -- "$@"
    }
fi
if [ x"`command -v can_be_added_to_path`" != x"can_be_added_to_path" ]; then
    can_be_added_to_path(){
        test -d "${1}" && ! is_path_element "${1}"
    }
fi
if can_be_added_to_path "<<prefix>>/bin"; then
    PATH="<<prefix>>/bin:${PATH}"
fi
EOF
@

****************

<<sh preamble>>=
#!/bin/sh
set -eu
@

<<*>>=
# nofake --error -Rinstall README.txt ../00build.sh
# nofake --error -R'create profile' README.txt ../00build.sh
@

****************
