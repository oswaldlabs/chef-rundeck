# Changelog 2.2.0
## Release Summary
### Deprecation Warning!
If you have been relying on chef-rundeck squashing node environment, role and run list data into the 'tags' field, be aware that this is going to change.  Rundeck has supported custom resource attributes in node filters for quite some time now.  If you rely on the current behavior, please consider pinning against chef-rundeck 2.x.
  * Better data validation on chef-rundeck.json.
  * Expanded functional test coverage.
  * Better documentation.

# Changelog 2.1.0
## Release Summary
* As some of the others have mentioned partial search is the way to go. We have seen 80%-90% improvement in performance. In addition we have introduced caching via a tmp file, this allows large chef node data not to remain in memory and slow down responses. Sinatra also will now run in env 'production' by default.

### New CLI params:

  * --env (production/development) (default: production)
  * --partial-search (true/false) - Only supported when using Chef Server 11 (default: false)
* --timeout (cache timeout in seconds) (default: 30)

# Changelog - 2.0.0
## Release Summary
  * Added support for search defined project resource definitions
  * Added support for Rundeck 2.0 and custom attributes
* Added support for Windows Systems in Rundeck node configuration (via overthere-winrm)
  * Refactor xml node generation  
# Changelog - 1.0.1
## Release Summary
  * Fixes to allow us to test Chef 11 and Chef 10 in Travis, based on the Chefspec way.
# Changelog - 1.0.0
## Release Summary
  * chef-rundeck is under new management (GitHub org name is 'oswaldlabs').  We use it at work in production and we are serious about maintaining it.  If you have suggestions or code that you would like to contribute, particularly if it improves our test coverage, please send us a pull request or open a GitHub issue.
  * A basic functioning test suite that builds under Travis-CI and Ruby 1.9.2/1.9.3, connects to a Hosted Chef organization and generates a simple Rundeck resource model.  ("rake spec" to test it for yourself!)
  * chef-rundeck should now drop a pidfile at startup and remove it during normal shutdown.
* Chef node tags now appear as tags in the generated Rundeck resource model.  (Thanks, giorgio-v!)

## Detailed Changes
  * [Tags from node](https://github.com/oswaldlabs/chef-rundeck/commit/d83373be4b903595d4db30d8c41a0a3bad340994) (giorgio-v)
  * [Initial attempt at Travis-ification.](https://github.com/oswaldlabs/chef-rundeck/commit/f64bdfce1dd12368f8c2364dd29b8d8acc63c606) (Steven Wagner)
  * [Slight refactoring for Ruby 1.9/RSpec + Travis ...](https://github.com/oswaldlabs/chef-rundeck/commit/89b1e22ebd7b611aa1ce8f28d1364a24cbddb814) (Steven Wagner)
  * [Added jeweler dependency to make Travis happy.](https://github.com/oswaldlabs/chef-rundeck/commit/4cad7308687b4c2964474421b7f0028123bffad6) (Steven Wagner)
  * [New fancy markdown README, ditch old busted RDoc README.](https://github.com/oswaldlabs/chef-rundeck/commit/df015dbd7771c331e76898c30e90102868793f28) (Steven Wagner)
  * [Sorry, Travis, adding the development gems back in.](https://github.com/oswaldlabs/chef-rundeck/commit/659f413872c5923cf534aa964da92e9c2b0bda5b) (Steven Wagner)
  * [Added new Authors](https://github.com/oswaldlabs/chef-rundeck/commit/de29b9c2c516a1bae1521a702b45233383a30231) (Brian Scott)
  * [Update Bundle](https://github.com/oswaldlabs/chef-rundeck/commit/2f83030f879c47a638037f24de74f6b5e9a270a1) (Brian Scott)
  * [Removed task check deps](https://github.com/oswaldlabs/chef-rundeck/commit/26c1599dc2fe0c3865e80ca55abffee50e648033) (Brian Scott)
  * [Attempt at adding specs](https://github.com/oswaldlabs/chef-rundeck/commit/3d108b773ad0c34423060e508d275087693c0cb9) (Brian Scott)
  * [Adding client.rb and client key for a test Chef org.](https://github.com/oswaldlabs/chef-rundeck/commit/27aae944b4cc8cc58ef6fbb34dbcba9eb375d2d1) (Steven Wagner)
  * [Simple, stupid script for use in setting up a Travis worker.](https://github.com/oswaldlabs/chef-rundeck/commit/58b02ff7eb0378e7c20f412a85537625018a3131) (Steven Wagner)
  * [Added Chef client configuration install script.](https://github.com/oswaldlabs/chef-rundeck/commit/5d9ede2bb5c2736b10ba5401636a100dac9e9416) (Steven Wagner)
  * [Script didn't get executed at the proper time. Let's try after_install -> before_script ...](https://github.com/oswaldlabs/chef-rundeck/commit/d27eed173abc94469d83117999a31469af7500f2) (Steven Wagner)
  * [rdoc -> markdown for README, new email.](https://github.com/oswaldlabs/chef-rundeck/commit/7d1b27844c9e8a2f74e456a1524cfabebc4d4f8b) (Steven Wagner)
  * [Paths now relative to root of repo.](https://github.com/oswaldlabs/chef-rundeck/commit/92cf6ae73dd84ef0393dbf45a24ff9f2a5f3078c) (Steven Wagner)
  * [We can sudo!](https://github.com/oswaldlabs/chef-rundeck/commit/74533fd4f2d0264ccd488a93ed9a746dc0d517c1) (Steven Wagner)
  * [Ensuring that :node_name is set.](https://github.com/oswaldlabs/chef-rundeck/commit/de1e858d431492cc1a965a511ecd8f7c2a70b5ba) (Steven Wagner)
  * [Debug output](https://github.com/oswaldlabs/chef-rundeck/commit/e1eac806cba0207415d41179ddab18b3f22ae5f3) (Steven Wagner)
  * [Modifying stuff to work with Travis.](https://github.com/oswaldlabs/chef-rundeck/commit/9dbba97c7bd4d68f3b1413387217125fc7881f00) (Steven Wagner)
  * [configure -> config_file, oops](https://github.com/oswaldlabs/chef-rundeck/commit/ecc076674236fbd806b8f4c749dcf80fea6834ae) (Steven Wagner)
  * [Fixed failed spec in spec_helper](https://github.com/oswaldlabs/chef-rundeck/commit/5940e4fbeadc2fa486ce84d518fb538e7592b5c5) (Brian Scott)
  * [Spec test](https://github.com/oswaldlabs/chef-rundeck/commit/9a5fc66deb0513889de53a372b73031c99d5a6b8) (Brian Scott)
  * [Added default web UI value (Hosted Chef) to pass tests.](https://github.com/oswaldlabs/chef-rundeck/commit/6c49cd1b143283bb4637f66bcbcd0feec21e4575) (Steven Wagner)
  * [Adding some chef-rundeck-specific config values.](https://github.com/oswaldlabs/chef-rundeck/commit/6d0ae6e81fd890dad9b5388a559dfd6bbcb2d56f) (Steven Wagner)
  * [Drop a pidfile at startup. Should nuke it if the app stops.  Appends port number for multi-tenant deployments.](https://github.com/oswaldlabs/chef-rundeck/commit/af63dcf91260d0f2c3f4882d14f71f0cffb4f838) (Steven Wagner)
  * [Merge pull request #21 from leftathome/manage_pidfile](https://github.com/oswaldlabs/chef-rundeck/commit/98f30ddf318f61a70c4a824c2896da96c7435473) (Brian Scott)
  * [default node_name to fqdn. fixes #11](https://github.com/oswaldlabs/chef-rundeck/commit/efd6e1aec07b749dd7b288141dcf349bad49ced1) (Joseph Anthony Pasquale Holsten)
  * [Load config in test](https://github.com/oswaldlabs/chef-rundeck/commit/83c2d9b6558f02877b5a86b1ff8419b3d3b118a5) (Joseph Anthony Pasquale Holsten)
  * [Set ChefRundeck.username in test](https://github.com/oswaldlabs/chef-rundeck/commit/3e7e7632a1e39b95124221ba0fd9d7e69373dc5f) (Joseph Anthony Pasquale Holsten)
  * [Set web_ui_url in test](https://github.com/oswaldlabs/chef-rundeck/commit/e1a24b232522dfda24d52b1701152fd3958c0ca5) (Joseph Anthony Pasquale Holsten)
  * [Merge pull request #18 from simplymeasured/default-to-fqdn-for-node-name](https://github.com/oswaldlabs/chef-rundeck/commit/ecf4833ad067f983db24910485bfff0519dddc5c) (Brian Scott)
  * [Added Nokogiri development dependency. Used for XML validation in testing.](https://github.com/oswaldlabs/chef-rundeck/commit/91dfff2dcaa431582155f8eab0217bcd1b49854d) (Steven Wagner)
  * [Added simple test to validate XML output.](https://github.com/oswaldlabs/chef-rundeck/commit/eec5573c89dac33e1aea45f2f41319aa9218d4b5) (Steven Wagner)
  * [Bump chef to 11.6.0.](https://github.com/oswaldlabs/chef-rundeck/commit/7c0146c72d46c033b20917a92eb9cee7214603eb) (Steven Wagner)
  * [Merge pull request #17 from giorgio-v/chef-tags](https://github.com/oswaldlabs/chef-rundeck/commit/c1333410a4b9ea70c30574727d11557da5d71d7b) (Brian Scott)
  * [Merge pull request #22 from leftathome/travis_fixes](https://github.com/oswaldlabs/chef-rundeck/commit/12a8c79ecfa25c012d98a6202c87369c1ca0dc55) (Brian Scott)
  * [Use Chef REST API](https://github.com/oswaldlabs/chef-rundeck/commit/d122c213680b8c3ce3afa85a316d7849e72c5c48) (Joseph Martin)
  * [Merge pull request #23 from hugespoon/rest-api](https://github.com/oswaldlabs/chef-rundeck/commit/aa4530cf765afdf01d108562a78961fc90dbe19d) (Brian Scott)
  * [Fix spec target so that it works from command-line.](https://github.com/oswaldlabs/chef-rundeck/commit/aee31730f6f2520eda2ec6265a7c8bf0bd251879) (Steven Wagner)
