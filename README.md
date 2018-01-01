# STOP!

This is not prime-time ready and is a good ol' pile of hacks™.

This intends to fix *some* issues that can be automated.

Do not expect much.

## Usage

Well, you shouldn't.

### `fixer.rb`

But first, you will need a packages.json from `unstable`.

```
$ ./generate-packages-json.sh
```

Then, a checkout of nixpkgs at a hard-coded location.

**THAT CHECKOUT WILL BE FORCIBLY RESET HARD**.

Run this script, it should be run with cwd being this dir.

```
$ ./fixer.rb
```

Since you're using nix, and this script uses nix-shell and ruby, there's no
dependencies to get, it is handled transparently.


### `problems.rb`

```
$ ./problems.rb  | xclip
```
