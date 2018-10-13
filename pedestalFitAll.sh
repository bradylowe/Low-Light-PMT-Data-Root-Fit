
if [ ${#1} -gt 0 ] ; then
	montage_name="png_pedestal/$1"
else
	montage_name="png_pedestal/pedestals.png"
fi

if [ ${#2} -gt 0 ] ; then
	chan=$2
else
	chan=12
fi

runs=$(head selected_rootfiles.txt)

pnglist=""
for run in ${runs} ; do
	root -l -b -q "pedestalFit.c(\"dir_processed_data/${run}\", ${chan}, 1)"
	png=$(ls -t r*.root.png | head -n 1)
	pnglist="${pnglist} ${png}"
done

montage -label "%f" -frame 5 -geometry 500x400+1+1 ${pnglist} ${montage_name}
echo eog ${montage_name}

echo "Remove individual png files? (y/n)"
read -n 1 choice
if [[ ${choice} == "y" || ${choice} == "Y" ]] ; then
	rm ${pnglist}
fi
