function area_color(freq,spectra,freq_range,cmin)
color_code = {'black','red','yellow','green','cyan','blue','magenta'}; % brown, red, yellow, green, light blue, dark blue, purple
for it = 1:length(freq)-1
    idx = find(freq_range<=freq(it),1,'last');
    h = patch([freq(it) freq(it+1) freq(it+1) freq(it)],[cmin cmin spectra(it+1) spectra(it)],color_code{idx});
    h.EdgeColor = 'none';
end