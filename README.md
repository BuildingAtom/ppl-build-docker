# Docker to help with building the Parma Polyhedral Library

This docker is intended to be used as an initial build environment for the [PPL library](https://www.bugseng.com/content/parma-polyhedra-library)
To start, once this repository has been cloned or the main scripts downloaded, you will need to clone the PPL repository as a subfolder of this current directory.

```bash
git clone git://git.bugseng.com/ppl/ppl.git
```

Specify the PPL version to build by checking out the right branch:

```bash
git checkout ppl-1_2-branch
```

Once done, you can enter the build environment by running the `start-env.sh` script.
This script will first build the docker container if needed, then proceed to drop you into a persistant interactive build container.

```bash
./start-env.sh
```

Finally, once you're inside the docker, you'll want to run this the first time (only do this if you need to rebuild from scratch).
You may also want to run a `make clean` or `git reset --hard` if you're redoing the build process from scratch.

```bash
cd ppl
autoreconf --install
autoupdate
./configure
```

After that, you can just run `make` inside the ppl repo to build the main library.
To build documentation, you'll want to build the main library first, then go to the documentation folder and execute any one of the following:

```bash
make user-html
make devref-html
# The following does not appear to work after ppl-1.1 as the pdf doesn't seem to generate anymore.
make world
```

---

If you want to restart the build container because something went wrong somewhere, add the restart argument.

```bash
./start-env.sh restart
```

\[TODO - Partial implementation\] If you want to clear off the build container and associated images, add the clean argument.

```bash
./start-env.sh clean
```

\[TODO - Not implemented\] If you want to use this in a script, use -- and specify the command you would like to execute in quotes after

```bash
./start-env.sh -- "cd ppl; make"
```
