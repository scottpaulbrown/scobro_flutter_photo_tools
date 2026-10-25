/// Pick a photo, let the user crop, rotate and zoom it to any aspect ratio,
/// and hand the result to your own upload code.
///
/// The quickest way in is [PhotoFlow.run], which shows the source sheet,
/// picks, opens the editor and calls your `upload` callback:
///
/// ```dart
/// final result = await PhotoFlow.run<String>(
///   context,
///   options: const RenderOptions(outputLongEdge: 512),
///   upload: (image) => api.uploadAvatar(image.bytes, image.mimeType),
/// );
/// if (result case PhotoFailed(:final message)) {
///   ScaffoldMessenger.of(context)
///       .showSnackBar(SnackBar(content: Text(message)));
/// }
/// ```
///
/// The pieces are usable on their own too:
///
/// - **Editing:** [showPhotoEditor], [PhotoEditorPage], [PhotoEditor] with
///   [PhotoEditorController].
/// - **Rendering and checks:** [PhotoRenderer], [RenderOptions],
///   [ImageValidator], [FramingGeometry].
/// - **Picking:** [PhotoSourcePicker], [PluginPhotoSourcePicker],
///   [showPhotoSourceSheet].
/// - **Display:** [PhotoAvatar], [ChangePhotoBadge], [PhotoPreviewStrip],
///   [VersionedImageLoader].
/// - **Customising:** [PhotoToolsScope], [PhotoToolsStrings],
///   [PhotoToolsTheme].
///
/// Test helpers live in `package:scobro_flutter_photo_tools/testing.dart`.
library;

export 'src/core/edited_image.dart' show EditedImage;
export 'src/core/framing_geometry.dart' show FramingGeometry;
export 'src/core/image_format.dart' show ImageFormat, detectImageFormat;
export 'src/core/image_validator.dart'
    show
        EmptyImageError,
        ImageTooLargeError,
        ImageValidationError,
        ImageValidator,
        UnsupportedImageFormatError,
        ValidationRules;
export 'src/core/photo_framing.dart' show PhotoFraming;
export 'src/core/photo_renderer.dart' show PhotoRenderer;
export 'src/core/render_options.dart'
    show JpegOutput, OutputFormat, PngOutput, RenderOptions;
export 'src/picking/photo_source_picker.dart' show PhotoSourcePicker;
export 'src/picking/pick_result.dart'
    show
        CameraDenied,
        PickCancelled,
        PickRefused,
        PickResult,
        Picked,
        PickedImage;
export 'src/picking/picker_options.dart' show PickerOptions;
export 'src/picking/plugin_photo_source_picker.dart'
    show PluginPhotoSourcePicker;
export 'src/theme/photo_tools_scope.dart'
    show PhotoToolsScope, PhotoToolsScopeData;
export 'src/theme/photo_tools_strings.dart' show PhotoToolsStrings;
export 'src/theme/photo_tools_theme.dart' show PhotoToolsTheme;
export 'src/editor/crop_guide_shape.dart' show CropGuideShape;
export 'src/editor/framed_image.dart' show FramedImage, paintFramedImage;
export 'src/editor/photo_editor.dart' show PhotoEditor;
export 'src/editor/photo_editor_controller.dart'
    show PhotoEditorController, PhotoEditorStatus;
export 'src/editor/photo_editor_page.dart'
    show PhotoEditorPage, showPhotoEditor;
export 'src/photo_tools_keys.dart' show PhotoToolsKeys;
export 'src/widgets/photo_preview_strip.dart'
    show PhotoPreviewSpec, PhotoPreviewStrip;
export 'src/flow/photo_flow.dart' show PhotoFlow;
export 'src/flow/photo_flow_result.dart'
    show PhotoCancelled, PhotoFailed, PhotoFlowResult, PhotoRemoved, PhotoSaved;
export 'src/sources/custom_photo_source.dart' show CustomPhotoSource;
export 'src/sources/photo_source_sheet.dart'
    show
        CameraSourceChoice,
        CustomSourceChoice,
        DeviceSourceChoice,
        PhotoSourceChoice,
        RemoveSourceChoice,
        showPhotoSourceSheet;
export 'src/loading/versioned_image_loader.dart'
    show PhotoBytesFetcher, VersionedImageLoader;
export 'src/loading/versioned_memory_image.dart' show VersionedMemoryImage;
export 'src/widgets/change_photo_badge.dart' show ChangePhotoBadge;
export 'src/widgets/photo_avatar.dart' show PhotoAvatar;
