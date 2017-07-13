function output_brain = results2output_brain(results4brain,file_searchlight_inds,output_brain,seed_x,seed_y,seed_z,options)


for searchlight_idx = 1:numel(file_searchlight_inds) %return results to output brain after parfor loop
    
    il = file_searchlight_inds(searchlight_idx); %this is pulling from the last loaded subject chunk-file, assumes chunk-file inds are the same across subjects
    
    for beh_idx = 1:numel(options.behavioral_file_list)
        
        prediction = results4brain(searchlight_idx,beh_idx);
        output_brain(seed_x(il),seed_y(il),seed_z(il),beh_idx) = prediction;

    end
    
end


