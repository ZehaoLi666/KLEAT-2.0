#!/bin/bash  -l

#SBATCH --nodes=1
#SBATCH --array=1-16        #depends on how mang files you are going to conduct
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=100G
#SBATCH --time=3-00:00:00
#SBATCH --mail-user=zli529@ucr.edu
#SBATCH --mail-type=ALL
#SBATCH --job-name="samtools"
#SBATCH --output=All_samples/logs/samtools/sam_%A_%a.out
#SBATCH --error=All_samples/logs/samtools/sam_%A_%a.err
#SBATCH -p batch


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

# set samtool input
samtool_input="/bigdata/lerochlab/zli529/cleavage/KLEAT-2.0/All_samples/$name/assembly/merged/$name-merged.fa"


# set up output dir
out_dir="/bigdata/lerochlab/zli529/cleavage/KLEAT-2.0/All_samples/$name/assembly/samtools"
mkdir $out_dir
rowdata_dir="/bigdata/lerochlab/zli529/cleavage/preprocessing/trim/results/paired"
echo "out put dirtory is $out_dir"
cd $out_dir
echo "Running bwa for $name..."
bwa index $samtool_input
bwa mem -t 40 $samtool_input "$rowdata_dir/$input_R1" "$rowdata_dir/$input_R2" | samtools view -bhS  -o $name-r2
echo "$name bwa is completed."

echo "running samtools for $name... "
samtools sort -m 100gb  -n $name-r2c.bam -o $name-r2c_ns.bam
samtools fixmate $name-r2c_ns.bam $name-r2c_fm.bam
samtools sort -m 100gb $name-r2c_fm.bam -o $name-r2c_sorted.bam
samtools index $name-r2c_sorted.bam
echo "$name samtools are completed."

echo "running gamp for $name..."
time gmap -d 3D7_Genome -D ~/lab/cleavage/KLEAT-2.0/3D7_Genome $samtool_input  -t 40 -f samse -n 0 -x 10 | grep
echo "$name gamp is complete"


echo "running samtools to create  $name c2g.bam file..."
time samtools view -bhS $name-c2g.sam -o $name-c2g.bam
samtools sort -o $name-c2g.sorted.bam $name-c2g.bam
samtools index $name-c2g.sorted.bam
samtools view -b -h -F 256 $name-c2g.sorted.bam > $name-c2g.cleaned.bam
samtools index $name-c2g.cleaned.bam
echo "Done"
