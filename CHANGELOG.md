2.8.1 (2017-12-13)
------------------
* Issue - autostacker24 depends only on aws-sdk-cloudformation
  See [related GitHub pull request #52](https://github.com/AutoScout24/autostacker24/pull/52)

2.8.0 (2017-10-27)
------------------
* Feature - Support role arn for deployments
  See [related GitHub pull request #47](https://github.com/AutoScout24/autostacker24/pull/47)

* Feature - Allow listing stacks from cli
  See [related GitHub pull request #49](https://github.com/AutoScout24/autostacker24/pull/49)

* Issue - Fail on empty values for --param parameter
  See [related GitHub pull request #48](https://github.com/AutoScout24/autostacker24/pull/48)

2.7.0 (2017-03-21)
------------------
* Feature - Use AWS_SHARED_CREDENTIALS_FILE environment variable to overwrite path of shared credential file
  See [related GitHub pull request #46](https://github.com/AutoScout24/autostacker24/pull/46)

2.6.0 (2017-02-23)
------------------
* Feature - Add --params parameter to load template parameters from file
  See [related GitHub pull request #43](https://github.com/AutoScout24/autostacker24/pull/44)

2.5.0 (2016-11-11)
------------------
* Feature - Allow to pass in custom cloudformation parameters
  See [related GitHub pull request #41](https://github.com/AutoScout24/autostacker24/pull/41) 

* Issue - Fix relative file includes
  See [related GitHub pull request #39](https://github.com/AutoScout24/autostacker24/pull/39) 

2.4.0 (2016-10-20)
------------------
* Issue - Compatibility with CloudFormation YAML
  See [related GitHub pull request #35](https://github.com/AutoScout24/autostacker24/pull/35) 

2.3.0 (2016-09-26)
------------------
* Issue - Optimize YAML support
  See [related GitHub pull request #34](https://github.com/AutoScout24/autostacker24/pull/34) 

2.2.0 (2016-09-22)
------------------
* Feature - Support new CloudFormation capabilities
  See [related GitHub pull request #33](https://github.com/AutoScout24/autostacker24/pull/33) and [related GitHub issue #32](https://github.com/AutoScout24/autostacker24/issues/32)

* Feature - Separate cli commands show and process
  See [related GitHub pull request #31](https://github.com/AutoScout24/autostacker24/pull/31)

2.1.0 (2016-07-05)
------------------
* Feature - Allowing overriding of timeouts
  See [related GitHub pull request #27](https://github.com/AutoScout24/autostacker24/pull/27)

2.0.1 (2016-05-03)
------------------
* Issue - Incorrect regex for yaml detection

  See [related GitHub pull request #26](https://github.com/AutoScout24/autostacker24/pull/26)


2.0.0 (2016-04-25)
------------------

* Feature - Syntactic Sugar for "Fn::GetAtt"

  `@Resource.Attrib` gets translated to `{"Fn::GetAtt": ["Resource", "Attrib"]}`

  __Breaking Change__  
  In order to limit an expression, they must be enclosed in curly braces. For example, to have @Subdomain.example.com expanded as {"Fn::Join":["",[{"Ref":"Subdomain"},".example.com"]]}, it must be written as @{Subdomain}.example.com to explicitly limit the expression to a simple reference.

  See [related GitHub pull request #24](https://github.com/AutoScout24/autostacker24/pull/24) and [related GitHub issue #20](https://github.com/AutoScout24/autostacker24/issues/20).


1.x
------------------

* No changelog entries.
