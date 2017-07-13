function results_brain2nii(options)


brain_cells = load(fullfile(options.save_dir,[options.name '_braincells']));
brain_cells = brain_cells.brain_cells;
outputdir = fullfile(options.save_dir,'brain_outputs');
if ~isdir(outputdir)
    mkdir(outputdir)
end


for idx = 1:numel(options.subjects)
    if ismember(options.subjects(idx),options.exclusions) == 0
        
        results = brain_cells{idx};
        template_scan = load_nii(fullfile(options.script_dir,'view_niis','w3danat.nii')); %load template nifti file
        template_scan.img = results;
        template_scan.hdr.dime.datatype = 64; %reset to double (so decimals will work..)
        template_scan.hdr.dime.bitpix = 64;
        brainfn = sprintf('%s_%i.nii',options.name,options.subjects(idx));
        save_nii(template_scan,fullfile(outputdir,brainfn))
    end
end