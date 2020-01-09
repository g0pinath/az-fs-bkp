# az-fs-bkp

The goal of this project is to scan the Azure File shares and backup the new files and modified files to another storage account.

This is based on a powershell script that is dockerized and can be setup just from a CSV file. For each entry in the CSV file an AKS node will be scaled out at night and after the backup is completed, the nodes will be cleaned out.

How fast can it backup?

Based on the testing on standard storage accounts, 1 million files can be parsed in 75 minutes, and increasing the node size wont help as the bottleneck is on the storage size. Premium storage will have better performance, but if you scale out the files in such a way that you limit the number of files per storage account(standard) to 3 million or less, this can finish overnight. With premium storage accounts you can test how much it can handle and spread the files accordingly.

How much does it cost?

There is a cost involved for the API calls that we make and its about USD 1 per 10 million transactions -getattributes operations. List, put will cost more. You will also be paying for the additional nodes that are coming up at night times during the backup.
The solution doesnt scale down as of now, and is WIP.

High-level steps
  
  - 01_plan_np_aksnodes - based on the CSV file in docker/scripts/inputCSV.csv AKS nodes will be scaled out.
  
  - 02_build_dockerimage - build the docker image if the docker/* has changed, and push it to AZ ACR and GITLAB.
  
  - 03_build-inputfile-dynamic-cronjob-actual-values-yml - create an input file dynamically in ansible-templates/dynamic-cronjob-actual-values.yml using powershel -- this can probably combined into 4 so both are using j2 or both use PS.
  
  - 04_build-cronjob-actual-template-yml - build the cronjob template using the ansible-templates/dynamic-cronjob-actual-values.yml as input for values and cronjob-values-base.yml as template using ansible/j2.
  
  -   05_taint_nodes_apply_templates - taint the nodes so that each node runs exactly one cron job.
  
  -   cron_job_check_status_scalein_nodes - this schedule needs to be 30 minutes before the schedule defined for the cronjobs.
  
  -   cron_job_start_backup_scaleout_nodes - this schedule needs to be 30 minutes after the schedule defined for the cronjobs.
 
 GITLAB CI Variables required.
 
The following GITLAB variables needs to be setup.
  - for TF -- ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID,
  - for git -- CI_DEPLOY_USER(user name of gitlab), GIT_PUSH_URL(git url to push), GIT_TOKEN
  - for kubectl, scripts to taint -- aks_name, aks_rg_name
  - for docker to push -- az_acr_name, az_acr_pwd, az_acr_repo_name, az_acr_usr
    create the acr credentials manually and then update the gitlab variables section before proceeding to the other stages.
  - for gitlab -- base_gitlab_image_url
  - for tf -- client_id, client_secret, subscription_id, tenant_id
  - for scaling in - aks_infra_nodes_name (this is the name of the RG that is getting created with MC_ prefix), aks_vmss_name
  - for cronjobs - update in 3 places
  
      Under the main project settings CI / CD -- variables
        cron_job_backup_finished - value - FALSE
        cron_job_backup_started - value - FALSE
        cron_job_triggered - value - FALSE
  -----------------------------------------------------------
      Under the CI / CD - schedules  --  set the below variables
       For the schedule - cron_job_start_backup_scaleout_nodes
        cron_job_backup_finished - value - FALSE
        cron_job_backup_started - value - TRUE
        cron_job_triggered - value - TRUE
            Under the CI / CD - schedules  --  set the below variables
----------------------------------------------------------------           
       For the schedule - cron_job_check_status_scalein_nodes
        cron_job_backup_finished - value - TRUE
        cron_job_backup_started - value - FALSE
        cron_job_triggered - value - TRUE
      


The following files needs to be updated with values for your environment.
tf-templates/backend.tf, provider.tf, vars.tf, k8s-infra.tf

Limitations:

  - Do not create files directly under the share, those will be skipped. Typically in production you dont, so I didnt bother including that logic.
  - Dont be too agressive and increase the batch count in the script, it will actually slow things down depending on the number of parallel jobs running against the storage account.
  - There cant be more than 100 lines, as AKS node limitation is set to 100. If you spread your files across say 25 storage accounts each having about 4 million files, then this should complete in about 5 hours. Again the bottleneck is the storage account, so spreading this across 50 storage accounts will halve the time. With premium storage this should be reducing even further.

Example for the input file inputCSV.csv:

    In the example given in the repo, line1 will be running on node0 that parses 2 file shares while the second line parses only 1.
  
    If you want to go through all of the shares in a storage account, put a * and don't overlap the file shares across different lines as they will collide.

ToDO
 
 - Comprehensive error logging and consolidate the reports across all the nodes and email it.
 - Implement strategy to store deleted files - store the file index daily in an Az table and compare it next day.
 - Store daily results in an Azure table or elsewhere so its easy to query and get a report on demand.
 - Handling failures - run backups against file shares on an ad-hoc basis.
