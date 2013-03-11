#!/usr/bin/env ruby

Mystring = "30." 

    if Mystring !~ /10./
			puts "Mystring is: " + Mystring
			puts Mystring + " Does not match" 
		else 
			puts "Mystring is: " + Mystring
			puts "This is a match"
		end
			
