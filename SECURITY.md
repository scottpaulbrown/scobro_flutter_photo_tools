# Security policy

## Supported versions

Security fixes are made on the latest released version.

## Reporting a vulnerability

Please don't open a public issue for a security problem. Report it privately
through GitHub's
[private vulnerability reporting](https://github.com/scottpaulbrown/scobro_flutter_photo_tools/security/advisories/new).

Include what you found, how to reproduce it, and the versions affected. You
can expect an acknowledgement within a week and a fix or plan within 30 days.

## Scope notes

The package decodes untrusted image files with
[`package:image`](https://pub.dev/packages/image) and Flutter's codecs, and
it never sends data anywhere itself: uploads happen in your own callback.
Rendered output has EXIF metadata (such as location) removed.
