# Contributing to knife-ec2

We're glad you want to contribute to knife-ec2! The first
step is the desire to improve the project.

## Quick Contributing Steps

1. Create an account on [GitHub](https://github.com).
2. Create an account on the [Chef Supermarket](https://supermarket.chef.io/).
3. [Become a contributor](https://supermarket.chef.io/become-a-contributor) by
signing our Contributor License Agreement (CLA).
4. Create a pull request for your change on [GitHub](https://github.com/chef/knife-ec2/pulls).
5. The knife-ec2 maintainers will review your change, and either merge the
change or offer suggestions.

## The Apache License and the CLA/CCLA
Licensing is very important to open source projects. It helps ensure the
software continues to be available under the terms that the author desired.

Chef uses [the Apache 2.0 license](http://www.apache.org/licenses/LICENSE-2.0)
to strike a balance between open contribution and allowing you to use the
software however you would like to.

The license tells you what rights you have that are provided by the copyright
holder. It is important that the contributor fully understands what rights they
are licensing and agrees to them. Sometimes the copyright holder isn't the
contributor, such as when the contributor is doing work for a company.

To make a good faith effort to ensure these criteria are met, Chef requires an
Individual CLA or a Corporate CLA for contributions. This agreement helps ensure
you are aware of the terms of the license you are contributing your copyrighted
works under, which helps to prevent the inclusion of works in the projects that
the contributor does not hold the rights to share.

It only takes a few minutes to complete a CLA, and you retain the copyright to
your contribution.

You can complete our [Individual
CLA](https://supermarket.chef.io/icla-signatures/new) online. If you're
contributing on behalf of your employer and they retain the copyright for your
works, have your employer fill out our [Corporate
CLA](https://supermarket.chef.io/ccla-signatures/new) instead.

### Chef Obvious Fix Policy

Small contributions such as fixing spelling errors, where the content is small enough
  to not be considered intellectual property, can be submitted by a contributor as a patch,
  without a CLA.

As a rule of thumb, changes are obvious fixes if they do not introduce any new functionality
  or creative thinking. As long as the change does not affect functionality. Some likely
  examples include the following:

* Spelling / grammar fixes
* Typo correction, white space and formatting changes
* Comment clean up
* Bug fixes that change default return values or error codes stored in constants
* Adding logging messages or debugging output
* Changes to ‘metadata’ files like Gemfile, .gitignore, build scripts, etc.
* Moving source files from one directory or package to another

**Whenever you invoke the “obvious fix” rule, please say so in your commit message:**

```
------------------------------------------------------------------------
commit 370adb3f82d55d912b0cf9c1d1e99b132a8ed3b5
Author: juliachild <julia@chef.io>
Date:   Wed Sep 18 11:44:40 2015 -0700

  Fix typo in the README.

  Obvious fix.

------------------------------------------------------------------------
```

## <a name="issues"></a>Issue Tracking

Chef uses Github Issues to track issues with knife-ec2. Issues should be
submitted at https://github.com/chef/knife-ec2/issues/new.

In order to decrease the back and forth in issues, and to help us get to
the bottom of them quickly we use the below issue template. You can copy/paste
this template into the issue you are opening and edit it accordingly.

<a name="issuetemplate"></a>
```
### Environment: [Details about the environment such as the Operating System, Ruby release, etc...]

### Scenario:
[What you are trying to achieve and you can't?]


### Steps to Reproduce:
[If you are filing an issue what are the things we need to do in order to repro your problem?]


### Expected Result:
[What are you expecting to happen as the consequence of above reproduction steps?]


### Actual Result:
[What actually happens after the reproduction steps?]
```

## Using git

You can copy the knife-ec2 repository to your local workstation by running
`git clone git://github.com/chef/knife-ec2.git`.

For collaboration purposes, it is best if you create a GitHub account
and fork the repository to your own account. Once you do this you will
be able to push your changes to your GitHub repository for others to
see and use.

### Branches and Commits

You should submit your patch as a git branch named after the Github
issue, such as GH-22. This is called a _topic branch_ and allows users
to associate a branch of code with the ticket.

It is a best practice to have your commit message have a _summary
line_ that includes the ticket number, followed by an empty line and
then a brief description of the commit. This also helps other
contributors understand the purpose of changes to the code.

```text
    [GH-22] - platform_family and style

    * use platform_family for platform checking
    * update notifies syntax to "resource_type[resource_name]" instead of
      resources() lookup
    * GH-692 - delete config files dropped off by packages in conf.d
    * dropped debian 4 support because all other platforms have the same
      values, and it is older than "old stable" debian release
```

Remember that not all users use Chef in the same way or on the same
operating systems as you, so it is helpful to be clear about your use
case and change so they can understand it even when it doesn't apply
to them.

### More information

Additional help with git is available on the [Community
Contributions](https://docs.chef.io/community_contributions.html#use-git)
page on the Chef Docs site.

## Unit Tests

knife-ec2 is tested with rspec unit tests to ensure changes don't cause
regressions for other use cases. All non-trivial changes must include
additional unit tests.

To run the rspec tests run the following commands from the root of the
project:

    bundle install
    bundle exec rspec spec

**All tests must pass** before your contribution can be merged. Thus it's a good idea
to execute the tests without your change to be sure you understand how to run
them, as well as after to validate that you've avoided regressions.

## Code Review

Chef Software regularly reviews code contributions and provides suggestions
for improvement in the code itself or the implementation.

## Release Cycle

The versioning for Chef Software projects is X.Y.Z.

* X is a major release, which may not be fully compatible with prior
  major releases
* Y is a minor release, which adds both new features and bug fixes
* Z is a patch release, which adds just bug fixes

## Working with the community

These resources will help you learn more about Chef and connect to
other members of the Chef community:

* [Chef Community Guidelines](https://docs.chef.io/community_guidelines.html)
* [Chef Mailing List](https://discourse.chef.io/c/dev)
* #chef and #chef-hacking IRC channels on irc.freenode.net
* [Supermarket site](https://supermarket.chef.io/)
* [Chef Docs](http://docs.chef.io)
* Chef Software Chef [product page](https://www.chef.io/chef/)


## Contribution Do's and Don't's

Please do include tests for your contribution. If you need help, ask on the
[chef-dev mailing list](https://discourse.chef.io/c/dev) or the [#chef-hacking
IRC channel](https://botbot.me/freenode/chef-hacking/). Please provide
evidence of testing your contribution if it isn't trivial so we don't have to
duplicate effort in testing.

Please do **not** modify the version number of the gem, Chef
will select the appropriate version based on the release cycle
information above.

Please do **not** update the `CHANGELOG.md` for a new version. Not all
changes may be merged and released in the same versions. Chef Software
will update the `CHANGELOG.md` when releasing a new version.

## Further Resources

### Fog

Knife-ec2 uses the Fog gem to interact with EC2's API. When there's a new
feature of EC2 that you'd like to utilize in knife-ec2 use cases, that feature
will probably be exposed by Fog. You can read about Fog
at its [project page](https://github.com/fog/fog).

