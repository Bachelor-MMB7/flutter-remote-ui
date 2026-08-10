# Flutter Remote UI

Generative remote UI system for Flutter. Bachelor thesis implementation.

Author: Marvin Helmer, HdM Stuttgart.
Practice partner: [pyck](https://github.com/pyck-ai).

This is a public copy for trying the system out. It carries the source and the workflow
definitions, but no company setup and no company data. The measurements reported in the
thesis were taken with this source, running against a deployed server. The hosting setup
for that server is not included here.

## What this is

A prototype that lets warehouse workflow screens in a Flutter mobile application be
changed on the server, without going through a native release cycle. The screens are
described on the server as text definitions and rendered as native Flutter widgets at
runtime through [Remote Flutter Widgets (RFW)](https://pub.dev/packages/rfw).

The repository holds the artifact of the bachelor thesis _Generative Remote UI for
Flutter in Logistics_. Four properties are evaluated in it, grouped into the three
sub-objectives of the thesis: rendering and composition from server definitions,
deployment time against the app store release path, offline availability and interaction
performance against a natively compiled Flutter baseline.

## Layout

| Path | What it holds |
| --- | --- |
| `apps/server/` | Dart server. Serves one workflow definition per request. |
| `apps/server/definitions/` | The workflow definitions, one folder per tenant. |
| `apps/rfw-client/` | The Flutter app that renders definitions at runtime. |
| `apps/baseline-client/` | The same screens, compiled into the app. The control. |
| `apps/run-so3-block.sh` | Runs one block of the interaction-performance measurement. |
| `docs/rfw-components.md` | Catalog of the eleven widgets, the data keys and the events. |
| `docs/generation-run/` | The prompt and the definition a language model produced from it. |
| `docs/design-decisions.md` | Chronological log of the decisions, with discarded alternatives. |
| `docs/so3-logs/` | The raw tap logs of the four measurement blocks, one line per tap. |

Both clients implement the same eleven widgets under the same names. The difference is
only where the screen comes from. The rfw-client fetches a definition, the
baseline-client has the screens compiled in.

## Requirements

Flutter 3.44.4 or newer, Dart SDK 3.10 or newer. The measurements were taken on an
iPhone 15 Pro with iOS 26.1.

## The server

The server runs on your own machine. The rfw-client fetches from `http://localhost:8080`,
and from `http://10.0.2.2:8080` on Android, because that is how the emulator reaches the
host machine. Both come from `_serverBase`. One route serves the definitions:

```
GET /tenants/<tenant>/workflows/<workflow>.rfw
```

It reads the matching `.rfwtxt`, compiles it to the binary RFW format and returns it.

The apps run even with no server reachable, because the fallback renders a bundled
generic goods receipt that belongs to no tenant. The two tenant workflows need the server
running. Start it before the app:

```sh
cd apps/server
dart pub get
dart run bin/server.dart
```

Compilation happens on every request, so an edited `.rfwtxt` is live as soon as the file
is saved. To run against a hosted server instead, replace the expression in `_serverBase`
(`apps/rfw-client/lib/workflow_screen.dart`) with its base URL.

The deployment time reported in the thesis cannot be reproduced against a local server.
[Reproducing the measurements](#reproducing-the-measurements) explains why.

## Running the apps

```sh
cd apps/rfw-client       # or apps/baseline-client
flutter pub get
flutter run
```

The rfw-client starts on tenant A's goods receipt. The dropdown in the app bar switches
between the two tenants, which re-fetches that tenant's definition.

### What happens when the server is not there

The client gives up on a request after three seconds. If the server is not running, or if
a hosted one has to wake from idle first, the request does not answer in time. The app
then falls back to the definition it cached last, or on a fresh install to the one
bundled in `assets/rfw/default.rfwtxt`, and the log shows:

```
fetch failed (TimeoutException after 0:00:03.000000),
falling back to cached definition
```

That is the fallback working, not a defect. Start the server and run the app again, and it
answers in well under a second. A hosted server that was idle usually answers on the
second attempt. After that the app renders the definition from the server.

The three-second cap and the fallback chain are part of the design. Without the cap the
app would sit on its loading spinner for as long as the network stack keeps the request
open, which is far longer than an operator would wait. The cap ends that wait and hands
over to the fallback, so a workflow screen appears even when the floor connection is
gone. The chain is described in the thesis and verified by three of the test cases.

## Definitions

The definitions live under `apps/server/definitions/<tenant>/workflows/<workflow>.rfwtxt`.

What a definition may contain is documented in [`docs/rfw-components.md`](docs/rfw-components.md).
The catalog lists the eleven widgets with their properties, the four keys under
`data.workflow` and the seven events the client handles. It is maintained by hand and is
also the context a language model is given when it writes a definition. One such run,
the prompt and its result, is kept in [`docs/generation-run/`](docs/generation-run).

## Tests

The functional test cases are not in this repository. They are 27 cases run by hand
against the running app, and they are listed in the appendix of the thesis.

Each client also has `integration_test/so3_test.dart`. That is the driver for the
interaction-performance measurement, not a functional test. It is run through the script,
see [Reproducing the measurements](#reproducing-the-measurements).

## Reproducing the measurements

### Interaction performance

Measured with `apps/run-so3-block.sh`, one block at a time. It builds the app in profile
mode, drives the workflow and writes the tap log. The device id has to be set, the log
directory defaults to the current directory and logs go to `<LOG_DIR>/so3-logs/`:

```sh
DEVICE=your-device-id ./apps/run-so3-block.sh 1 rfw
DEVICE=your-device-id ./apps/run-so3-block.sh 2 baseline
```

Each block runs 168 passes of the workflow, set in the script as
`--dart-define=SO3_PASSES=168`.

The logs of the four blocks reported in the thesis are in [`docs/so3-logs/`](docs/so3-logs),
one line per tap:

```
flutter: SO3 tap_to_frame=6619us build_start=572us step=1
```

### Deployment time

This one needs a deployed server, a local one is not enough. The thesis measures two
things, publishing a changed definition to that server and delivering it to the device.
With a local server there is nothing to publish, because the server compiles on request
and a saved `.rfwtxt` is live at once. The delivery does not go over the internet either.
The deployment configuration is not part of this repository, so the hosting is yours to
set up.

The client still times the delivery and prints it on every fetch:

```
SO2 deployment: fetch=<ms> first_frame=<ms>
```
