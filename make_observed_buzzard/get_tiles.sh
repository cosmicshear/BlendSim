#!/bin/bash -l
#SBATCH -p debug #regular
#SBATCH -N 1 #30                             # 64 max for cori # do 30 or even less each time otherwise ValueError: scale < 0 in mtrand idk why
#SBATCH -t 00:26:00
#SBATCH -A m1727
#SBATCH -J get_tiles
#SBATCH -o get_tiles.out
#SBATCH -e get_tiles.err
#SBATCH --mail-type=END                    # Event(s) that triggers email notification (BEGIN,END,FAIL,ALL)
#SBATCH --mail-user=erfan@ucdavis.edu      # Destination email address
#SBATCH --constraint=haswell
#SBATCH --ntasks-per-node=2

start_time="$(date -u +%s)"
echo "SLURM_JOB_ID" $SLURM_JOB_ID

HOSTNAME=$(echo $NERSC_HOST)
if [[ $(echo $HOSTNAME | grep -c "edison") > 0 ]]; then
    echo $'Edison is your host';
    HOST=edison
#   source activate erfanxyz-edison  # Edison
#   NNODE=40
#   DNODE=$((NNODE*2))
#   NODETYPE=ivybridge
elif [[ $(echo $HOSTNAME |grep -c "cori") > 0 ]]; then
    echo $'Cori is your host';
#   HOST=cori
#   source activate erfanxyz-1       # Cori
#   NNODE=4
#   DNODE=$((NNODE*8))
#   NODETYPE=haswell
else
    echo "unknown host",$HOST
    exit
fi


module load python/3.6-anaconda-4.4

if $( echo ${LOADEDMODULES} | grep --quiet 'PrgEnv-intel' ); then
	echo $'Had to do: module swap PrgEnv-intel PrgEnv-gnu\n';
	module swap PrgEnv-intel PrgEnv-gnu
elif $( echo ${LOADEDMODULES} | grep --quiet 'PrgEnv-cray' ); then
	echo $'Had to do: module swap PrgEnv-cray PrgEnv-gnu\n';
	module swap PrgEnv-cray PrgEnv-gnu
elif $( echo ${LOADEDMODULES} | grep --quiet 'PrgEnv-gnu' ); then
	echo $'PrgEnv-gnu is already loaded\n';
else
	echo $'Had to do: module load PrgEnv-gnu\n';
	module load PrgEnv-gnu
fi


if [ -n "$SLURM_CPUS_PER_TASK" ]; then
  omp_threads=$((1*$SLURM_CPUS_PER_TASK)) # 2X for hyper_threading (but we already did the multiplication in cpu_per_task) so we don't need it here
else
  omp_threads=1
fi
export OMP_NUM_THREADS=$omp_threads

srun --unbuffered --cpu_bind=cores python get_tiles.py #$1 $2 

end_time="$(date -u +%s)"
secs="$(($end_time-$start_time))"
printf 'SLURM Runtime: %02dh:%02dm:%02ds\n' $(($secs/3600)) $(($secs%3600/60)) $(($secs%60))
