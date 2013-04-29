#!/bin/sh

this_dir=$1;
that_dir=$2;

#echo "$this_dir";
#echo "$that_dir";

for file in `ls $this_dir`; 

	do 
					#echo "$file";
					echo "diff $this_dir/$file $that_dir/$file"; 
					diff $this_dir/$file $that_dir/$file; 
					
	done
