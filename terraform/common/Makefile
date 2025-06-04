#Make terraform plan
## TODO: Add better verification for new plan
plan:
	@echo "Terraform Plan"
	@rm -f plan.tfplan
	@terraform plan -out=plan.tfplan
	@terraform show ./plan.tfplan | grep " # "


# #Get EKS kubeconfig
# kubeconfig:
# 	@echo "Getting EKS kubeconfig"
# 	EKS_CLUSTER_NAME=$$(terraform output -json | jq -r '.eks_cluster_name.value')
# 	AWS_REGION=$$(terraform output -json | jq -r '.eks_cluster_region.value')
# 	@echo "EKS_CLUSTER_NAME: $$EKS_CLUSTER_NAME"
# 	@echo "AWS_REGION: $(AWS_REGION)"
# 	@aws eks update-kubeconfig --name $$EKS_CLUSTER_NAME --region $$AWS_REGION

#Install karpenter
karpenter:
	@echo "Installing Karpenter"
	@helm repo add karpenter https://charts.karpenter.sh
	@helm repo update
	@helm upgrade --install karpenter oci://public.ecr.aws/karpenter/karpenter \
		--version "${KARPENTER_VERSION}" \
		--namespace "karpenter" --create-namespace \
		--set "settings.clusterName=${EKS_CLUSTER_NAME}" \
		--set "settings.interruptionQueue=${KARPENTER_SQS_QUEUE}" \
		--set controller.resources.requests.cpu=1 \
		--set controller.resources.requests.memory=1Gi \
		--set controller.resources.limits.cpu=1 \
		--set controller.resources.limits.memory=1Gi \
		--set replicas=1 \
		--wait
