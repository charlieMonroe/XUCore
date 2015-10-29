//
//  XUBlockThreading.h
//  DownieCore
//
//  Created by Charlie Monroe on 8/31/14.
//  Copyright (c) 2014 Charlie Monroe Software. All rights reserved.
//

#ifndef DownieCore_XUBlockThreading_h
#define DownieCore_XUBlockThreading_h

#define XU_PERFORM_BLOCK_ON_MAIN_THREAD(block) {\
	if ([NSThread isMainThread]){\
		block();\
	}else{\
		dispatch_sync(dispatch_get_main_queue(), block);\
	}\
}

#define XU_PERFORM_BLOCK_ON_MAIN_THREAD_ASYNC(block) {\
	if ([NSThread isMainThread]){\
		block();\
	}else{\
		dispatch_async(dispatch_get_main_queue(), block);\
	}\
}

#endif
