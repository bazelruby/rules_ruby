## `build.sh`

Anytime you change the Ruby version you must push a new image to Docker Hub.

Email kigster@gmail.com to be added to bazelruby org on hub.docker.com.

### To Upgrade

Change the ruby version in the `Dockerfile` and run:

```bash
cd .circleci
./build.sh
```
