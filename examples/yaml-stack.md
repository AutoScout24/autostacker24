## Example YAML Template
Note that in YAML `@` is a reserved character so if it is the first character
in a string you have to quote the complete string.

```yaml
# AutoStacker24 YAML CloudFormation Template
AWSTemplateFormatVersion: '2010-09-09'
Description: Example WebService Stack
Parameters:
  Environment:
    Type: String
    AllowedValues:
    - Staging
    - Production
  Version:
    Type: String
    Default: latest
  ImageId:
    Type: String
    Default: ami-12345678
  InstanceProfile:
    Type: String
    Default: arn:aws:iam::1234567800:instance-profile/Service
  BastionSSH:
    Type: String
    Default: sg-12345678 # You can put comments here
Mappings:
  EnvironmentMap:
    Staging:
      AvailabilityZones:
      - eu-west-1a
      Subnets:
      - subnet-80907060
      InstanceType: t2.small
      InstanceSecurityGroup: sg-87654321
      ELBSecurityGroup: sg-abcdef00
      DomainName: ci-service.myorg.net
    Production:
      AvailabilityZones:
      - eu-west-1b
      Subnets:
      - subnet-60607060
      InstanceType: t2.small
      InstanceSecurityGroup: sg-ab23ab45
      ELBSecurityGroup: sg-00abcdef
      DomainName: service.myorg.net
Resources:
  LaunchConfig:
    Type: AWS::AutoScaling::LaunchConfiguration
    Properties:
      AssociatePublicIpAddress: true
      EbsOptimized: false
      IamInstanceProfile: "@InstanceProfile"
      ImageId: "@ImageId"
      InstanceMonitoring: false
      InstanceType: "@{Environment[InstanceType]}"
      KeyName: instance_key
      SecurityGroups:
      - "@{Environment[InstanceSecurityGroup]}"
      - "@BastionSSH"
      UserData: |
        #!/bin/bash -xe
        aws ecr get-login --region us-east-1 | /bin/bash
        docker run -d --restart=always -e ENVIRONMENT=@Environment 1234567800.dkr.ecr.us-east-1.amazonaws.com/my-service:@Version
        wget -nv --retry-connrefused --tries=30 --wait=1 --timeout=1 -O- http://localhost:8080/health
        /opt/aws/bin/cfn-signal -e $? --stack @AWS::StackName --resource ASG --region @AWS::Region
  ELB:
    Type: AWS::ElasticLoadBalancing::LoadBalancer
    Properties:
      ConnectionDrainingPolicy:
        Enabled: true
        Timeout: 30
      ConnectionSettings:
        IdleTimeout: 60
      CrossZone: false
      HealthCheck:
        HealthyThreshold: 2
        Interval: 30
        Target: HTTP:8080/health
        Timeout: 5
        UnhealthyThreshold: 3
      LoadBalancerName: "@AWS::StackName"
      Listeners:
      - InstancePort: 8080
        InstanceProtocol: HTTP
        LoadBalancerPort: 80
        Protocol: HTTP
      - InstancePort: 8080
        InstanceProtocol: HTTP
        LoadBalancerPort: 443
        Protocol: HTTPS
        SSLCertificateId: arn:aws:iam::1234567800:server-certificate/service
      Scheme: internet-facing
      SecurityGroups:
      - "@{Environment[ELBSecurityGroup]}"
      Subnets: "@Environment[Subnets]"
      Tags:
      - Key: Name
        Value: "@AWS::StackName"
      - Key: Environment
        Value: "@Environment"
  ASG:
    Type: AWS::AutoScaling::AutoScalingGroup
    Properties:
      AvailabilityZones: "@{Environment[AvailabilityZones]}"
      Cooldown: 600
      DesiredCapacity: 1
      HealthCheckGracePeriod: 180
      HealthCheckType: EC2
      LaunchConfigurationName: "@LaunchConfig"
      LoadBalancerNames:
      - "@ELB"
      MaxSize: 2
      MinSize: 0
      Tags:
      - Key: Name
        Value: "@AWS::StackName"
        PropagateAtLaunch: true
      - Key: Environment
        Value: "@Environment"
        PropagateAtLaunch: true
      VPCZoneIdentifier: "@{Environment[Subnets]}"
    UpdatePolicy:
      AutoScalingRollingUpdate:
        MinInstancesInService: 1
        MaxBatchSize: 2
        PauseTime: PT4M0S
        WaitOnResourceSignals: true
  R53Dns:
    Type: AWS::Route53::RecordSet
    Properties:
      AliasTarget:
        DNSName:
          Fn::GetAtt:
          - ELB
          - CanonicalHostedZoneName
        HostedZoneId:
          Fn::GetAtt:
          - ELB
          - CanonicalHostedZoneNameID
      Comment: "@AWS::StackName"
      HostedZoneName: myorg.net.
      Name: "@{Environment[DomainName]}"
      Type: A
```
