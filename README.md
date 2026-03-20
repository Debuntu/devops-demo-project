# devops-demo-project
An end to end devops project to display on my resume.

Project Summary: 
1. In this project, we first build a portfolio web app using python flask. We create the docker image for that app and store it in AWS ECR. (to see how we did this check the README.md under ./portfolio-webapp directory)

2. We create our aws infrastructure (VPC, EKS etc) using terraform and running through gitlab pipeline.

3. Deploy our portfolio web app into our provisioned EKS cluster using our kubernetes config files (located under ./deploying_portfolio-webapp_into_EKS)




To install the AWS Application Load Balancer follow the below steps- 

----CREATING CLUSTER WITH FARGATE PROFILE-------
#spin up the eks cluster with fargate profile ensuring that we have met the prerequisites mentioned at https://docs.aws.amazon.com/eks/latest/userguide/lbc-helm.html

aws eks update-kubeconfig --region us-east-1 --name tf-cluster

#we have created fargate profile with game-2048 and kube0system namespaces and we will be deloying our apps and alb in game-2048 namespace. So lets create it first.

kubectl create namespace portfolio --save-config

#If you get  degraded core dns add on error, make sure add on version is compatible with the eks version you used. We can check it running
the following aws cli command-

aws eks describe-addon-versions --addon-name {addon_name} --kubernetes-version {kubernetes_version}


-------------INSTALLING AWS LOAD BALANCER CONTROLLER USING HELM---------------------
#download the iam_policy.json file
curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.11.0/docs/install/iam_policy.json

#crete the iam policy using the json file
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json

#create the iam service account 
eksctl create iamserviceaccount \
  --cluster=tf-cluster \
  --namespace=portfolio \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::949100095136:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve

#add helm repo
helm repo add eks https://aws.github.io/eks-charts

#update helm repo for eks
helm repo update eks

#install aws load balancer
  helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n portfolio \
  --set clusterName=tf-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=us-east-1 \
  --set vpcId=vpc-0307f18a9db13e25d 

  #deploying portfolio-webapp application
  kubectl apply -f flask-deployment.yaml
  kubectl apply -f flask-service.yaml 
  kubectl apply -f flask-ingress.yaml   


#work around for security group rules. onc its successfully deployed,we can get the ingress- 

kubectl get ingress -n portfolio
NAME           CLASS   HOSTS   ADDRESS                                                                        PORTS   AGE
ingress-2048   alb     *       http://k8s-portfoli-flaskpor-1d9e35ba76-1507855371.us-east-1.elb.amazonaws.com   80     20m

However, the address wouldn't be reachable yet from internet as our configuration is not complete yet. 
To do so, we need to add the following inbound rule to our Shared Backend SecurityGroup for LoadBalancer that is associated with our load balancer. 

Type: HTTP
Protocol: TCP
Port Range: 80
Source: sg-0123456789abcdef (ALB's managed security group ID)

now if we try again the ingress address, the application will be reachable from internet.

