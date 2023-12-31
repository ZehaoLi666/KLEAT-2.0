#!/bin/bash  -l

#SBATCH --nodes=1
#SBATCH --array=1-16        #depends on how mang files you are going to conduct
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=100G
#SBATCH --time=10-00:15:00
#SBATCH --mail-user=zli529@ucr.edu
#SBATCH --mail-type=ALL
#SBATCH --job-name="pre_KLEAT"
#SBATCH --output=All_samples/logs/assembly_k32_%A_%a.out
#SBATCH --error=All_samples/logs/assembly_k32_%A_%a.err
#SBATCH -p intel

conda activate cleavage
module load samtools
module load bwa
module load gmap

# set up variables that are needed to use in command line
read1=()
read2=()
prename=()

# get all input samples names
input_dir="/bigdata/lerochlab/zli529/cleavage/preprocessing/trim/results/paired"
for sample in "$input_dir"/*R1*;do
    samplename=$(basename "$sample")
    read1+=("$samplename")

    # set up a pre name of each samples
    pre_name=$(echo "$samplename" |  grep -oP 'S[0-9]+')
    prename+=("$pre_name")
done

echo "read1 is ${read1[@]}"
echo "prename is ${prename[@]}"

for sample in "$input_dir"/*R2*;do
    samplename=$(basename "$sample")
    read2+=("$samplename")
done


index=$(expr $SLURM_ARRAY_TASK_ID - 1 )
input_R1=${read1[$index]}
input_R2=${read2[$index]}
name=${prename[$index]}

echo "Creating $name k32 assembly"

echo "$index"
echo "$input_R1"
echo "$input_R2"
echo "$name"

# set up output dir
out_dir="/bigdata/lerochlab/zli529/cleavage/KLEAT-2.0/All_samples/$name/assembly/K32"

echo "$out_dir"
mkdir -p "$out_dir"

stdo="$out_dir"/32.ta.std.o
stde="$out_dir"/32.ta.std.e
touch "$stdo"
touch "$stde"

time python ~/lab/cleavage/KLEAT-2.0/transabyss/transabyss --SS --kmer 32 --pe "$input_dir/$input_R1" "$input_dir/$input_R2" --outdir "$out_dir" --name "$name" --thread "40" > "$stdo" 2> "$stde"

