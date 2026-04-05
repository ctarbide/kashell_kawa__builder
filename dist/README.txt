
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

'can_be_added_to_path' is at [1].

- [1]: https://github.com/ctarbide/coolscripts/blob/master/README.txt

<<create profile>>=
cat@<<'EOF'>"<<prefix>>/profile"
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
