import 'package:flutter/material.dart';

import 'src/fake_photo_server.dart';
import 'src/gallery_app.dart';

void main() => runApp(GalleryApp(server: FakePhotoServer()));
