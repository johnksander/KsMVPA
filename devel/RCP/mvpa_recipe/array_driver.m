clear
clc
format compact

%do both the analysis and permutations
num_workers = 30; %parpool workers

mdl = {'DiscrimType','linear','Prior','uniform','SaveMemory','on','FillCoeffs','off'...
    'OptimizeHyperparameters','auto',...
    'HyperparameterOptimizationOptions',struct('Kfold',10,'ShowPlots',false,'Verbose',0)};

options = set_options('name','MVPA_R2SL_2p5_enc2ret_k80_HP_conn26','location','harvard',...
    'enc_job','RSA_SL_1p5_ASGM_encodingValence','cluster_conn',26',...
    'searchlight_radius',2.5,'PCAcomponents2keep',80,...
    'classifier_type',mdl);


skip_subs = options.subjects(options.subjects < 425); %assume first job gets these
skip_subs = [skip_subs, options.exclusions];
skip_subs = unique(skip_subs);
options.exclusions = skip_subs;

%array jobs
subs2run = options.subjects(~ismember(options.subjects,options.exclusions));
JID = str2num(getenv('SLURM_ARRAY_TASK_ID'));
subs2run = subs2run(JID);
options.exclusions = options.subjects(~ismember(options.subjects,subs2run));

%job prof directories
files2attach = {which('predict.m')}; %{fullfile(options.classifier_function_dir,[func2str(options.classifier_type) '.m'])};
prof_name = sprintf('prof_%i',JID);
c = parcluster(prof_name);
c.NumWorkers = num_workers;
prof_loc = sprintf('/users/ksander/parprofiles/%s',prof_name);
if ~isdir(prof_loc),mkdir(prof_loc);end
c.JobStorageLocation = prof_loc;
parpool(c,c.NumWorkers,'IdleTimeout',Inf,'AttachedFiles',files2attach)

%do permutations
MVPA_ROI2searchlight_perm(options);

delete(gcp('nocreate'))

