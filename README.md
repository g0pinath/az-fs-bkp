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
 
 GITLAB CI Variables required.
 
 The following GITLAB variables needs to be setup.
ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID, CI_DEPLOY_USER, GIT_PUSH_URL,
GIT_TOKEN, aks_name, aks_rg_name, az_acr_name, az_acr_pwd, az_acr_repo_name, az_acr_usr, base_gitlab_image_url, client_id,
client_secret,  subscription_id, tenant_id
