#include "FilePicker.h"
#include <QtCore/QDebug>
#include <Foundation/Foundation.h>
#include <UIKit/UIKit.h>

@interface FilePickerSaveDelegate : NSObject <UIDocumentPickerDelegate>
@property (nonatomic, strong) NSString *fileName;
@property (nonatomic, strong) NSString *fileContent;
@end

@implementation FilePickerSaveDelegate

- (instancetype)initWithFileName:(NSString *)fileName content:(NSString *)content {
    self = [super init];
    if (self) {
        self.fileName = fileName;
        self.fileContent = content;
    }
    return self;
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    if (urls.count > 0) {
        NSURL *selectedFolder = [urls firstObject];

        BOOL accessGranted = [selectedFolder startAccessingSecurityScopedResource];
        if (!accessGranted) {
            qDebug() << "Error: No permission to access folder.";
            return;
        }

        NSString *filePath = [selectedFolder.path stringByAppendingPathComponent:self.fileName];

        NSError *error;
        [self.fileContent writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];

        if (error) {
            qDebug() << "Error saving file:" << error.localizedDescription.UTF8String;
        } else {
            qDebug() << "File saved at:" << filePath.UTF8String;
        }

        [selectedFolder stopAccessingSecurityScopedResource];
    }
}

@end

@interface FilePickerProfileDelegate : NSObject <UIDocumentPickerDelegate>
@property (nonatomic, assign) RaccoonFilePicker *picker;
@end

@implementation FilePickerProfileDelegate

- (instancetype)initWithPicker:(RaccoonFilePicker *)picker {
    self = [super init];
    if (self) {
        self.picker = picker;
    }
    return self;
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    if (urls.count > 0) {
        NSURL *selectedFile = [urls firstObject];

        BOOL accessGranted = [selectedFile startAccessingSecurityScopedResource];
        if (!accessGranted) {
            qDebug() << "Error: No permission to access file.";
            return;
        }

        QString filePath = QString::fromNSString(selectedFile.path);
        qDebug() << "filePath:" << filePath;
        NSURL *selectedFileURL = urls.firstObject;
        if (![selectedFileURL.pathExtension isEqualToString:@"profile"]) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                           message:@"Please select a file with the .profile extension."
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
            [alert addAction:okAction];

            UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
            [rootVC presentViewController:alert animated:YES completion:nil];

            return;
        }

        NSError *error = nil;
        NSString *fileContent = [NSString stringWithContentsOfURL:selectedFile encoding:NSUTF8StringEncoding error:&error];

        if (error) {
            qDebug() << "Error reading file:" << error.localizedDescription.UTF8String;
        } else {
            QString content = QString::fromNSString(fileContent);
            emit self.picker->filePicked(filePath, content);
        }

        [selectedFile stopAccessingSecurityScopedResource];
    }
}

@end

@interface FilePickerAnyFileDelegate : NSObject <UIDocumentPickerDelegate>
@property (nonatomic, assign) RaccoonFilePicker *picker;
@end

@implementation FilePickerAnyFileDelegate

- (instancetype)initWithPicker:(RaccoonFilePicker *)picker {
    self = [super init];
    if (self) {
        self.picker = picker;
    }
    return self;
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    if (urls.count > 0) {
        NSURL *selectedFile = [urls firstObject];

        BOOL accessGranted = [selectedFile startAccessingSecurityScopedResource];
        if (!accessGranted) {
            qDebug() << "Error: No permission to access file.";
            return;
        }

        QString filePath = QString::fromNSString(selectedFile.path);
        qDebug() << "Selected file path:" << filePath;

        NSError *error = nil;
        NSString *fileContent = nil;

        fileContent = [NSString stringWithContentsOfURL:selectedFile encoding:NSUTF8StringEncoding error:&error];

        if (error) {
            NSData *fileData = [NSData dataWithContentsOfURL:selectedFile];
            if (fileData) {
                qDebug() << "Binary file loaded successfully.";
                emit self.picker->selectedFile(filePath);
            } else {
                qDebug() << "Error reading file as binary.";
            }
        } else {
            QString content = QString::fromNSString(fileContent);
            emit self.picker->selectedFile(filePath);
        }

        [selectedFile stopAccessingSecurityScopedResource];
    }
}

@end

typedef void (^ExportCompletionHandler)(BOOL success, NSString * _Nullable errorMessage);
@interface FilePickerExportDelegate : NSObject <UIDocumentPickerDelegate>
@property (nonatomic, strong) NSURL *fileURL;
@property (nonatomic, copy) ExportCompletionHandler completionHandler;

- (instancetype)initWithFileURL:(NSURL *)fileURL completion:(ExportCompletionHandler)completion;
@end

@implementation FilePickerExportDelegate

- (instancetype)initWithFileURL:(NSURL *)fileURL completion:(ExportCompletionHandler)completion {
    self = [super init];
    if (self) {
        self.fileURL = fileURL;
        self.completionHandler = completion;
    }
    return self;
}

- (void)presentExportOptionsInViewController:(UIViewController *)viewController {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Експорт файлу"
                                                                   message:@"Оберіть спосіб експорту:"
                                                            preferredStyle:UIAlertControllerStyleActionSheet];

    // "Зберегти у Файли"
    UIAlertAction *saveToFilesAction = [UIAlertAction actionWithTitle:@"Зберегти у Файли"
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * _Nonnull action) {
                                                                  UIDocumentPickerViewController *documentPicker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"public.folder"]
                                                                                                                                                                          inMode:UIDocumentPickerModeOpen];
                                                                  documentPicker.delegate = self;
                                                                  [viewController presentViewController:documentPicker animated:YES completion:nil];
                                                              }];

    // "Поділитися"
    UIAlertAction *shareAction = [UIAlertAction actionWithTitle:@"Поділитися"
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction * _Nonnull action) {
                                                            UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[self.fileURL] applicationActivities:nil];
                                                            [viewController presentViewController:activityVC animated:YES completion:nil];
                                                        }];

    // "Скасувати"
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Скасувати"
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];

    [alert addAction:saveToFilesAction];
    [alert addAction:shareAction];
    [alert addAction:cancelAction];

    [viewController presentViewController:alert animated:YES completion:nil];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    if (urls.count > 0) {
        NSURL *selectedFolder = [urls firstObject];

        BOOL accessGranted = [selectedFolder startAccessingSecurityScopedResource];
        if (!accessGranted) {
            qDebug() << "Error: No permission to access folder.";
            if (self.completionHandler) {
                self.completionHandler(NO, @"No permission to access folder.");
            }
            return;
        }

        NSString *fileName = self.fileURL.lastPathComponent;
        NSURL *destinationURL = [selectedFolder URLByAppendingPathComponent:fileName];

        NSError *error = nil;
        [[NSFileManager defaultManager] copyItemAtURL:self.fileURL toURL:destinationURL error:&error];

        if (error) {
            qDebug() << "Error copy file:" << error.localizedDescription.UTF8String;
            if (self.completionHandler) {
                self.completionHandler(NO, [NSString stringWithUTF8String:error.localizedDescription.UTF8String]);
            }
        } else {
            qDebug() << "File copied:" << destinationURL.path.UTF8String;
            if (self.completionHandler) {
                self.completionHandler(YES, nil);
            }
        }

        [selectedFolder stopAccessingSecurityScopedResource];
    }
}
@end


RaccoonFilePicker::RaccoonFilePicker(QObject *parent) : QObject(parent) {}

void RaccoonFilePicker::pickFolderAndSaveFile(const QString &fileName, const QString &content) {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *nsFileName = fileName.toNSString();
        NSString *nsContent = content.toNSString();

        FilePickerSaveDelegate *delegate = [[FilePickerSaveDelegate alloc] initWithFileName:nsFileName content:nsContent];

        UIDocumentPickerViewController *picker =
            [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"public.folder"]
                                                                   inMode:UIDocumentPickerModeOpen];
        picker.delegate = delegate;
        picker.allowsMultipleSelection = NO;

        UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
        [rootVC presentViewController:picker animated:YES completion:nil];
        emit profileExported();
    });
}

void RaccoonFilePicker::pickProfileFile() {
    dispatch_async(dispatch_get_main_queue(), ^{
        FilePickerProfileDelegate *delegate = [[FilePickerProfileDelegate alloc] initWithPicker:this];

        UIDocumentPickerViewController *picker =
            [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"public.data"]
                                                                   inMode:UIDocumentPickerModeOpen];
        picker.delegate = delegate;
        picker.allowsMultipleSelection = NO;

        UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
        [rootVC presentViewController:picker animated:YES completion:nil];
    });
}

void RaccoonFilePicker::pickAnyFile() {
    dispatch_async(dispatch_get_main_queue(), ^{
        FilePickerAnyFileDelegate *delegate = [[FilePickerAnyFileDelegate alloc] initWithPicker:this];

        UIDocumentPickerViewController *picker =
            [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"public.item"]
                                                                   inMode:UIDocumentPickerModeOpen];
        picker.delegate = delegate;
        picker.allowsMultipleSelection = NO;

        UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
        [rootVC presentViewController:picker animated:YES completion:nil];
    });
}

void RaccoonFilePicker::exportFile(const QString &filePath) {
    qDebug() << "exportFile" << filePath;    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *nsFilePath = filePath.toNSString();
        NSURL *fileURL = [NSURL fileURLWithPath:nsFilePath];

        if (![[NSFileManager defaultManager] fileExistsAtPath:nsFilePath]) {
            qDebug() << "Файл не знайдено: " << filePath;
            QString errMsg = "File not found";
            emit error(errMsg);
            return;
        }

        FilePickerExportDelegate *delegate = [[FilePickerExportDelegate alloc] initWithFileURL:fileURL completion:^(BOOL success, NSString * _Nullable errorMessage) {
                                                                                        if (success) {
                                                                                            emit copied();
                                                                                        } else {
                                                                                            emit error(QString::fromNSString(errorMessage));
                                                                                        }
                                                                                    }];

        UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
        [delegate presentExportOptionsInViewController:rootVC];
    });
}
