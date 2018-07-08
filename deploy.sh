echo "=> Compiling"
crystal build renda.cr --release --no-debug
echo "=> Stopping"
ssh crypta "killall -9 renda && rm renda"
echo "=> Deploy"
scp renda crypta:~
echo "=> Starting"
ssh crypta "./renda -arb"
