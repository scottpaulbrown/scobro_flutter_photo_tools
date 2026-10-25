# Upload recipes

`PhotoFlow.run` never talks to a server itself. You give it an `upload`
callback that receives an `EditedImage` and returns whatever your API answers
with (a URL, a version, a record). These recipes show that callback for common
stacks. Every `EditedImage` carries:

- `bytes`: the encoded picture
- `mimeType`: `image/jpeg` or `image/png`, for `Content-Type`
- `suggestedFileName([stem])`: for example `avatar.jpg`
- `width`, `height`, `format`, `framing`

If the callback throws, the flow returns `PhotoFailed`. Pass `errorMessage`
to turn your own exceptions into text for the user:

```dart
errorMessage: (error) => switch (error) {
  DioException(response: Response(statusCode: 413)) => 'That photo is too big.',
  _ => 'The photo could not be saved. Please try again.',
},
```

## Dio (multipart)

```dart
upload: (image) async {
  final form = FormData.fromMap({
    'file': MultipartFile.fromBytes(
      image.bytes,
      filename: image.suggestedFileName('avatar'),
      contentType: DioMediaType.parse(image.mimeType),
    ),
  });
  final response = await dio.put<Map<String, dynamic>>(
    '/users/me/photo',
    data: form,
  );
  return response.data!['photoVersion'] as String;
},
```

## `http` (multipart)

```dart
upload: (image) async {
  final request = http.MultipartRequest(
    'PUT',
    Uri.parse('https://api.example.com/users/me/photo'),
  )
    ..headers['Authorization'] = 'Bearer $token'
    ..files.add(
      http.MultipartFile.fromBytes(
        'file',
        image.bytes,
        filename: image.suggestedFileName('avatar'),
        contentType: MediaType.parse(image.mimeType), // package:http_parser
      ),
    );
  final response = await http.Response.fromStream(await request.send());
  if (response.statusCode != 200) {
    throw HttpException('Upload failed (${response.statusCode})');
  }
  return jsonDecode(response.body)['photoVersion'] as String;
},
```

## Raw body (`http`)

When the endpoint takes the picture as the request body:

```dart
upload: (image) async {
  final response = await http.put(
    Uri.parse('https://api.example.com/users/me/photo'),
    headers: {'Content-Type': image.mimeType, 'Authorization': 'Bearer $token'},
    body: image.bytes,
  );
  if (response.statusCode >= 300) throw HttpException('${response.statusCode}');
  return response.headers['etag']!;
},
```

## Firebase Storage

```dart
upload: (image) async {
  final ref = FirebaseStorage.instance
      .ref('avatars/${user.uid}.${image.fileExtension}');
  await ref.putData(image.bytes, SettableMetadata(contentType: image.mimeType));
  return ref.getDownloadURL();
},
```

## Presigned URL (S3, GCS, Azure Blob)

Ask your backend for a short-lived upload URL, then `PUT` the bytes to it:

```dart
upload: (image) async {
  final ticket = await api.createPhotoUpload(contentType: image.mimeType);
  final response = await http.put(
    Uri.parse(ticket.uploadUrl),
    headers: {'Content-Type': image.mimeType},
    body: image.bytes,
  );
  if (response.statusCode >= 300) throw HttpException('${response.statusCode}');
  await api.confirmPhotoUpload(ticket.id);
  return ticket.id;
},
```

## Showing progress

`onBusy` reports `true` while the upload runs and `false` when it ends. Wire
it to a `ChangePhotoBadge`:

```dart
onBusy: (busy) => setState(() => _uploading = busy),
```

## Fetching photos back

For photos behind your auth, give `VersionedImageLoader` a fetcher using the
same client, and `PhotoAvatar` shows them:

```dart
final loader = VersionedImageLoader(
  fetch: (id, version) async {
    final response = await http.get(
      Uri.parse('https://api.example.com/users/$id/photo?v=$version'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return response.statusCode == 200 ? response.bodyBytes : null;
  },
);
```
