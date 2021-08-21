#!/bin/sh
#
# Purpose: Quickly do a 'pmapper' analysis of your currently configured account and print out visalization/report 
# Prereqs: follow installation instructions for pmapper in 'README' most importantly the IAM permissions being used by this user see 'required-permissions.json'
# Prereq to visualize install 'graphviz'
# Sudo apt-get install graphviz
# Set your account # as variable

account=* #change to your account

# Set -x #echos out command before execution if you like

# Create Graph in region you need to speed up process, change region as needed

pmapper graph create --include-regions us-east-1

# Visualize all IAM roles / users in account
# Make sure your user running script on local machine can execute creating and saving file to directory your in

echo "Visualizing all roles in account:"
pmapper --account $account visualize --filetype svg

echo "Visualizing priv users only:"
pmapper --account $account visualize --only-privesc --filetype svg

echo "Graph the stats of the account:"
pmapper graph display
pmapper graph display >> analysis.txt

echo "List table of all IAM users via AWS CLI:"
aws iam list-users --output table
aws iam list-users --output table >> analysis.txt

echo "pmapper built in analysis:"
pmapper analysis --output-type text
pmapper analysis --output-type text >> analysis.txt

echo "Which users can escalate privs:"
pmapper --account $account query -s 'preset privesc *'
pmapper --account $account query -s 'preset privesc *' >> analysis.txt

echo "who can create a user:"
pmapper query 'who can do iam:CreateUser'
pmapper query 'who can do iam:CreateUser' >> analysis.txt

echo "What roles can execute expensive instances:" 
pmapper --account $account argquery -s --action 'ec2:RunInstances' --condition 'ec2:InstanceType=c6gd.16xlarge'
pmapper --account $account argquery -s --action 'ec2:RunInstances' --condition 'ec2:InstanceType=c6gd.16xlarge' >> analysis.txt

echo "Who is connected:"
pmapper query 'preset connected * *'
pmapper query 'preset connected * *' >> analysis.txt

echo "Who can get objects from specific ip;"
pmapper query 'who can do s3:GetObject with * when aws:SourceIp=*'
pmapper query 'who can do s3:GetObject with * when aws:SourceIp=*' >> analysis.txt

echo "Who can delete objects in s3:"
pmapper --account $account argquery  --action 's3:delete-objects'
pmapper --account $account argquery  --action 's3:delete-objects' >> analysis.txt

echo "Who has multifactor auth present:"
pmapper query 'who can do aws:MultiFactorAuthPresent'
pmapper query 'who can do aws:MultiFactorAuthPresent' >> analysis.txt

echo "Who can run ec2 run instances:"
pmapper query 'who can do ec2:RunInstances'
pmapper query 'who can do ec2:RunInstances'

echo "Who can create lambda function:"
pmapper query 'who can do lambda:CreateFunction'
pmapper query 'who can do lambda:CreateFunction' >> analysis.txt

echo "Who can expose s3 resources to public aka ENDGAME;"
pmapper query 'preset endgame s3'
pmapper query 'preset endgame s3' >> analysis.txt

echo "Who can endgame all resources:"
pmapper argquery --preset endgame --resource '*'
pmapper argquery --preset endgame --resource '*' >> analysis.txt

echo "Generate,read, and decode credential reports from IAM then put into csv file"
aws iam generate-credential-report
aws iam get-credential-report --output text | base64 --decode >> credentialreport.csv
echo "'credentialreport.csv' generated successfully the 'invalid input' was for datetime stamp not in proper format"
echo "Results in 'analysis.txt', credentialreport.csv, and 'svg' files of working directory"

