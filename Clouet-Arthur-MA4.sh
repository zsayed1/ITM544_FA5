#!/bin/bash
# The shell script has a usage pattern provide the data before hand and then reference it.
#example ./Clouet-Arthur-ma3.sh ArthurLBSouthAm ArthurSouthAmKey ArthurInstance 4 Arthur_Security   
# In this shell script then value $1  would be the first argument about...ArthurLBSouthAm
# $2 would reference the second value ArthurSouthAmKey and so forth...

ELBNAME=$1
KEYPAIR=$2
CLIENT_TOKENS=$3
N_INSTANCES=$4
SECURITY_GROUP_NAME=$5

if [ $# != 5 ]
  then 
  echo "This script needs 5 arguments/variables to run; ELB-NAME, KEYPAIR, CLIENT_TOKENS, NUMBER OF INSTANCES, and SECURITY_GROUP_NAME"
else

#Step 1: Create a VPC with a /28 cidr block (see the aws example) - assign the vpc-id to a variable  you can awk column $6 on the --output=text to get the value
vpc_id=`aws ec2 create-vpc --cidr-block 10.0.0.0/28 --output=text | awk '{print $6}'`
echo $vpc_id
 
#Step 2: Create a subnet for the VPC - use the same /28 cidr block that you used in step 1.  Save the subnet-id to a variable (retrieve it by awk column 6)
subnet_id=`aws ec2 create-subnet --vpc-id $vpc_id --cidr-block 10.0.0.0/28 --output=text | awk '{print $6}'`
echo $subnet_id

#Step 3: Create a custom security group per this VPC - store the group ID in a variable (awk $1) 
group_id=`aws ec2 create-security-group --group-name $SECURITY_GROUP_NAME --description "Security Group of VPC" --vpc-id $vpc_id | awk '{print $1}'`
echo $group_id

#step 3b:  Open the ports For SSH and WEB access to your security group
aws ec2 authorize-security-group-ingress --group-id $group_id --protocol tcp --port 80 --cidr 0.0.0.0/0 
aws ec2 authorize-security-group-ingress --group-id $group_id --protocol tcp --port 22 --cidr 0.0.0.0/0 

#Step 4: We need to create an internet gateway so that our VPC has internet access - save the gaetway ID to a variable (awk column 2) 
gateway_id=`aws ec2 create-internet-gateway | awk '{print $2}'`
echo $gateway_id

#step 4b:  We need to modify the VPC attributes to enable dns support and enable dns hostnames
aws ec2 modify-vpc-attribute --vpc-id $vpc_id --enable-dns-support "{\"Value\":true}"
aws ec2 modify-vpc-attribute --vpc-id $vpc_id --enable-dns-hostnames "{\"Value\":true}"


#Step 5 Modify-subnet-attribute - tell the subnet id to --map-public-ip-on-launch 
aws ec2 modify-subnet-attribute --subnet-id $subnet_id --map-public-ip-on-launch

#Step 6:  We need to attach the internet gateway we created to our VPC
aws ec2 attach-internet-gateway --internet-gateway-id $gateway_id --vpc-id $vpc_id

#Step 6b: Now lets create a ROUTETABLE variable and use the command create-route-table command to get the routetable id us  | grep rtb | awk {'print $2'}
rtb_id=`aws ec2 create-route-table --vpc-id $vpc_id | grep rtb | awk {'print $2'}`
echo $rtb_id

#Step 6c: Now we create a route to be attached to the route table
aws ec2 create-route --route-table-id $rtb_id --destination-cidr-block 0.0.0.0/0 --gateway-id $gateway_id
# Now associate that route with a route-table-id and a subnet-id
aws ec2 associate-route-table --route-table-id $rtb_id --subnet-id $subnet_id

#Step 7:  Now create a ELBURL variable and lets create a load balancer - change from the EC2 cli docs to the ELB docs. 
ELBURL=`aws elb create-load-balancer --load-balancer-name $ELBNAME --listeners Protocol=HTTP,LoadBalancerPort=80,InstanceProtocol=HTTP,InstancePort=80 --subnets $subnet_id --security-groups $group_id --output=text | awk {'print $1'}`
echo $ELBURL
 
echo -e "\nFinished launching ELB and sleeping 25 seconds"
for i in {0..25}; do echo -ne '.'; sleep 1;done

#step 7b: This is the elb configure-health-check this section is what the loadbalancer will be checking and how often(
aws elb configure-health-check --load-balancer-name $ELBNAME --health-check Target=HTTP:80/index.php,Interval=30,UnhealthyThreshold=2,HealthyThreshold=2,Timeout=3

echo -e "\nFinished ELB health check and sleeping 30 seconds"
for i in {0..25}; do echo -ne '.'; sleep 1;done

#Step 8: Here is where we launch our instances, provide the VPC configuration, provide client-tokens, and provide the user-data via the file:// handler setup-MA3.sh
aws ec2 run-instances --image-id ami-b83c0aa5 --count $N_INSTANCES --instance-type t2.micro --key-name $KEYPAIR --subnet-id $subnet_id --security-group-ids $group_id --client-token $CLIENT_TOKENS --iam-instance-profile Name=MA4Role --block-device-mappings '{"DeviceName": "/dev/xvdb", "Ebs": {"VolumeSize": 10}}' --user-data file://setup-MA4.sh --output=table
 
echo -e "\nFinished launching EC2 Instances and sleeping 60 seconds"
for i in {0..60}; do echo -ne '.'; sleep 1;done

#Step 9: Here we declare an array in BASH and list our instances - then we use the --filters Name=client-token,Values=(your value here)   --output=text | grep INSTANCES | awk {'print $*'}  that should get your the instance-ids
declare -a ARRAY 
ARRAY=(`aws ec2 describe-instances --filters Name=client-token,Values=$CLIENT_TOKENS --output text | grep INSTANCES | awk {'print $8'}`)
echo -e "\nListing Instances, filtering their instance-id, adding them to an ARRAY and sleeping 15 seconds"
for i in {0..15}; do echo -ne '.'; sleep 1;done

#Step 10: Here the first line calculates the length of the array $# is a system variable that know its length.   Now we loop through the instance array and add each instance to our loadbalancer one by one and print out the progress. I give this one to you 
LENGTH=${#ARRAY[@]}
echo "ARRAY LENGTH IS $LENGTH"
for (( i=0; i<${LENGTH}; i++)); 
  do
  echo "Registering ${ARRAY[$i]} with load-balancer $ELBNAME" 
  aws elb register-instances-with-load-balancer --load-balancer-name $ELBNAME --instances ${ARRAY[$i]} --output=table 
echo -e "\nLooping through instance array and registering each instance one at a time with the load-balancer.  Then sleeping 60 seconds to allow the process to finish. )"
    for y in {0..60} 
    do
      echo -ne '.'
      sleep 1
    done
 echo "\n"
done

echo -e "\nWaiting an additional 3 minutes (180 second) - before opening the ELB in a webbrowser"
for i in {0..180}; do echo -ne '.'; sleep 1;done


#Last Step
#firefox $ELBURL &

fi  #End of if statement
