/******************************************************************************
 * Copyright (c) 2008-2012 Transmission authors and contributors
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 *****************************************************************************/

#import "BlocklistDownloaderViewController.h"
#import "BlocklistDownloader.h"
#import "PrefsController.h"
#import "NSStringAdditions.h"

@interface BlocklistDownloaderViewController (Private)

- (instancetype)initWithPrefsController:(PrefsController*)prefsController;
- (void)startDownload;

@end

@implementation BlocklistDownloaderViewController

BlocklistDownloaderViewController* fBLViewController = nil;
+ (void)downloadWithPrefsController:(PrefsController*)prefsController
{
    if (!fBLViewController)
    {
        fBLViewController = [[BlocklistDownloaderViewController alloc] initWithPrefsController:prefsController];
        [fBLViewController startDownload];
    }
}

- (void)awakeFromNib
{
    fButton.title = NSLocalizedString(@"Cancel", "Blocklist -> cancel button");

    CGFloat const oldWidth = NSWidth(fButton.frame);
    [fButton sizeToFit];
    NSRect buttonFrame = fButton.frame;
    buttonFrame.size.width += 12.0; //sizeToFit sizes a bit too small
    buttonFrame.origin.x -= NSWidth(buttonFrame) - oldWidth;
    fButton.frame = buttonFrame;

    fProgressBar.usesThreadedAnimation = YES;
    [fProgressBar startAnimation:self];
}

- (void)cancelDownload:(id)sender
{
    [[BlocklistDownloader downloader] cancelDownload];
}

- (void)setStatusStarting
{
    fTextField.stringValue = [NSLocalizedString(@"Connecting to site", "Blocklist -> message") stringByAppendingEllipsis];
    fProgressBar.indeterminate = YES;
}

- (void)setStatusProgressForCurrentSize:(NSUInteger)currentSize expectedSize:(long long)expectedSize
{
    NSString* string = NSLocalizedString(@"Downloading blocklist", "Blocklist -> message");
    if (expectedSize != NSURLResponseUnknownLength)
    {
        fProgressBar.indeterminate = NO;

        NSString* substring = [NSString stringForFilePartialSize:currentSize fullSize:expectedSize];
        string = [string stringByAppendingFormat:@" (%@)", substring];
        fProgressBar.doubleValue = (double)currentSize / expectedSize;
    }
    else
    {
        string = [string stringByAppendingFormat:@" (%@)", [NSString stringForFileSize:currentSize]];
    }

    fTextField.stringValue = string;
}

- (void)setStatusProcessing
{
    //change to indeterminate while processing
    fProgressBar.indeterminate = YES;
    [fProgressBar startAnimation:self];

    fTextField.stringValue = [NSLocalizedString(@"Processing blocklist", "Blocklist -> message") stringByAppendingEllipsis];
    fButton.enabled = NO;
}

- (void)setFinished
{
    [NSApp endSheet:fStatusWindow];
    [fStatusWindow orderOut:self];

    fBLViewController = nil;
}

- (void)setFailed:(NSString*)error
{
    [NSApp endSheet:fStatusWindow];
    [fStatusWindow orderOut:self];

    NSAlert* alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:NSLocalizedString(@"OK", "Blocklist -> button")];
    alert.messageText = NSLocalizedString(@"Download of the blocklist failed.", "Blocklist -> message");
    alert.alertStyle = NSWarningAlertStyle;

    alert.informativeText = error;

    [alert beginSheetModalForWindow:fPrefsController.window completionHandler:^(NSModalResponse returnCode) {
        [alert.window orderOut:self];

        fBLViewController = nil;
    }];
}

@end

@implementation BlocklistDownloaderViewController (Private)

- (instancetype)initWithPrefsController:(PrefsController*)prefsController
{
    if ((self = [super init]))
    {
        fPrefsController = prefsController;
    }

    return self;
}

- (void)startDownload
{
    //load window and show as sheet
    [NSBundle.mainBundle loadNibNamed:@"BlocklistStatusWindow" owner:self topLevelObjects:NULL];

    BlocklistDownloader* downloader = [BlocklistDownloader downloader];
    [downloader setViewController:self]; //do before showing the sheet to ensure it doesn't slide out with placeholder text

    [fPrefsController.window beginSheet:fStatusWindow completionHandler:nil];
}

@end
