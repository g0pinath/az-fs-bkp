cronjob-template-base.j2 - this is the base template file to generate the cronjobs k8s template. J2 engine creates the template based on 
this base file and a values file - dynamic-cronjob-actual-values.yml

cronjob-values-base.yml - this is the base template file for values.This is used to generate the file dynamic-cronjob-actual-values.yml
The PS script gen-allvales-forj2.ps1 creates this using the base template file for values.

J2 engine applies dynamic-cronjob-actual-values.yml on cronjob-template-base.j2 to generate the actual cronjobs template.