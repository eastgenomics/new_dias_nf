# /usr/bin/python3
"""
    This script calculates percentage target bases coverage at custom depths
    Requires the pandas package (and dependencies) installed

    Expected inputs:
        - folder containing sample.hsmetrics.tsv files
        - comma-separated list of integer values of the depths
            at which coverage should be calculated

    Output:
        - custom_coverage.csv file in the inputs/ folder
            * has headings based on the input depths
            * config.yaml should have the same headings for
            data to be parsed correctly

    Sophie Ratkai 211105
"""

import os
import sys
import pandas as pd

# This script is pointed to a folder eg /hsmetrics_files

sample_number = sys.argv[1]
custom_depths = sys.argv[2]
folder = sys.argv[3:int(sample_number)+3 ]
print(int(sample_number)+2)
# %coverage is calculated at the depths provided by the user input

depths = [int(x) for x in custom_depths.split(",")]

# Create header row: eg Sample,200x,250x,300x,500x,1000x
header = [str(i)+"x" for i in depths]
header.insert(0, "Sample")
custom_coverage = pd.DataFrame(columns=header)

extensions = ['markdup', 'sorted', 'duplication', 'Duplication']

# Go through each file in the folder
# parse the files' section after ##HISTOGRAM into a dataframe
# then calculate target bases coverage of each sample and write to a file
for file_name in folder:
    #hs_metrics_file = "/".join([folder, file])
    hs_metrics_file = file_name
    hs_data = pd.read_csv(hs_metrics_file, sep='\t', header=8, index_col=False,
        usecols=["coverage_or_base_quality", "high_quality_coverage_count"]
    )
    # Get the sample name by removing extensions
    sample_name = file_name.rstrip('.hsmetrics.tsv')
    for ext in extensions:
        # remove any extensions from name prefixed with dot or underscore
        sample_name = sample_name.replace('.{}'.format(ext), '')
        sample_name = sample_name.replace('_{}'.format(ext), '')

    sample_info = {"Sample": sample_name}

    total = sum(hs_data["high_quality_coverage_count"])
    for depth in depths:  # list of integers
        # Sum the bases that are covered above 'depth'
        basecount_above_depth = sum(hs_data.loc[hs_data[
            "coverage_or_base_quality"] >= depth
            ]["high_quality_coverage_count"])
        # Calculate percentage coverage
        pct_coverage = basecount_above_depth / total * 100
        # Add percentage coverage to the dictionary with the key
        # matching the DataFrame column name
        depth_key = str(depth)+"x"
        sample_info[depth_key] = pct_coverage

    # Calculate usable unique bases on-target, reread in files as its on a different header/row
    hs_data_on_target_calc = pd.read_csv(hs_metrics_file, sep='\t', header = 5, nrows=1)
    Usable_unique_bases_on_target = (hs_data_on_target_calc.ON_TARGET_BASES / hs_data_on_target_calc.PF_UQ_BASES_ALIGNED) * 100
    sample_info['Usable unique bases on-target'] = float(Usable_unique_bases_on_target)

    #custom_coverage = custom_coverage.append(sample_info, ignore_index=True)
    #df = pd.concat([df, pd.DataFrame([new_row])], ignore_index=True)
    custom_coverage = pd.concat([custom_coverage, pd.DataFrame([sample_info])], ignore_index=True)
custom_coverage.to_csv("custom_coverage.csv",
    sep=',', encoding='utf-8', header=True, index=False)


print("Percentage coverage values were calculated for {} depths and saved to file: custom_coverage.csv".format(custom_depths))
