#! /bin/bash

#LAS point cloud export and analysis for SkySat triplet

topdir=/nobackupp2/sbhusha1/skysat/proc_rainier/final_paper_submission/mapprojected_srtm_mgm_dems
cd $topdir

#forward
#img1=20190827_214711_ssc9d2_0013
#nadir
img1=20190827_214821_ssc9d2_0013

#ll -Sr 2*/*$img1*/*PC.tif

img_list=$(ls -Sr 2*/*$img1*/*PC.tif | tail -n 3 | awk -F'/' '{print $2}' | cut -c 1-27)
img_list+=" $img1"

#Write out primary PC.tif as individual laz files

pc_list=""
for img in $img_list; do
    pc_list+=" $(ls -Sr 2*/*$img*/*PC.tif)"
done

proj="EPSG:32610"
outdir=/nobackup/deshean/skysat_rainier_PC_test
mkdir -pv $outdir
merge_fn=${outdir}/${img1}_pc_merge.tif
if [ ! -e $merge_fn ] ; then
    pc_merge -o $merge_fn $pc_list
fi
if [ ! -e $outdir/${img1}_pc_merge.laz ] ; then
    point2las -c --t_srs $proj -o $outdir/${img1}_pc_merge $merge_fn
fi

echo -n > $outdir/cmd_list.txt
out=${outdir}/${img1}_pc_merge
point2dem_opt_base="--t_srs $proj --nodata-value -9999 --threads 2"
#point2dem can now write out --tr "1 2 3" which serially creates outprefix-DEM outprefix_1-DEM outprefix_2-DEM
for res in 1 2 3; do
    for filter in median count nmad min max weighted_average; do
        point2dem_opt=$point2dem_opt_base
        point2dem_opt+=" --tr $res"
        point2dem_opt+=" --filter $filter"
        if [ "$filter" = "weighted_average" ]; then
            point2dem_opt+=" --errorimage"
        fi
        echo point2dem -o ${out}_${res}m $point2dem_opt $merge_fn >> $outdir/cmd_list.txt
    done
done

parallel --progress --jobs 8 --delay 5 -a $outdir/cmd_list.txt
    
#Shashank's overlap DataFrame
#import pandas as pd
#df = pd.read_pickle('1_percent_overlap_rainier_triplet_with_overlap_perc.pkl')
#df[df['img1'].str.contains('20190827_214821_ssc9d2_0013')].sort_values(by='overlap_perc')
#df[df['img2'].str.contains('20190827_214821_ssc9d2_0013')].sort_values(by='overlap_perc')
