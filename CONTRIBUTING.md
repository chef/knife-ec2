# Contributing to knife-ec2

We are glad you want to contribute to Chef's knife-ec2 plugin! The first step is the desire to improve the project.

You can find the answers to additional frequently asked questions [on the wiki](http://wiki.opscode.com/display/chef/How+to+Contribute).

## Quick-contribute

*   Create an account on our [bug tracker](http://tickets.opscode.com/browse/KNIFE)
*   Sign our contributor agreement (CLA) [
online](https://secure.echosign.com/public/hostedForm?formid=PJIF5694K6L)
    (keep reading if you're contributing on behalf of your employer)
* Create a ticket for your change on the [bug tracker](http://tickets.opscode.com/browse/KNIFE)
* Link to your patch as a rebased git branch or pull request from the ticket
* Resolve the ticket as fixed

We regularly review contributions and will get back to you if we have any suggestions or concerns.

## The Apache License and the CLA/CCLA

Licensing is very important to open source projects, it helps ensure the software continues to be available under the terms that the author desired.
Chef uses the Apache 2.0 license to strike a balance between open contribution and allowing you to use the software however you would like to.

The license tells you what rights you have that are provided by the copyright holder. It is important that the contributor fully understands what rights
they are licensing and agrees to them. Sometimes the copyright holder isn't the contributor, most often when the contributor is doing work for a company.

To make a good faith effort to ensure these criteria are met, Opscode requires a Contributor License Agreement (CLA) or a Corporate Contributor License
Agreement (CCLA) for all contributions. This is without exception due to some matters not being related to copyright and to avoid having to continually
check with our lawyers about small patches.

It only takes a few minutes to complete a CLA, and you retain the copyright to your contribution.

You can complete our contributor agreement (CLA) [
online](https://secure.echosign.com/public/hostedForm?formid=PJIF5694K6L).  If you're contributing on behalf of your employer, have
your employer fill out our [Corporate CLA](https://secure.echosign.com/public/hostedForm?formid=PIE6C7AX856) instead.

## Issue Tracking

You can file tickets to describe the bug you'd like to fix or feature you'd
like to add via the [knife-ec2 project](http://tickets.opscode.com/browse/KNIFE). For your contribution to be reviewed
and merged, you **must** file a ticket.

## Contribution Details

Once you've created the ticket, you can make a pull request to
knife-ec2 on GitHub at <https://github.com/opscode/knife-ec2> that references
that ticket. 

## Testing Instructions

To run tests, run the following Ruby tool commands from the root of your local checkout of
knife-ec2:

    bundle install
    bundle exec rspec spec
    
**All tests must pass** before your contribution can be merged. Thus it's a good idea
to execute the tests without your change to be sure you understand how to run
them, as well as after to validate that you've avoided regressions.

All but the most trivial changes should include **at least one unit test case** to exercise the
new / changed code; please add tests to your pull request in this common case.

## Further Resources

### Fog

Knife-ec2 uses the Fog gem to interact with EC2's API. When there's a new
feature of EC2 that you'd like to utilize in knife-ec2 use cases, that feature
will probably be exposed by Fog. You can read about Fog
at its [project page](https://github.com/fog/fog).
