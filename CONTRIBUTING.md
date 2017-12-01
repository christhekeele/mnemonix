Contributing
============

Thanks for your interest in contributing to Mnemonix!
There are several things you can do to help out:

- [Report bugs](#reporting-bugs)
- [Submit your usecase](#creating-guides)
- [Improve documentation](#improving-documentation)
- [Add tests](#adding-tests)
- [Participate on GitHub](#triaging-contributions)
- [Contribute stores](#contributing-stores)
- [Implement new feature-sets](#implementing-features)
- [Build integrations](#building-integrations)

Reporting bugs
--------------

All bug reports are welcome in the [issue tracker](https://github.com/christhekeele/mnemonix/pulls).
Make sure to search around before filing new bugs; someone may have encountered the same issue
and the discussion around it may solve your problem.

Please follow the issue template if you can't find an existing discussion about your problem:

- Specify the erlang, Elixir, and Mnemonix versions you are using
- Mention the store module or particular function giving you grief
- Describe what you wanted to happen
- Provide any backtraces you've encountered
- Add any other tips to reproduce

Creating guides
---------------

We use our [GitHub wiki](https://github.com/christhekeele/mnemonix/wiki) to document various ways people are using Mnemonix.

Anyone can edit it, so if you don't see a guide for your use-case, or you can build upon instructions for an existing one, [go nuts](https://github.com/christhekeele/mnemonix/wiki/_new?wiki%5Bname%5D=Howto%3A)!

Improving documentation
-----------------------

We measure the quality of our documentation with [Inch CI](https://inch-ci.org/github/christhekeele/mnemonix). If you are looking for a way to get involved, improving our documentation is possibly the highest-value entry-level way to help out!

Inch isn't the only heuristic to decide which documentation needs to be improved: any time you've ever tried something with Mnemonix and been even midly confused is a sign that you can help us clarify how to use it.

The task `mix inch` can give you in-terminal reccommendations for functions that could benefit from further documentation.

Adding tests
------------

Expanding our test suite is the highest-value way to contribute to Mnemonix if you are pretty comfortable with Elixir. Doctests and edge cases are particularly cherished.

### External systems setup

Some parts of the test suite are contingent upon configration of out-of-memory backends. If they can't be detected, the parts of the suite that rely on them will be skipped. Detection of these systems can be configured through environment variables:

- Mnesia
  - `FILESYSTEM_TEST_DIR`: The location of a filesystem Elixir can read from and write to. 
    - Default: `System.tmp_dir/0`
- Redis
  - `REDIS_TEST_HOST`: The hostname of a redis server. 
    - Default: `localhost`
  - `REDIS_TEST_PORT`: The port on the host redis is accessible at. 
    - Default: `6379`
- Memcached
  - `MEMCACHED_TEST_HOST`: The hostname of a memcached instance. 
    - Default: `localhost`
  - `MEMCACHED_TEST_PORT`: The port on the host memcached is accessible at. 
    - Default: `11211`
- ElasticSearch
  - `ELASTIC_SEARCH_TEST_HOST`: The hostname of an ElasticSearch instance. 
    - Default: `localhost`
  - `ELASTIC_SEARCH_TEST_PORT`: The port on the host ElasticSearch is accessible at. 
    - Default: `9200`

If you want to fail the test suite if any backend cannot be accessed, set the environment variable `ALL_BACKENDS=true`.

### Doctests

By default, the test suite omits doctests. This is because, by nature of the library, for full working examples in documentation to act as integration tests, some external state must be stored in an out-of-memory system. Normal tests have the opportunity to correctly configure these backends; doctests do not.

If you wish to run them anyways, use the environment variable `DOCTESTS=true`. For them to pass, your system must be configured using the defaults in the backend setup steps specified above.

The CI server fulfills these requirements, so if you can't, you can always configure your fork to use [travis](https://travis-ci.org) too, to get the same build environment we use to vet all pull requests.

Triaging contributions
----------------------

The [GitHub Triage project](https://github.com/christhekeele/mnemonix/projects/1) surrounding Mnemonix is where potential contributions are evaluated and assigned. Issues and pull requests pending review or corresponding to a regression are listed therein.

In particular:

- [items under consideration](https://github.com/christhekeele/mnemonix/projects/1?card_filter_query=is%3Aopen+label%3A%22status%3A+under+consideration%22) are open for discussion
- [planned unassigned issues](https://github.com/christhekeele/mnemonix/projects/1?card_filter_query=type%3Aissue+label%3A%22status%3A+planned%22+no%3Aassignee) are great candidates for pull requests
- [unreviewed unassigned pull requests](https://github.com/christhekeele/mnemonix/projects/1?card_filter_query=type%3Apr+label%3A%22status%3A+awaiting+review%22+no%3Aassignee) are welcome to be reviewed

If you want to be assigned to something, or have any questions about anything, just leave a comment on the item.

Contributing stores
-------------------

Instructions on how to add a new store to Mnemonix can be [found in the wiki](https://github.com/christhekeele/mnemonix/wiki/Making-a-new-store).

Implementing features
---------------------

A description of how to build new feature-sets for Mnemonix can be [found in the wiki](https://github.com/christhekeele/mnemonix/wiki/Adding-a-new-feature-set).

Building integrations
---------------------

If you can think of a task so appropriate for Mnemonix that you think we should support it out of the box, [propose an integration](https://github.com/christhekeele/mnemonix/issues/new) for it!

Worst-case scenario, you can always publish such a package as `mnemonix-<xxx>` to make your integration publicly available, but we're happy to integrate solid use-cases into Mnemonix itself.

Integrations should live within the `lib` directory but ***outside*** the `lib/mnemonix` folder. The Mnemonix [Plug Session store](https://github.com/christhekeele/mnemonix/blob/master/lib/plug/session/mnemonix.ex) integration is a good example of this.
