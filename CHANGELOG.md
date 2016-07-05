Unreleased Changes
------------------


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
