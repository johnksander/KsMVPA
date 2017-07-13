function my_files = prepare_fp(varargin)

%curr_options = varargin{1};
if length(varargin) == 4
    subj_dir = varargin{2};
    sub_directory = varargin{3};
    ft = varargin{4};
    it_dir = fullfile(subj_dir,sub_directory);
elseif length(varargin) == 3 %for TR files, don't have subject directories 
    subj_dir = varargin{2};
    ft = varargin{3};
    it_dir = fullfile(subj_dir);
end
fileslist = dir(fullfile(it_dir,ft));
my_files = cellfun(@(x) fullfile(it_dir,x),{fileslist(:).name},'UniformOutput',false);


% 06/08/2016: manglefest code below, making file trees the same between datatypes

% switch curr_options.rawdata_type
%     case {'unsmoothed_raw','dartel_raw'}
%
%         if length(varargin) == 4
%             subj_dir = varargin{2};
%             sub_directory = varargin{3};
%             ft = varargin{4};
%             it_dir = fullfile(subj_dir,sub_directory);
%         elseif length(varargin) == 3
%             subj_dir = varargin{2};
%             ft = varargin{3};
%             it_dir = fullfile(subj_dir);
%         end
%         fileslist = dir(fullfile(it_dir,ft));
%         my_files = cellfun(@(x) fullfile(it_dir,x),{fileslist(:).name},'UniformOutput',false);
%
%     case 'LSS_eHDR'
%
%         if length(varargin) == 4
%             subj_dir = varargin{2};
%             sub_directory = varargin{3};
%             ft = varargin{4};
%             it_dir = fullfile(subj_dir,sub_directory,curr_options.rawdata_type_subdir);
%         elseif length(varargin) == 3
%             subj_dir = varargin{2};
%             ft = varargin{3};
%             it_dir = fullfile(subj_dir);
%         end
%         fileslist = dir(fullfile(it_dir,ft));
%         my_files = cellfun(@(x) fullfile(it_dir,x),{fileslist(:).name},'UniformOutput',false);
%
%     case 'estimatedHDR_spm'
%
%         if length(varargin) == 4
%             subj_dir = varargin{2};
%             sub_directory = varargin{3};
%             ft = varargin{4};
%             it_dir = fullfile(subj_dir,sub_directory,curr_options.rawdata_type_subdir);
%             numdirs = length(dir(fullfile(it_dir,'TOI*')));
%             my_files = cell(numdirs,1);
%             for dir_idx = 1:numdirs
%                 fp =  fullfile(it_dir,['TOI_' num2str(dir_idx)]);
%                 my_files{dir_idx} = dir(fullfile(fp,curr_options.scan_ft));
%                 my_files{dir_idx} = fullfile(fp,my_files{dir_idx}.name);
%             end
%         elseif length(varargin) == 3
%             subj_dir = varargin{2};
%             ft = varargin{3};
%             it_dir = fullfile(subj_dir);
%             fileslist = dir(fullfile(it_dir,ft));
%             my_files = cellfun(@(x) fullfile(it_dir,x),{fileslist(:).name},'UniformOutput',false);
%         end
%
%     case 'anatom'
%
%         if length(varargin) == 4
%             subj_dir = varargin{2};
%             sub_directory = varargin{3};
%             ft = varargin{4};
%             it_dir = fullfile(subj_dir,sub_directory);
%         elseif length(varargin) == 3
%             subj_dir = varargin{2};
%             ft = varargin{3};
%             it_dir = fullfile(subj_dir);
%         end
%         fileslist = dir(fullfile(it_dir,ft));
%         my_files = cellfun(@(x) fullfile(it_dir,x),{fileslist(:).name},'UniformOutput',false);
% end






%
% if numel(strsplit(ft,'*')) == 2
%     fileslist = dir(fullfile(it_dir,ft));
%     my_files = cellfun(@(x) fullfile(it_dir,x),{fileslist(:).name},'UniformOutput',false);
% elseif numel(strsplit(ft,'*')) == 3
%     dir_wc = strsplit(ft,'*');
%     file_wc = [dir_wc{2} '*' dir_wc{3}];
%     dir_wc = [dir_wc{1} '*'];
%     if numel(strsplit(dir_wc,'/')) == 2
%         subdir = strsplit(dir_wc,'/');
%         subdir = subdir{1};
%     elseif numel(strsplit(dir_wc,'/')) == 2
%         subdir = '';
%     end
%     dirlist = dir(fullfile(it_dir,dir_wc));
%     my_files = cell(length(dirlist),1);
%     for diridx = 1:length(dirlist)
%         my_files{diridx} =  dir(fullfile(it_dir,subdir,dirlist(diridx).name,file_wc));
%         my_files{diridx} = fullfile(it_dir,subdir,dirlist(diridx).name,my_files{diridx}.name); %assumes only one match per folder
%     end
% end
