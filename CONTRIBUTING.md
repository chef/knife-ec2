# Contributing to knife-ec2

We're glad you want to contribute to knife-ec2! The first
step is the desire to improve the project.

## Contribution Process

We have a 3 step process for contributions:

1. Commit changes to a git branch, making sure to sign-off those changes for the [Developer Certificate of Origin](#developer-certification-of-origin-dco).
2. Create a Github Pull Request for your change, following the instructions in the pull request template.
3. Perform a [Code Review](#code-review-process) with the project maintainers on the pull request.

### Code Review Process

Code review takes place in Github pull requests. See [this article](https://help.github.com/articles/about-pull-requests/) if you're not familiar with Github Pull Requests.

Once you open a pull request, project maintainers will review your code and respond to your pull request with any feedback they might have. The process at this point is as follows:

1. Two thumbs-up (:+1:) are required from project maintainers. See the master maintainers document for Chef projects at <https://github.com/chef/chef/blob/master/MAINTAINERS.md>.
2. When ready, your pull request will be tagged with label `Ready For Merge`.
3. Your change will be merged into the project's `master` branch and will be noted in the project's `CHANGELOG.md` at the time of release.

### Developer Certification of Origin (DCO)

Licensing is very important to open source projects. It helps ensure the software continues to be available under the terms that the author desired.

Chef uses [the Apache 2.0 license](https://github.com/chef/chef/blob/master/LICENSE) to strike a balance between open contribution and allowing you to use the software however you would like to.

The license tells you what rights you have that are provided by the copyright holder. It is important that the contributor fully understands what rights they are licensing and agrees to them. Sometimes the copyright holder isn't the contributor, such as when the contributor is doing work on behalf of a company.

To make a good faith effort to ensure these criteria are met, Chef requires the Developer Certificate of Origin (DCO) process to be followed.

The DCO is an attestation attached to every contribution made by every developer. In the commit message of the contribution, the developer simply adds a Signed-off-by statement and thereby agrees to the DCO, which you can find below or at <http://developercertificate.org/>.

```
Developer's Certificate of Origin 1.1

By making a contribution to this project, I certify that:

(a) The contribution was created in whole or in part by me and I
    have the right to submit it under the open source license
    indicated in the file; or

(b) The contribution is based upon previous work that, to the
    best of my knowledge, is covered under an appropriate open
    source license and I have the right under that license to
    submit that work with modifications, whether created in whole
    or in part by me, under the same open source license (unless
    I am permitted to submit under a different license), as
    Indicated in the file; or

(c) The contribution was provided directly to me by some other
    person who certified (a), (b) or (c) and I have not modified
    it.

(d) I understand and agree that this project and the contribution
    are public and that a record of the contribution (including
    all personal information I submit with it, including my
    sign-off) is maintained indefinitely and may be redistributed
    consistent with this project or the open source license(s)
    involved.
```

For more information on the change see the Chef Blog post [Introducing Developer Certificate of Origin](https://blog.chef.io/2016/09/19/introducing-developer-certificate-of-origin/)

#### DCO Sign-Off Methods

The DCO requires a sign-off message in the following format appear on each commit in the pull request:

```
Signed-off-by: Julia Child <juliachild@chef.io>
```

The DCO text can either be manually added to your commit body, or you can add either **-s** or **--signoff** to your usual git commit commands. If you forget to add the sign-off you can also amend a previous commit with the sign-off by running **git commit --amend -s**. If you've pushed your changes to Github already you'll need to force push your branch after this with **git push -f**.

### Chef Obvious Fix Policy

Small contributions, such as fixing spelling errors, where the content is small enough to not be considered intellectual property, can be submitted without signing the contribution for the DCO.

As a rule of thumb, changes are obvious fixes if they do not introduce any new functionality or creative thinking. Assuming the change does not affect functionality, some common obvious fix examples include the following:

- Spelling / grammar fixes
- Typo correction, white space and formatting changes
- Comment clean up
- Bug fixes that change default return values or error codes stored in constants
- Adding logging messages or debugging output
- Changes to 'metadata' files like Gemfile, .gitignore, build scripts, etc.
- Moving source files from one directory or package to another

**Whenever you invoke the "obvious fix" rule, please say so in your commit message:**

```
------------------------------------------------------------------------
commit 370adb3f82d55d912b0cf9c1d1e99b132a8ed3b5
Author: Julia Child <juliachild@chef.io>
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

