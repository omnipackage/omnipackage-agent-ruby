[![CI](https://github.com/omnipackage/omnipackage-agent-ruby/actions/workflows/ruby.yml/badge.svg)](https://github.com/omnipackage/omnipackage-agent-ruby/actions/workflows/ruby.yml)
[![OmniPackage repositories badge](https://repositories.omnipackage.org/oleg/omnipackage-agent/omnipackage-agent.svg)](https://web.omnipackage.org/oleg/omnipackage-agent)

# OmniPackage agent

Agent is responsible for building packages. It contains 2 executables:

- `exe/omnipackage` - stand-alone usage without any connection to [OmniPackage web](https://github.com/omnipackage/omnipackage-web)
- `exe/omnipackage-agent` - to be used as a deamon connected to [OmniPackage web](https://github.com/omnipackage/omnipackage-web) server

## Installation

Use repositories provided by OmniPackage itself:

https://web.omnipackage.org/oleg/omnipackage-agent

Or just clone this repo and run  `exe/omnipackage` or `exe/omnipackage-agent` directly. Ruby 3.0 or higher required.

### In Docker

Not recommended especially in production since it requires `--privileged` flag to run containers inside.

To build an image run:
```
docker build -t omnipackage-agent .
```

Use it to build a project:
```
docker run --rm -it --privileged --cgroupns=host -v /tmp/build/:/tmp -v /path/to/project:/project omnipackage-agent omnipackage build /project
```

Change `/tmp/build/` to your desired host build directory, and `/path/to/project` to where the target project is located.

## Usage

Refer to [docs.omnipackage.org](https://docs.omnipackage.org/)
