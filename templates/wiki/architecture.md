---
updated: YYYY-MM-DD
covers: [architecture]
status: draft
---

# Architecture

How this system fits together. Keep it high-level — a reader should grasp the shape without opening
much code, then use [index](index.md) to reach specifics.

## Overview

_One paragraph: what kind of system this is (web app, CLI, service, library), and the big pieces._

## Components

- **_<Component A>_** (`<path>`) — _responsibility; what it depends on._
- **_<Component B>_** (`<path>`) — _responsibility._
- _..._

## Data / control flow

_How a typical request / command / operation flows through the components. A short numbered list or
a simple text diagram is enough:_

```
request → <entry> → <router> → <handler> → <data layer> → response
```

## Boundaries & external dependencies

- _External services, APIs, databases, queues this system talks to._
- _Where the seams are (module boundaries, interfaces) that changes should respect._

## Key decisions & constraints

- _Non-obvious design choices and why they exist (so agents don't "fix" them by accident)._
