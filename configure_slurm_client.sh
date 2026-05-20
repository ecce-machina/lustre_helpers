#!/bin/bash
set -euxo pipefail

ROLE=""
NODE_NAME=""
CONTROLLER_HOST="lustre-client1"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --role) ROLE="$2"; shift 2 ;;
    --node-name) NODE_NAME="$2"; shift 2 ;;
    --controller-host) CONTROLLER_HOST="$2"; shift 2 ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

dnf -y install epel-release || true
dnf -y install munge munge-libs slurm slurm-slurmd slurm-slurmctld fio || true

systemctl enable --now munge

cat > /etc/slurm/slurm.conf <<EOF
ClusterName=lustre-lab
SlurmctldHost=${CONTROLLER_HOST}
MpiDefault=none
ProctrackType=proctrack/linuxproc
ReturnToService=2
SlurmctldPidFile=/run/slurmctld.pid
SlurmdPidFile=/run/slurmd.pid
SlurmdSpoolDir=/var/spool/slurmd
StateSaveLocation=/var/spool/slurmctld
SwitchType=switch/none
TaskPlugin=task/none
SchedulerType=sched/backfill
SelectType=select/cons_tres
SelectTypeParameters=CR_Core

NodeName=lustre-client[1-2] CPUs=4 State=UNKNOWN
PartitionName=debug Nodes=lustre-client[1-2] Default=YES MaxTime=INFINITE State=UP
EOF

mkdir -p /var/spool/slurmd /var/spool/slurmctld
chown -R slurm:slurm /var/spool/slurmd /var/spool/slurmctld || true

systemctl enable --now slurmd

if [[ "$ROLE" == "controller" ]]; then
  systemctl enable --now slurmctld
fi

mkdir -p /mnt/lustre/fio-test || true

