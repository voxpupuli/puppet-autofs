# Contributing

If you have a bugfix or new feature that you would like to contribute to this puppet module, please find or open an issue about it first.
Talk about what you would like to do.
It may be that somebody is already working on it, or that there are particular issues that you should know about before implementing the change.

I enjoy working with contributors to get their code accepted.
There are many approaches to fixing a problem and it is important to find the best approach before writing too much code.

## Development Setup

There are a few testing prerequisites to meet:

* Ruby.
  As long as you have a recent version with `bundler` available, `bundler` will install development dependencies.

You can then install the necessary gems with:

    bundle install

I strongly recommend using rbenv or rvm to create a local Ruby development environment, this will help isolate gems specific to this module from other projects you may be working on.

## Testing

Running through the tests on your own machine can get ahead of any problems others (or Travis) may run into.

First, run the rspec tests and ensure it completes without errors with your changes. These are lightweight tests.

    rake spec

Next, run the more thorough acceptance tests.
By default, the test will run against a CentOS 7 Vagrant image - other available hosts can be found in `spec/acceptance/nodesets`.
For example, to run the acceptance tests against Ubuntu 14.04, run the following:

    BEAKER_set=ubuntu-1404-x64 rake acceptance

The final output line will tell you which, if any, tests failed.

## Opening Pull Requests

In summary, to open a new PR:

* Run the tests to confirm everything works as expected
* Rebase your changes.
  Update your local repository with the most recent code from this puppet module repository, and rebase your branch on top of the latest master branch.
* Submit a pull request
  Push your local changes to your forked copy of the repository and submit a pull request.
  In the pull request, describe what your changes do and mention the number of the issue where discussion has taken place, eg "Closes #123".

Then sit back and wait!
There will probably be discussion about the pull request and, if any changes are needed, I would love to work with you to get your pull request merged into this puppet module.
