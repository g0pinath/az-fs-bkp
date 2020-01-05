	src == cronjob-template-base.j2
	
	dest == k8s-templates/cronjob-template-final-withvalues.yml
	
	input vars == dynamic-cronjob-actual-values.yml
	
	ansible_file == generate-cronjob-template.yml

How is the input vars generated?

j2-templates\scripts\gen-allValues-forJ2.ps1 uses input.csv file for values and template cronjob-values-base.yml.
By applying the values in csv file on the template, the input vars file is generated.

Can this also be j2 bases?
yes, PS script is used only to show more than 1 way to do this.