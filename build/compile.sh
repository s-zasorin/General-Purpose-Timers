# Директория скрипта.

curdir=$(pwd)

# Директория артефактов симулятора.

mkdir -p ${curdir}/work

# Компиляция исходных файлов в Xcelium выполняется с помощью команды
# 'xrun -compile'. Исходные файлы передаются этой команде.

# Аргумент '-xmlibdirpath' используется для указания пути к директории
# артефактов симулятора.

# Аргумент '-l' указывает путь к лог-файлу компиляции.

xrun -compile -64bit ${curdir}/../rtl/digital_filter.sv ${curdir}/../rtl/divider_output.sv ${curdir}/../rtl/divider_trigger.sv \
    ${curdir}/../rtl/edge_detector.sv ${curdir}/../rtl/encoder_mode.sv ${curdir}/../rtl/encoder_mode.sv \
    ${curdir}/../rtl/fdts_generator.sv ${curdir}/../rtl/gpt_top.sv ${curdir}/../rtl/output_control.sv ${curdir}/../rtl/prescaler.sv \
    ${curdir}/../rtl/sync_cell.sv ${curdir}/../rtl/tim_channel.sv ${curdir}/../rtl/time_base_unit.sv ${curdir}/../rtl/trigger_controller.sv \
    ${curdir}/../rtl/regblock/axi_lite_if.sv ${curdir}/../rtl/regblock/CSR_GPT_pkg.sv ${curdir}/../rtl/regblock/CSR_GPT.sv ${curdir}/../tb/tb_gpt.sv \
    -xmlibdirpath ${curdir}/work -l ${curdir}/compile.log