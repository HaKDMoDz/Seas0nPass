//
//  FWBundle.m
//  tetherKit
//
//  Created by Kevin Bradley on 1/14/11.
//  Copyright 2011 FireCore, LLC. All rights reserved.
//

#import "FWBundle.h"
#import "nitoUtility.h"


@implementation FWBundle

@synthesize fwRoot;

+ (FWBundle *)bundleWithName:(NSString *)bundleName
{
	
	NSString *thePath = [[NSBundle mainBundle] pathForResource:bundleName ofType:@"bundle" inDirectory:@"bundles"];
	if (![FM fileExistsAtPath:thePath])
		return nil;
	FWBundle *theBundle = [[FWBundle alloc] initWithPath:thePath];
	theBundle.fwRoot = TMP_ROOT;
	return [theBundle autorelease];
}

+ (FWBundle *)bundleForFile:(NSString *)theFile
{
	NSString *filename = [[theFile lastPathComponent] stringByDeletingPathExtension];
	NSArray *filenameSplit = [filename componentsSeparatedByString:@"_Restore"];
	NSString *newName = [filenameSplit objectAtIndex:0];
		//NSLog(@"checking for: %@", newName);
	FWBundle *theBundle = [FWBundle bundleWithName:newName];
		//NSLog(@"theBundle: %@", theBundle);
	return theBundle;
}

/*
 
 BuildIdentities - > object at index 0 - > Manifest  (dict) - > KernelCache
 BuildIdentities - > object at index 0 - > Manifest  (dict) - > iBSS
 
 */

	//DownloadUrl

- (NSString *)downloadURL
{
	NSString *url = [[self infoDictionary] valueForKey:DOWNLOAD_URL];
	if ([url length] > 1)
		return url;
	
	return nil;
}

- (NSString *)SHA
{
	return [[self infoDictionary] valueForKey:SHA_ONE];
}

- (NSDictionary *)buildManifest
{
	NSArray *buildIdentities = [[self fwDictionary] objectForKey:@"BuildIdentities"];
	NSDictionary *one = [buildIdentities lastObject];
	return [one valueForKey:@"Manifest"];
	
}

- (NSString *)kernelCacheName
{
	return [[[[self buildManifest] valueForKey:@"KernelCache"] valueForKey:@"Info"] valueForKey:@"Path"];
}

- (NSString *)iBSSName
{
	return [[[[self buildManifest] valueForKey:@"iBSS"] valueForKey:@"Info"] valueForKey:@"Path"];
}


- (NSString *)iBECName
{
	return [[[[self buildManifest] valueForKey:@"iBEC"] valueForKey:@"Info"] valueForKey:@"Path"];
}


- (NSDictionary *)fwDictionary
{
	NSString *buildM = [TMP_ROOT stringByAppendingPathComponent:@"BuildManifest.plist"];
	if ([FM fileExistsAtPath:buildM])
	{
		return [NSDictionary dictionaryWithContentsOfFile:buildM];
		
	} else {
		buildM = [IPSW_TMP stringByAppendingPathComponent:@"BuildManifest.plist"];
		if ([FM fileExistsAtPath:buildM])
		{
			return [NSDictionary dictionaryWithContentsOfFile:buildM];
			
		}
	}
	return nil;
}

- (NSString *)localBundlePath
{
	return [[nitoUtility applicationSupportFolder] stringByAppendingPathComponent:[[self bundleName] stringByAppendingPathExtension:@"bundle"]];
}

- (NSDictionary *)localManifest
{
	NSString *bundlePath = [self localBundlePath];
	NSString *bm = [bundlePath stringByAppendingPathComponent:@"BuildManifest.plist"];
	if ([FM fileExistsAtPath:bm])
	{
		return [NSDictionary dictionaryWithContentsOfFile:bm];
		
	}
	return nil;
}

- (NSString *)localiBSS
{
	if ([self localManifest] != nil)
	{
		return [[self localBundlePath] stringByAppendingPathComponent:[[self localManifest] valueForKey:@"iBSS"]];
	}
	return nil;
}

- (NSString *)localiBEC
{
	if ([self localManifest] != nil)
	{
		return [[self localBundlePath] stringByAppendingPathComponent:[[self localManifest] valueForKey:@"iBEC"]];
	}
	return nil;
}

- (NSString *)localKernel
{
	if ([self localManifest] != nil)
	{
		return [[self localBundlePath] stringByAppendingPathComponent:[[self localManifest] valueForKey:@"KernelCache"]];
	}
	return nil;
}

- (NSString *)oldOutputFile
{
	return [NSHomeDirectory() stringByAppendingPathComponent:self.outputName];
}

- (NSString *)outputFile
{
	NSString *newOutputFile = [[nitoUtility firmwareFolder] stringByAppendingPathComponent:self.outputName];
	NSString *oldOutputFile = [self oldOutputFile];
	NSFileManager *man = [NSFileManager defaultManager];
	if ([man fileExistsAtPath:oldOutputFile])
	{
		if (![man fileExistsAtPath:newOutputFile]) //we have the file in the old location, but not the new. migrate that shit!!
		{
			if ([man moveItemAtPath:oldOutputFile toPath:newOutputFile error:nil])
			{
				NSLog(@"migrated: %@ to proper location, returning now!", self.outputName);
				return newOutputFile;
			} else {
				NSLog(@"failed to migrate the file, but we still have the old one, so return it anyways");
				return oldOutputFile;
			}
		}
	}

		//if we got this far, we dont have teh old deprecated file, but we are still not sure if we have hte new proper location either.
	
	if ([man fileExistsAtPath:newOutputFile])
		return newOutputFile;
	
	return nil; //we got nothing!!!
	
}

- (NSString *)outputName
{
	return [[self bundleName] stringByAppendingString:@"_SP_Restore.ipsw"];
}

- (NSString *)oldramdiskSize
{
	if ([[self bundleName] isEqualToString:@"AppleTV2,1_4.3_8F5148c"])
	{
		return @"24676576";
	} else if ([[self bundleName] isEqualToString:@"AppleTV2,1_4.3_8F5153d"]){
		return @"24676576";
	} else if ([[self bundleName] isEqualToString:@"AppleTV2,1_4.3_8F5166b"]) {
		return @"24676576";
	} else {
		return @"16541920";	
	}
}
	//26067520
- (NSString *)ramdiskSize
{
	if ([self is4point3])
	{//23529796
		return @"26067520";
	} else {
		return @"16541920";	
	}
}

- (BOOL)untethered
{
	if ([self is4point4])
		return NO;
	
//    if ([self is8F455])
//        return NO;
    
	return YES;
		//make this smarter later, for now this will do
}


- (NSString *)deviceType
{
	NSString *firstLetter = [[self bundleName] substringToIndex:1];
	if ([firstLetter isEqualToString:@"i"]) //ipad or iphone oops forgot ipod dummy!! ;-P
	{
		NSString *clippedPath = [[self bundleName] substringToIndex:5];
		if ([clippedPath isEqualToString:@"iPhone"])
		{
			return clippedPath;
			
		} else {
			 
			return [[self bundleName] substringToIndex:3]; //since iPod/iPad are both 4 letters this should return either one.
		}

	}
	
	return @"AppleTV";
	
		//iPhone 5
		//iPad 5
		//AppleTV 7 
}

- (int)deviceInt
{
	if ([[self deviceType] isEqualToString:@"iPhone"])
	{
		return kiPhoneDevice;
		
	} else if ([[self deviceType] isEqualToString:@"iPad"]){
		
		return kiPadDevice;
	
	} else if ([[self deviceType] isEqualToString:@"AppleTV"]) {
		
		return kAppleTVDevice;
		
	} else if ([[self deviceType] isEqualToString:@"iPod"]) {
		
		return kiPodDevice;
		
	}
	
	return kUnknownDevice;
}

- (NSString *)buildVersion
{
	NSString *name = [self bundleName];
	NSArray *objects = [name componentsSeparatedByString:@"_"];
	return [objects lastObject];
}

- (BOOL)is50B7
{
	
	if ([[self buildVersion] isEqualToString:@"9A334"])
		return YES;
	
	if ([[self buildVersion] isEqualToString:@"9A5313e"])
		return YES;
	
	return NO;
}

- (BOOL)is8F455
{
    if ([[self bundleName] isEqualToString:@"AppleTV2,1_4.3_8F455"])
    {
        return YES;
    }
    return NO;
}


- (BOOL)is4point4
{
	NSString *comparisonVersion = @"4.4"; //yes pandering to appletv2, what of it? ;-P
	
	NSString *clippedPath = nil;
	int deviceInteger = [self deviceInt];
	
	switch (deviceInteger) {
			
			
		case kAppleTVDevice:
			
			clippedPath = [[self bundleName] substringWithRange:NSMakeRange(11, 3)];
			break;
			
		case kiPadDevice:
		case kiPodDevice:
				//iPad1,1_4.3.1_8G4_Restore.ipsw
			clippedPath = [[self bundleName] substringWithRange:NSMakeRange(8, 3)];
			comparisonVersion = @"5.0";
			break;
			
		case kiPhoneDevice:
			
			clippedPath = [[self bundleName] substringWithRange:NSMakeRange(10, 3)];
			comparisonVersion = @"5.0";
			break;
			
	}
	
	NSComparisonResult theResult = [clippedPath compare:comparisonVersion options:NSNumericSearch];
		//NSLog(@"theversion: %@  installed version %@", theVersion, installedVersion);
	if ( theResult == NSOrderedDescending )
	{
	//	NSLog(@"%@ is greater than %@", clippedPath, @"4.4");
		
		return YES;
		
	} else if ( theResult == NSOrderedAscending ){
		
	//	NSLog(@"%@ is greater than %@", @"4.4", clippedPath);
		return NO;
		
	} else if ( theResult == NSOrderedSame ) {
		
	//	NSLog(@"%@ is equal to %@", clippedPath, @"4.4");
		return YES;
	}
	
	return NO;
}

- (BOOL)is4point3
{
	NSString *clippedPath = nil;
	int deviceInteger = [self deviceInt];
	
	switch (deviceInteger) {
	
		
		case kAppleTVDevice:
		
			clippedPath = [[self bundleName] substringWithRange:NSMakeRange(11, 3)];
			break;
	
		case kiPadDevice:
				//iPad1,1_4.3.1_8G4_Restore.ipsw
			clippedPath = [[self bundleName] substringWithRange:NSMakeRange(8, 3)];
			break;
	
		case kiPhoneDevice:
			
			clippedPath = [[self bundleName] substringWithRange:NSMakeRange(10, 3)];
			
			break;
		
	}

	NSComparisonResult theResult = [clippedPath compare:@"4.3" options:NSNumericSearch];
		//NSLog(@"theversion: %@  installed version %@", theVersion, installedVersion);
	if ( theResult == NSOrderedDescending )
	{
				//NSLog(@"%@ is greater than %@", clippedPath, @"4.3");
		
		return YES;
		
	} else if ( theResult == NSOrderedAscending ){
		
		//NSLog(@"%@ is greater than %@", @"4.3", clippedPath);
		return NO;
		
	} else if ( theResult == NSOrderedSame ) {
		
	//	NSLog(@"%@ is equal to %@", clippedPath, @"4.3");
		return YES;
	}
	
	return NO;
}


- (BOOL)is4point3old
{
	NSString *clippedPath = [[self bundleName] substringToIndex:14];
	if ([clippedPath isEqualToString:@"AppleTV2,1_4.3"])
	{
		return YES;
	} else {
		return NO;
	}
	return NO;
}

- (NSDictionary *)extraPatch
{
	if ([self is4point3])
	{
		NSDictionary *thePatch = [NSDictionary dictionaryWithObjectsAndKeys:[[NSBundle mainBundle] pathForResource:@"status" ofType:@"patch" inDirectory:@"patches"], @"Patch", @"private/var/lib/dpkg/status", @"Target", @"7945d79f0dad7c3397b930877ba92ec4", @"md5", nil];
			//NSLog(@"extraPatch: %@", thePatch);
		return thePatch;					  
	}
	return nil;
}

- (NSDictionary *)oldextraPatch
{
	
	NSString *clippedPath = [[self bundleName] substringToIndex:14];
	NSLog(@"clippedPath: %@", clippedPath);
	
	if ([[self bundleName] isEqualToString:@"AppleTV2,1_4.3_8F5166b"])
	{
		NSDictionary *thePatch = [NSDictionary dictionaryWithObjectsAndKeys:[[NSBundle mainBundle] pathForResource:@"status" ofType:@"patch" inDirectory:@"patches"], @"Patch", @"private/var/lib/dpkg/status", @"Target", @"7945d79f0dad7c3397b930877ba92ec4", @"md5", nil];
			//NSLog(@"extraPatch: %@", thePatch);
		return thePatch;					  
	}
	
	if ([[self bundleName] isEqualToString:@"AppleTV2,1_4.3_8F5148c"])
	{
		NSDictionary *thePatch = [NSDictionary dictionaryWithObjectsAndKeys:[[NSBundle mainBundle] pathForResource:@"status" ofType:@"patch" inDirectory:@"patches"], @"Patch", @"private/var/lib/dpkg/status", @"Target", @"7945d79f0dad7c3397b930877ba92ec4", @"md5", nil];
			//NSLog(@"extraPatch: %@", thePatch);
		return thePatch;					  
	}
	
	if ([[self bundleName] isEqualToString:@"AppleTV2,1_4.3_8F5153d"])
	{
		NSDictionary *thePatch = [NSDictionary dictionaryWithObjectsAndKeys:[[NSBundle mainBundle] pathForResource:@"status" ofType:@"patch" inDirectory:@"patches"], @"Patch", @"private/var/lib/dpkg/status", @"Target", @"7945d79f0dad7c3397b930877ba92ec4", @"md5", nil];
			//NSLog(@"extraPatch: %@", thePatch);
		return thePatch;					  
	}
	
	return nil;
}

- (NSDictionary *)coreFilesInstallation
{
	return [[self filesystemPatches] valueForKey:CORE_FILES];
}

- (NSString *)restoreRamdiskVolume
{
	return [[self infoDictionary] valueForKey:MOUNTED_RAMDISK];
}

- (void)logDescription
{
	NSLog(@"filename: %@", [self filename]);
	NSLog(@"iBSS: %@", [self iBSS]);
	NSLog(@"Restore Ramdisk: %@", [self restoreRamdisk]);
	NSLog(@"Update Ramdisk: %@", [self updateRamdisk]);
	NSLog(@"RootFilesystem: %@", [self rootFilesystem]);
	NSLog(@"Filesystem Patches: %@", [self filesystemPatches]);
	NSLog(@"bundlePath: %@", [self bundlePath]);
	NSLog(@"fwRoot: %@", [self fwRoot]);
	NSLog(@"bundleName: %@", [self bundleName]);
	NSLog(@"kernelCache: %@", [self kernelCacheName]);
	NSLog(@"iBSS: %@", [self iBSSName]);
	NSLog(@"AppleLogo: %@", [self appleLogo]);
}

- (NSString *)bundleName
{
	return [[self infoDictionary] valueForKey:@"Name"];
}

- (NSString *)filesystemSize
{
		//RootFilesystemSize
	return [[self infoDictionary] valueForKey:@"RootFilesystemSize"];
	
}

- (NSString *)restoreRamdiskFile
{
	return [[self restoreRamdisk] valueForKey:@"File"];
}

- (NSString *)updateRamdiskFile
{
	return [[self updateRamdisk] valueForKey:@"File"];
}

- (NSDictionary *)restoreRamdisk;
{
	return [[self firmwarePatches] valueForKey:RESTORE_RD];
}

- (NSDictionary *)updateRamdisk
{
	
	return [[self firmwarePatches] valueForKey:UPDATE_RD];
}

- (NSDictionary *)iBEC
{
	return [[self firmwarePatches] valueForKey:@"iBEC"];
}

- (NSDictionary *)iBSS
{
	return [[self firmwarePatches] valueForKey:@"iBSS"];
}

- (NSDictionary *)appleLogo
{
	return [[self firmwarePatches] valueForKey:@"AppleLogo"];
}

- (NSDictionary *)kernelcache
{
	return [[self firmwarePatches] valueForKey:@"kernelcache"];
}

- (NSDictionary *)sbkernel
{
    return [[self supportBundlePatches] valueForKey:@"kernelcache"];
}

- (NSString *)rootFilesystem
{
	return [[self infoDictionary] valueForKey:ROOT_FS];
}

- (NSString *)filesystemKey
{
	return [[self infoDictionary] valueForKey:FS_KEY];
}

- (NSString *)filename
{
	return [[self infoDictionary] valueForKey:FILE_NAME];
}

- (NSDictionary *)filesystemPatches
{
	return [[self infoDictionary] valueForKey:FS_PATCHES];
}

- (NSArray *)filesystemJailbreak
{
	return [[self filesystemPatches] valueForKey:FS_JB];
}

- (NSDictionary *)firmwarePatches
{
	return [[self infoDictionary] valueForKey:FW_PATCHES];
	
}

- (NSDictionary *)supportBundlePatches
{
    return [[self infoDictionary] valueForKey:SB_PATCHES];
    
}

- (NSDictionary *)ramdiskPatches
{
	return [[self infoDictionary] valueForKey:RD_PATCHES];
}

- (NSDictionary *)preInstalledPackages
{
	return [[self infoDictionary] valueForKey:PREINST_PACKAGES];
}

- (void)dealloc
{
	[fwRoot release];
	fwRoot = nil;
	[super dealloc];
}

@end
