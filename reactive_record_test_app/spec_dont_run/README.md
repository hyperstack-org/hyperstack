This directory is here just to make things easier if these tests are failing

If you have test failures then do this:

1) swap the `active_record` directories that are in `spec_dont_run` (this directory)
and spec-opal (the directory that will run specs)

2) move the file that is failing from the `spec_dont_run/active_record` directory and
rerun the test - make sure it still fails, etc.

3) copy the failing file to the proper `spec/reactive_record/` directory

4) update the failing file so that it uses the same style that the other files use in
that directory.  I.e. they typically use capybara plus rspec-steps gem plus isomorphic
helpers to drive the test from the server rspec environment.

**Why?**

Because its just far easier to maintain a single test harness that call run all tests
whether they are server, client, or isomorphic.  Most tests in this gem by definition
are isomorphic so being able to use factory girl to create models, then make sure that
client updates, properly, drive the client to change the models, and make sure that
the server updates properly, is the way to go.

Consult the existing specs in the spec/reactive_record directory and compare them to the
old style files stored in `reactive_record_test_app/test/spec_dont_run/moved_to_main_spec_dir`.


Note: Permissions is superceeded by a different set of tests in the main test spec directory
however the old tests are there in case somebody has a chance to go through and make sure
everything is covered.

Note: Prerendering has not been formally tested... Probably should be its just a bit difficult.
