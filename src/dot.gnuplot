#!/usr/bin/env gnuplot

# map type to a number
map_color(string) = ( \
  string eq 'iti' ? 0 : \
  string eq 'dot' ? 1 : \
  string eq 'exp' ? 2 : \
  string eq 'diff' ? 3 : \
  4)

set palette maxcolors 4
set palette model RGB defined ( 0 "red", 1 "blue", 2 "green", 3 "black")
set cbrange [0:3]
set cbtics offset 0,0  ('iti' 0,  'dot' 1,  'pos' 2,  'diff' 3)

plot 'dot.dat' u 1:2:(map_color(stringcolumn(3))) w points pt 5 palette, 0 

while (1) {replot; system("./dotplot.pl > dot.dat");  pause .5;}