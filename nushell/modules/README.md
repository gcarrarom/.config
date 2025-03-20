# NuGUIsh

This is the nuguish module. It implements some of the [oh-my-guish](https://github.com/gcarrarom/oh-my-guish) commands for [NuShell](https://www.nushell.sh/).

## Installation

The installation of this module depends on a working installation of NuShell. Please refer to the [NuShell installation instructions](https://www.nushell.sh/install.html) for more information.

It also depends on adding a new modules path to the NuShell configuration. You can do this by adding the following line to your `env.nu` file: ($nu.env-path)

```shell
$env.NU_LIB_DIRS = [
    ($nu.default-config-dir | path join 'scripts') # add <nushell-config-dir>/scripts
    ($nu.default-config-dir | path join 'modules') # add <nushell-config-dir>/modules <- this line
```

Then you should be able to clone your modules (including this one) to the `modules` directory and add the nuguish module to your NuShell configuration file.

```shell
git clone https://github.com/gcarrarom/nuguish.git ($nu.default-config-dir | path join modules/nuguish)
echo "use nuguish/nuguish.nu *\n" | save --append $nu.config-path
```

## Updates

To update the module, you can simply pull the changes from the repository and restart NuShell.

```shell
cd ($nu.default-config-dir | path join modules/nuguish)
git pull
```

## Commands

### `gitc`
`gitc` is a command that wraps the `git clone` command. It allows you to clone a repository, cd into the directory and set the user and email for the repository.

```shell
gitc <profile> <repository> [git arguments...]
```

In your home directory (`$nu.home-path`), create a file called `.git_profiles.yml`. Example:

```yaml
profiles:
  profile1:
    user:
      name: "John Doe"
      email: "john.doe@example.com"
  profile2:
    user:
      name: "Jane Smith"
      email: "jane.smith@example.com"
```

*Note that if you specify any git arguments, it would be good to set last argument to be directory where you want to clone the repository, this way command will cd into right directory.*

**TODO:**
- [ ] Use `ls -as | where type == dir and modified > ((date now) - 5sec)` to get the last directory created and recursively search for a `.git` directory to set the user and email.
