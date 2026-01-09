#!/bin/bash

# ==========================================
# AWS Auto Scaling Verification Script
# ==========================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REGIONS=("eu-west-2" "eu-central-1")
REGION_NAMES=("France (London)" "Germany (Frankfurt)")
ASG_NAMES=("prod-france-medusa-asg" "prod-germany-medusa-asg")

# Functions
print_header() {
  echo -e "\n${BLUE}=========================================="
  echo -e "$1"
  echo -e "==========================================${NC}\n"
}

print_success() {
  echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
  echo -e "${RED}❌ $1${NC}"
}

print_warning() {
  echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
  echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if AWS CLI is installed
check_aws_cli() {
  print_header "Checking AWS CLI"
  
  if ! command -v aws &> /dev/null; then
    print_error "AWS CLI is not installed"
    echo "Install it with: brew install awscli"
    exit 1
  fi
  
  print_success "AWS CLI is installed"
  aws --version
}

# Check AWS credentials
check_aws_credentials() {
  print_header "Checking AWS Credentials"
  
  if aws sts get-caller-identity &> /dev/null; then
    print_success "AWS credentials are configured"
    aws sts get-caller-identity
  else
    print_error "AWS credentials are not configured"
    echo "Configure them with: aws configure"
    exit 1
  fi
}

# List Auto Scaling Groups
list_asgs() {
  local region=$1
  local region_name=$2
  
  print_header "Auto Scaling Groups in $region_name ($region)"
  
  asgs=$(aws autoscaling describe-auto-scaling-groups \
    --region "$region" \
    --query 'AutoScalingGroups[*].[AutoScalingGroupName,MinSize,MaxSize,DesiredCapacity,length(Instances)]' \
    --output table 2>/dev/null)
  
  if [ -z "$asgs" ]; then
    print_warning "No Auto Scaling Groups found"
  else
    echo "$asgs"
    print_success "Auto Scaling Groups listed"
  fi
}

# Describe specific ASG
describe_asg() {
  local region=$1
  local asg_name=$2
  local region_name=$3
  
  print_header "Details for $asg_name in $region_name"
  
  if ! aws autoscaling describe-auto-scaling-groups \
    --region "$region" \
    --auto-scaling-group-names "$asg_name" &> /dev/null; then
    print_warning "ASG $asg_name not found. It may not be deployed yet."
    return
  fi
  
  # Get ASG details
  asg_details=$(aws autoscaling describe-auto-scaling-groups \
    --region "$region" \
    --auto-scaling-group-names "$asg_name" \
    --query 'AutoScalingGroups[0]' 2>/dev/null)
  
  # Extract key information
  min_size=$(echo "$asg_details" | jq -r '.MinSize')
  max_size=$(echo "$asg_details" | jq -r '.MaxSize')
  desired=$(echo "$asg_details" | jq -r '.DesiredCapacity')
  instances=$(echo "$asg_details" | jq -r '.Instances | length')
  health_check=$(echo "$asg_details" | jq -r '.HealthCheckType')
  
  echo "📊 Configuration:"
  echo "   Min Size: $min_size"
  echo "   Max Size: $max_size"
  echo "   Desired Capacity: $desired"
  echo "   Current Instances: $instances"
  echo "   Health Check Type: $health_check"
  
  # List instances
  echo -e "\n🖥️  Instances:"
  echo "$asg_details" | jq -r '.Instances[] | "   - \(.InstanceId): \(.HealthStatus) (\(.LifecycleState))"'
  
  print_success "ASG details retrieved"
}

# List scaling policies
list_scaling_policies() {
  local region=$1
  local asg_name=$2
  local region_name=$3
  
  print_header "Scaling Policies for $asg_name in $region_name"
  
  if ! aws autoscaling describe-auto-scaling-groups \
    --region "$region" \
    --auto-scaling-group-names "$asg_name" &> /dev/null; then
    print_warning "ASG $asg_name not found"
    return
  fi
  
  policies=$(aws autoscaling describe-policies \
    --region "$region" \
    --auto-scaling-group-name "$asg_name" \
    --query 'ScalingPolicies[*].[PolicyName,PolicyType,AdjustmentType,ScalingAdjustment]' \
    --output table 2>/dev/null)
  
  if [ -z "$policies" ]; then
    print_warning "No scaling policies found"
  else
    echo "$policies"
    print_success "Scaling policies listed"
  fi
}

# List CloudWatch alarms
list_cloudwatch_alarms() {
  local region=$1
  local region_name=$2
  local asg_name=$3
  
  print_header "CloudWatch Alarms in $region_name"
  
  alarms=$(aws cloudwatch describe-alarms \
    --region "$region" \
    --alarm-name-prefix "prod-" \
    --query 'MetricAlarms[*].[AlarmName,StateValue,MetricName,Threshold,ComparisonOperator]' \
    --output table 2>/dev/null)
  
  if [ -z "$alarms" ]; then
    print_warning "No CloudWatch alarms found"
  else
    echo "$alarms"
    print_success "CloudWatch alarms listed"
  fi
}

# Get scaling activity history
get_scaling_activity() {
  local region=$1
  local asg_name=$2
  local region_name=$3
  
  print_header "Recent Scaling Activities for $asg_name in $region_name"
  
  if ! aws autoscaling describe-auto-scaling-groups \
    --region "$region" \
    --auto-scaling-group-names "$asg_name" &> /dev/null; then
    print_warning "ASG $asg_name not found"
    return
  fi
  
  activities=$(aws autoscaling describe-scaling-activities \
    --region "$region" \
    --auto-scaling-group-name "$asg_name" \
    --max-records 5 \
    --query 'Activities[*].[StartTime,StatusCode,Description]' \
    --output table 2>/dev/null)
  
  if [ -z "$activities" ]; then
    print_warning "No scaling activities found"
  else
    echo "$activities"
    print_success "Scaling activities listed"
  fi
}

# Get current CPU metrics
get_cpu_metrics() {
  local region=$1
  local asg_name=$2
  local region_name=$3
  
  print_header "Current CPU Metrics for $asg_name in $region_name"
  
  if ! aws autoscaling describe-auto-scaling-groups \
    --region "$region" \
    --auto-scaling-group-names "$asg_name" &> /dev/null; then
    print_warning "ASG $asg_name not found"
    return
  fi
  
  # Get metrics for the last hour
  end_time=$(date -u +%Y-%m-%dT%H:%M:%S)
  start_time=$(date -u -v-1H +%Y-%m-%dT%H:%M:%S)
  
  metrics=$(aws cloudwatch get-metric-statistics \
    --region "$region" \
    --namespace AWS/EC2 \
    --metric-name CPUUtilization \
    --dimensions Name=AutoScalingGroupName,Value="$asg_name" \
    --start-time "$start_time" \
    --end-time "$end_time" \
    --period 300 \
    --statistics Average \
    --query 'Datapoints[*].[Timestamp,Average]' \
    --output table 2>/dev/null)
  
  if [ -z "$metrics" ]; then
    print_warning "No metrics available yet"
  else
    echo "$metrics"
    print_success "CPU metrics retrieved"
  fi
}

# Main menu
show_menu() {
  echo -e "\n${BLUE}==========================================
AWS Auto Scaling Verification Tool
==========================================${NC}"
  echo "1) Check all regions overview"
  echo "2) Detailed check for France (eu-west-2)"
  echo "3) Detailed check for Germany (eu-central-1)"
  echo "4) View CloudWatch alarms (all regions)"
  echo "5) View scaling activity history"
  echo "6) View CPU metrics (last hour)"
  echo "0) Exit"
  echo ""
  read -p "Choose an option: " choice
  
  case $choice in
    1)
      check_aws_cli
      check_aws_credentials
      for i in "${!REGIONS[@]}"; do
        list_asgs "${REGIONS[$i]}" "${REGION_NAMES[$i]}"
      done
      show_menu
      ;;
    2)
      describe_asg "${REGIONS[0]}" "${ASG_NAMES[0]}" "${REGION_NAMES[0]}"
      list_scaling_policies "${REGIONS[0]}" "${ASG_NAMES[0]}" "${REGION_NAMES[0]}"
      get_scaling_activity "${REGIONS[0]}" "${ASG_NAMES[0]}" "${REGION_NAMES[0]}"
      show_menu
      ;;
    3)
      describe_asg "${REGIONS[1]}" "${ASG_NAMES[1]}" "${REGION_NAMES[1]}"
      list_scaling_policies "${REGIONS[1]}" "${ASG_NAMES[1]}" "${REGION_NAMES[1]}"
      get_scaling_activity "${REGIONS[1]}" "${ASG_NAMES[1]}" "${REGION_NAMES[1]}"
      show_menu
      ;;
    4)
      for i in "${!REGIONS[@]}"; do
        list_cloudwatch_alarms "${REGIONS[$i]}" "${REGION_NAMES[$i]}" "${ASG_NAMES[$i]}"
      done
      show_menu
      ;;
    5)
      for i in "${!REGIONS[@]}"; do
        get_scaling_activity "${REGIONS[$i]}" "${ASG_NAMES[$i]}" "${REGION_NAMES[$i]}"
      done
      show_menu
      ;;
    6)
      for i in "${!REGIONS[@]}"; do
        get_cpu_metrics "${REGIONS[$i]}" "${ASG_NAMES[$i]}" "${REGION_NAMES[$i]}"
      done
      show_menu
      ;;
    0)
      print_success "Goodbye!"
      exit 0
      ;;
    *)
      print_error "Invalid option"
      show_menu
      ;;
  esac
}

# Start
check_aws_cli
check_aws_credentials
show_menu
