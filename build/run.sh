# Директория скрипта.

curdir=$(pwd)

# Директория артефактов симулятора.

mkdir -p ${curdir}/work

xrun -r tb_gpt_opt -64bit -xmlibdirpath ${curdir}/work $1 \
    -seed $RANDOM -l ${curdir}/run.log -input xlm.tcl -input @"run" -gui