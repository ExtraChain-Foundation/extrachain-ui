#include "ImagePicker.h"
#include <MobileCoreServices/MobileCoreServices.h>
#include <QGuiApplication>
#include <QQuickWindow>
#include <QtGui/qpa/qplatformnativeinterface.h>
#include <UIKit/UIKit.h>

#define PICKER 6
#define CAMERA 7

@interface ImagePickerDelegate : NSObject <UIImagePickerControllerDelegate,
                                           UINavigationControllerDelegate> {
  ImagePicker *m_imagePicker;
}
@end

@implementation ImagePickerDelegate

- (id)initWithObject:(ImagePicker *)imagePicker {
  self = [super init];
  if (self) {
    m_imagePicker = imagePicker;
  }
  return self;
}

- (void)imagePickerController:(UIImagePickerController *)picker
    didFinishPickingMediaWithInfo:(NSDictionary *)info {
  NSURL *url = [info objectForKey:UIImagePickerControllerMediaURL];
  NSString *path = [NSSearchPathForDirectoriesInDomains(
      NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
  NSLog(@"VideoURL = %@", url);
  if (url.absoluteString.length != 0) {
    NSLog(@"chect = video url is not empty");

    NSURL *tempURL = [NSURL fileURLWithPath:NSTemporaryDirectory()
                                isDirectory:true];
    NSURL *tempFileURL =
        [tempURL URLByAppendingPathComponent:url.lastPathComponent];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager copyItemAtURL:url.absoluteURL toURL:tempFileURL error:nil];
    NSLog(@"chect = video url is not empty. new url = %@", tempFileURL);
    m_imagePicker->setPath(QString::fromNSString(tempFileURL.absoluteString));
    [picker dismissViewControllerAnimated:YES completion:nil];
    return;
  }

  NSString *fileName = [NSString
      stringWithFormat:@"/image-%f.jpg", [[NSDate date] timeIntervalSince1970]];
  path = [path stringByAppendingString:fileName];
  UIImage *image = nil;
  if ([info objectForKey:UIImagePickerControllerEditedImage]) {
    image = [info objectForKey:UIImagePickerControllerEditedImage];
  } else {
    image = [info objectForKey:UIImagePickerControllerOriginalImage];
  }

  if (picker.view.tag == CAMERA && m_imagePicker->saveImageToCameraRoll()) {
    UIImageWriteToSavedPhotosAlbum(
        [info objectForKey:UIImagePickerControllerOriginalImage], nil, nil,
        nil);
  }
  UIImage *uImage = [UIImage imageWithCGImage:[image CGImage]];
  [UIImageJPEGRepresentation(uImage, m_imagePicker->imageQuality())
      writeToFile:path
          options:NSAtomicWrite
            error:nil];
  m_imagePicker->setImagePath(QString::fromNSString(path));
  [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller
    didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
  if (controller.documentPickerMode == UIDocumentPickerModeImport) {
    for (NSURL *obj in urls) {
      NSString *myString = [obj absoluteString];
      Q_EMIT m_imagePicker->file(QString::fromNSString(myString));
      break;
    }
  }
}

@end

ImagePicker::ImagePicker(QQuickItem *parent)
    : QQuickItem(parent),
      m_delegate([[ImagePickerDelegate alloc] initWithObject:this]),
      m_imageScale(1.0), m_imageQuality(1.0), m_saveImageToCameraRoll(false) {}

void ImagePicker::openPicker() {
  UIView *view = static_cast<UIView *>(
      QGuiApplication::platformNativeInterface()->nativeResourceForWindow(
          "uiview", window()));

  UIViewController *qtController = [[view window] rootViewController];
  UIImagePickerController *imageController =
      [[[UIImagePickerController alloc] init] autorelease];

  [imageController setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
  [imageController setAllowsEditing:NO];
  [imageController setDelegate:id(m_delegate)];
  [imageController
      setMediaTypes:@[ (NSString *)kUTTypeImage, (NSString *)kUTTypeMovie ]];

  [qtController presentViewController:imageController
                             animated:YES
                           completion:nil];
}

void ImagePicker::openCamera() {
  UIView *view = static_cast<UIView *>(
      QGuiApplication::platformNativeInterface()->nativeResourceForWindow(
          "uiview", window()));
  UIViewController *qtController = [[view window] rootViewController];
  UIImagePickerController *imageController =
      [[[UIImagePickerController alloc] init] autorelease];
  [imageController setSourceType:UIImagePickerControllerSourceTypeCamera];
  [imageController setAllowsEditing:YES];
  [imageController setDelegate:id(m_delegate)];
  [imageController setMediaTypes:@[ (NSString *)kUTTypeImage ]];
  [[imageController view] setTag:CAMERA];
  [qtController presentViewController:imageController
                             animated:YES
                           completion:nil];
}

void ImagePicker::openFiles() {
  UIView *view = static_cast<UIView *>(
      QGuiApplication::platformNativeInterface()->nativeResourceForWindow(
          "uiview", window()));
  UIViewController *qtController = [[view window] rootViewController];
  NSArray *types = @[
    (NSString *)kUTTypeImage, (NSString *)kUTTypeSpreadsheet,
    (NSString *)kUTTypePresentation, (NSString *)kUTTypePDF,
    (NSString *)kUTTypeDatabase, (NSString *)kUTTypeFolder,
    (NSString *)kUTTypeZipArchive, (NSString *)kUTTypeVideo
  ];
  UIDocumentPickerViewController *docPicker =
      [[UIDocumentPickerViewController alloc]
          initWithDocumentTypes:@[ @"public.data" ]
                         inMode:UIDocumentPickerModeImport];
  [docPicker setDelegate:id(m_delegate)];
  [qtController presentViewController:docPicker animated:YES completion:nil];
}
