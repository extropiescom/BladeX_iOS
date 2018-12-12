//
//  Test_C_EWallet_ViewController.m
//  TestCompileDemo
//
//  Created by 周权威 on 2018/8/15.
//  Copyright © 2018年 extropies. All rights reserved.
//

#import "Test_C_EWallet_ViewController.h"
#import "PA_EWallet/iOS_EWalletDynamic.framework/Headers/PA_EWallet.h"
#import "ToolInputView.h"
#import "PickerViewAlert.h"
#import "TextFieldViewAlert.h"
#import "Utils.h"

@interface Test_C_EWallet_ViewController ()
{
    NSInteger logCounter;
    int lastSignState;
    int lastButtonState;
    BOOL authTypeCached;
    unsigned char nAuthType;
    int authTypeResult;
    BOOL pinCached;
    NSString *pin;
    int pinResult;
    size_t imageCount;
    int updateProgress;
}

@property (nonatomic, strong) UITextView *in_outTextView;

@property (nonatomic, strong) UIButton *getDevInfoBtn;

@property (nonatomic, strong) UIButton *initiPinBtn;

@property (nonatomic, strong) UIButton *verifyPinBtn;

@property (nonatomic, strong) UIButton *changePinBtn;

@property (nonatomic, strong) UIButton *updateCOSBtn;

@property (nonatomic, strong) UIButton *getBatteryStateBtn;

@property (nonatomic, strong) UIButton *getFWVersionBtn;

@property (nonatomic, strong) UIButton *getFPListBtn;

@property (nonatomic, strong) UIButton *enrollFPBtn;

@property (nonatomic, strong) UIButton *verifyFPBtn;

@property (nonatomic, strong) UIButton *deleteFPBtn;

@property (nonatomic, strong) UIButton *formatBtn;

@property (nonatomic, strong) UIButton *genSeedBtn;

@property (nonatomic, strong) UIButton *ETHSignBtn;

@property (nonatomic, strong) UIButton *EOSSignBtn;

@property (nonatomic, strong) UIButton *CYBSignBtn;

@property (nonatomic, strong) UIButton *ETHSignNewBtn;

@property (nonatomic, strong) UIButton *EOSSignNewBtn;

@property (nonatomic, strong) UIButton *CYBSignNewBtn;

@property (nonatomic, strong) UIButton *SwitchSignBtn;

@property (nonatomic, strong) UIButton *importMNEBtn;

@property (nonatomic, strong) UIButton *recoverSeedBtn;

@property (nonatomic, strong) UIButton *getAddressBtn;

@property (nonatomic, strong) UIButton *getDeviceCheckCodeBtn;

@property (nonatomic, strong) UIButton *freeContextBtn;

@property (nonatomic, strong) UIButton *calibrateFPBtn;

@property (nonatomic, strong) UIButton *abortBtn;
@property (nonatomic, strong) UIButton *abortButton1Btn;
@property (nonatomic, strong) UIButton *abortButton2Btn;
@property (nonatomic, strong) UIButton *signAbortBtn;


@property (nonatomic, strong) UIButton *clearLogBtn;

@property (nonatomic, strong) UIButton *clearScreenBtn;
@property (nonatomic, strong) UIButton *powerOffBtn;
@property (nonatomic, strong) UIButton *writeSNBtn;

@property (nonatomic, strong) UIButton *setImageDataBtn;
@property (nonatomic, strong) UIButton *showImageBtn;
@property (nonatomic, strong) UIButton *setLogoImageBtn;
@property (nonatomic, strong) UIButton *getImageListBtn;
@property (nonatomic, strong) UIButton *setImageNameBtn;
@property (nonatomic, strong) UIButton *getImageNameBtn;

@property (nonatomic, strong) UIButton *deviceCategoryBtn;
@property (nonatomic, strong) UIButton *fPrintCategoryBtn;
@property (nonatomic, strong) UIButton *InitCategoryBtn;
@property (nonatomic, strong) UIButton *walletCategoryBtn;
@property (nonatomic, strong) UIButton *imageCategoryBtn;

@property (nonatomic, strong) NSArray *deviceCategoryList;
@property (nonatomic, strong) NSArray *fPrintCategoryList;
@property (nonatomic, strong) NSArray *InitCategoryList;
@property (nonatomic, strong) NSArray *walletCategoryList;
@property (nonatomic, strong) NSArray *imageCategoryList;
@property (nonatomic, strong) NSArray *categoryList;
@property (nonatomic, strong) NSArray *allList;

@property (nonatomic,strong)ToolInputView *inputView;

@property (nonatomic, assign) BOOL abortBtnState;

@property (nonatomic, assign) BOOL switchSignFlag;
@property (nonatomic, assign) BOOL abortSignFlag;
@property (nonatomic, assign) BOOL abortButtonFlag;

@property (nonatomic, strong) NSCondition *abortCondition;

@property (nonatomic, copy) void(^abortHandelBlock)(BOOL abortState);

@end

@implementation Test_C_EWallet_ViewController

static Test_C_EWallet_ViewController *selfClass =nil;


#pragma mark-- C callback for ETH/EOS sign method

const uint32_t puiDerivePathETH[] = {0, 0x8000002c, 0x8000003c, 0x80000000, 0x00000000, 0x00000000};
const uint32_t puiDerivePathEOS[] = {0, 0x8000002C, 0x800000c2, 0x80000000, 0x00000000, 0x00000000};
const uint32_t puiDerivePathCYB[] = {0, 0, 1, 0x00000080, 0x00000000, 0x00000000};

int GetAuthType(void * const pCallbackContext, unsigned char * const pnAuthType)
{
    int rtn = 0;
    if (!selfClass->authTypeCached) {
        [selfClass getAuthType];
    }
    rtn = selfClass->authTypeResult;
    if (rtn == PAEW_RET_SUCCESS) {
        *pnAuthType = selfClass->nAuthType;
    }
    selfClass->authTypeCached = NO;
    return rtn;
}

int GetPin(void * const pCallbackContext, unsigned char * const pbPIN, size_t * const pnPINLen)
{
    int rtn = 0;
    if (!selfClass->pinCached) {
        [selfClass getPIN];
    }
    rtn = selfClass->pinResult;
    if (rtn == PAEW_RET_SUCCESS) {
        *pnPINLen = selfClass->pin.length;
        strcpy((char *)pbPIN, [selfClass->pin UTF8String]);
    }
    selfClass->pinCached = NO;
    return rtn;
}

int PutSignState(void * const pCallbackContext, const int nSignState)
{
    //It is a normal phenomenon that nSignState may equals dev_state_invalid after PAEW_AbortSign was called successfully
    //So at this time, PAEW_XXX_TXSign will also returs dev_state_invalid
    //as this is a deprecated callback and being kept for only compatible reason
    //we will NOT fix it any more
    if (nSignState != selfClass->lastSignState) {
        [selfClass printLog:[Utils errorCodeToString:nSignState]];
        selfClass->lastSignState = nSignState;
    }
    //here is a good place to canel sign function
    if (selfClass.abortSignFlag) {
        [selfClass.abortCondition lock];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            int devIdx = 0;
            uint64_t temp = selfClass.savedDevice;
            void *ppPAEWContext = (void*)temp;
            int iRtn = PAEW_RET_UNKNOWN_FAIL;
            
            selfClass.abortSignFlag = NO;
            [selfClass printLog:@"ready to call PAEW_AbortSign"];
            [selfClass.abortCondition lock];
            iRtn = PAEW_AbortSign(ppPAEWContext, devIdx);
            [selfClass.abortCondition signal];
            [selfClass.abortCondition unlock];
            
            if (iRtn != PAEW_RET_SUCCESS) {
                [selfClass printLog:@"PAEW_AbortSign returns failed %@", [Utils errorCodeToString:iRtn]];
                return ;
            }
            
            [selfClass printLog:@"PAEW_AbortSign returns success"];
        });
        [selfClass.abortCondition wait];
        [selfClass.abortCondition unlock];
        selfClass.abortBtnState = NO;
    }
    return 0;
}

int UpdateCOSProgressCallback(void * const pCallbackContext, const size_t nProgress)
{
    [selfClass printLog:@"current update progress is %zu%%", nProgress];
    return PAEW_RET_SUCCESS;
}

int PutState_Callback(void * const pCallbackContext, const int nState)
{
    if (nState != selfClass->lastButtonState) {
        [selfClass printLog:[Utils errorCodeToString:nState]];
        selfClass->lastButtonState = nState;
    }
    //here is a good place to canel sign function
    if (selfClass.abortButtonFlag) {
        [selfClass.abortCondition lock];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            int devIdx = 0;
            uint64_t temp = selfClass.savedDevice;
            void *ppPAEWContext = (void*)temp;
            int iRtn = PAEW_RET_UNKNOWN_FAIL;
            
            selfClass.abortButtonFlag = NO;
            [selfClass printLog:@"ready to call PAEW_AbortButton"];
            [selfClass.abortCondition lock];
            iRtn = PAEW_AbortButton(ppPAEWContext, devIdx);
            [selfClass.abortCondition signal];
            [selfClass.abortCondition unlock];
            
            if (iRtn != PAEW_RET_SUCCESS) {
                [selfClass printLog:@"PAEW_AbortButton returns failed %@", [Utils errorCodeToString:iRtn]];
                return ;
            }
            
            [selfClass printLog:@"PAEW_AbortButton returns success"];
        });
        [selfClass.abortCondition wait];
        [selfClass.abortCondition unlock];
        selfClass.abortButtonFlag = NO;
    }
    return 0;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.extendedLayoutIncludesOpaqueBars = NO;
    self.modalPresentationCapturesStatusBarAppearance = NO;
    
    [self addSubViewAfterVDLoad];
    
    _deviceCategoryList = [NSArray arrayWithObjects:_getDevInfoBtn, _initiPinBtn, _verifyPinBtn, _changePinBtn, _formatBtn, _clearScreenBtn, _freeContextBtn, _powerOffBtn, _writeSNBtn, _updateCOSBtn, _abortButton1Btn, _getBatteryStateBtn, _getFWVersionBtn, nil];
    _fPrintCategoryList = [NSArray arrayWithObjects:_getFPListBtn, _enrollFPBtn, _verifyFPBtn, _deleteFPBtn, _calibrateFPBtn, _abortBtn, nil];
    _InitCategoryList = [NSArray arrayWithObjects:_genSeedBtn, _importMNEBtn, _recoverSeedBtn, nil];
    _walletCategoryList = [NSArray arrayWithObjects:_getAddressBtn, _getDeviceCheckCodeBtn, _ETHSignBtn, _EOSSignBtn, _CYBSignBtn,_signAbortBtn, _ETHSignNewBtn, _EOSSignNewBtn, _CYBSignNewBtn, _SwitchSignBtn, _abortButton2Btn, nil];
    _imageCategoryList = [NSArray arrayWithObjects:_getImageListBtn, _setImageNameBtn, _getImageNameBtn, _setImageDataBtn, _showImageBtn, _setLogoImageBtn, nil];
    _categoryList = [NSArray arrayWithObjects:_deviceCategoryBtn, _fPrintCategoryBtn, _InitCategoryBtn, _walletCategoryBtn, _imageCategoryBtn, nil];
    _allList = @[self.deviceCategoryList, self.fPrintCategoryList, self.InitCategoryList, self.walletCategoryList, self.imageCategoryList];
    
    [self categoryAction:_deviceCategoryBtn];
    
    self.abortBtnState = NO;
    self->logCounter = 0;
    self->lastSignState = PAEW_RET_SUCCESS;
    self->lastButtonState = PAEW_RET_SUCCESS;
    self->nAuthType = 0xFF;
    selfClass = self;
    self->pinResult = PAEW_RET_SUCCESS;
    self->authTypeResult = PAEW_RET_SUCCESS;
    self->authTypeCached = NO;
    self->pinCached = NO;
    self->imageCount = 0;
}

- (void) showCategory:(NSArray *) categoryList
{
    for (NSArray *item in self.allList) {
        for (UIButton *btn in item) {
            btn.hidden = categoryList == item ? NO : YES;
        }
    }
}

#define LINESPACING 10
#define BUTTONHEIGHT 30
- (void)addSubViewAfterVDLoad
{
    [self.view addSubview:self.in_outTextView];
    [self.in_outTextView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.view.mas_top).offset(10);
        make.left.mas_equalTo(self.view.mas_left).offset(10);
        make.right.mas_equalTo(self.view.mas_right).offset(-10);
        make.height.mas_equalTo(self.view.mas_height).multipliedBy(0.33);
    }];
    self.in_outTextView.layoutManager.allowsNonContiguousLayout = NO;
    
    [self.view addSubview:self.deviceCategoryBtn];
//    [self.deviceCategoryBtn mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.top.mas_equalTo(self.in_outTextView.mas_bottom).offset(20);
//        make.width.mas_equalTo(self.in_outTextView.mas_width).multipliedBy(0.25);
//        make.height.mas_equalTo(30);
//        make.left.mas_equalTo(self.in_outTextView.mas_left);
//    }];
    
    [self.view addSubview:self.fPrintCategoryBtn];
//    [self.fPrintCategoryBtn mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.top.mas_equalTo(self.in_outTextView.mas_bottom).offset(20);
//        make.width.mas_equalTo(self.in_outTextView.mas_width).multipliedBy(0.25);
//        make.height.mas_equalTo(30);
//        make.left.mas_equalTo(self.deviceCategoryBtn.mas_right);
//    }];
    
    [self.view addSubview:self.InitCategoryBtn];
//    [self.InitCategoryBtn mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.top.mas_equalTo(self.in_outTextView.mas_bottom).offset(20);
//        make.width.mas_equalTo(self.in_outTextView.mas_width).multipliedBy(0.25);
//        make.height.mas_equalTo(30);
//        make.left.mas_equalTo(self.fPrintCategoryBtn.mas_right);
//    }];
    
    [self.view addSubview:self.walletCategoryBtn];
    
    [self.view addSubview:self.imageCategoryBtn];
//    [self.walletCategoryBtn mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.top.mas_equalTo(self.in_outTextView.mas_bottom).offset(20);
//        make.width.mas_equalTo(self.in_outTextView.mas_width).multipliedBy(0.25);
//        make.height.mas_equalTo(30);
//        make.left.mas_equalTo(self.InitCategoryBtn.mas_right);
//    }];
    
    NSArray *catArr = @[self.deviceCategoryBtn, self.fPrintCategoryBtn, self.InitCategoryBtn, self.walletCategoryBtn, self.imageCategoryBtn];
    [catArr mas_distributeViewsAlongAxis:MASAxisTypeHorizontal withFixedSpacing:1 leadSpacing:10 tailSpacing:10];
    [catArr mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.in_outTextView.mas_bottom).offset(20);
        make.height.mas_equalTo(30);
    }];
    
    [self.view addSubview:self.getDevInfoBtn];
    [self.view addSubview:self.initiPinBtn];
    [self.view addSubview:self.verifyPinBtn];
    [self.view addSubview:self.changePinBtn];
    [self.view addSubview:self.formatBtn];
    [self.view addSubview:self.clearScreenBtn];
    [self.view addSubview:self.freeContextBtn];
    [self.view addSubview:self.powerOffBtn];
    [self.view addSubview:self.writeSNBtn];
    [self.view addSubview:self.updateCOSBtn];
    [self.view addSubview:self.abortButton1Btn];
    [self.view addSubview:self.getBatteryStateBtn];
    [self.view addSubview:self.getFWVersionBtn];
    
    [self.view addSubview:self.getFPListBtn];
    [self.view addSubview:self.enrollFPBtn];
    [self.view addSubview:self.verifyFPBtn];
    [self.view addSubview:self.deleteFPBtn];
    [self.view addSubview:self.calibrateFPBtn];
    [self.view addSubview:self.abortBtn];
    
    [self.view addSubview:self.genSeedBtn];
    [self.view addSubview:self.importMNEBtn];
    [self.view addSubview:self.recoverSeedBtn];
    
    [self.view addSubview:self.getAddressBtn];
    [self.view addSubview:self.getDeviceCheckCodeBtn];
    [self.view addSubview:self.signAbortBtn];
    [self.view addSubview:self.ETHSignBtn];
    [self.view addSubview:self.EOSSignBtn];
    [self.view addSubview:self.CYBSignBtn];
    [self.view addSubview:self.ETHSignNewBtn];
    [self.view addSubview:self.EOSSignNewBtn];
    [self.view addSubview:self.CYBSignNewBtn];
    [self.view addSubview:self.SwitchSignBtn];
    [self.view addSubview:self.abortButton2Btn];
    
    [self.view addSubview:self.getImageListBtn];
    [self.view addSubview:self.setImageNameBtn];
    [self.view addSubview:self.getImageNameBtn];
    [self.view addSubview:self.setImageDataBtn];
    [self.view addSubview:self.showImageBtn];
    [self.view addSubview:self.setLogoImageBtn];
    
    NSArray *cat1Arr1 = @[self.getDevInfoBtn, self.initiPinBtn, self.verifyPinBtn];
    [cat1Arr1 mas_distributeViewsAlongAxis:MASAxisTypeHorizontal withFixedSpacing:10 leadSpacing:30 tailSpacing:30];
    [cat1Arr1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.deviceCategoryBtn.mas_bottom).offset(LINESPACING);
        make.height.mas_equalTo(30);
    }];
    NSArray *cat1Arr2 = @[self.changePinBtn, self.formatBtn, self.clearScreenBtn];
    [cat1Arr2 mas_distributeViewsAlongAxis:MASAxisTypeHorizontal withFixedSpacing:10 leadSpacing:30 tailSpacing:30];
    [cat1Arr2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.getDevInfoBtn.mas_bottom).offset(LINESPACING);
        make.height.mas_equalTo(30);
    }];
    NSArray *cat1Arr3 = @[self.freeContextBtn, self.powerOffBtn, self.writeSNBtn];
    [cat1Arr3 mas_distributeViewsAlongAxis:MASAxisTypeHorizontal withFixedSpacing:10 leadSpacing:30 tailSpacing:30];
    [cat1Arr3 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.changePinBtn.mas_bottom).offset(LINESPACING);
        make.height.mas_equalTo(30);
    }];
    NSArray *cat1Arr4 = @[self.updateCOSBtn, self.abortButton1Btn, self.getBatteryStateBtn];
    [cat1Arr4 mas_distributeViewsAlongAxis:MASAxisTypeHorizontal withFixedSpacing:10 leadSpacing:30 tailSpacing:30];
    [cat1Arr4 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.freeContextBtn.mas_bottom).offset(LINESPACING);
        make.height.mas_equalTo(30);
    }];
    
    [self.getFWVersionBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.updateCOSBtn.mas_bottom).offset(LINESPACING);
        make.height.mas_equalTo(30);
        make.left.mas_equalTo(self.updateCOSBtn.mas_left);
        make.right.mas_equalTo(self.updateCOSBtn.mas_right);
    }];
    
    NSArray *cat2Arr1 = @[self.getFPListBtn, self.enrollFPBtn, self.verifyFPBtn];
    [cat2Arr1 mas_distributeViewsAlongAxis:MASAxisTypeHorizontal withFixedSpacing:10 leadSpacing:30 tailSpacing:30];
    [cat2Arr1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.deviceCategoryBtn.mas_bottom).offset(LINESPACING);
        make.height.mas_equalTo(30);
    }];
    NSArray *cat2Arr2 = @[self.deleteFPBtn, self.calibrateFPBtn, self.abortBtn];
    [cat2Arr2 mas_distributeViewsAlongAxis:MASAxisTypeHorizontal withFixedSpacing:10 leadSpacing:30 tailSpacing:30];
    [cat2Arr2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.getDevInfoBtn.mas_bottom).offset(LINESPACING);
        make.height.mas_equalTo(30);
    }];
    
    
    NSArray *cat3Arr1 = @[self.genSeedBtn, self.importMNEBtn, self.recoverSeedBtn];
    [cat3Arr1 mas_distributeViewsAlongAxis:MASAxisTypeHorizontal withFixedSpacing:10 leadSpacing:30 tailSpacing:30];
    [cat3Arr1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.deviceCategoryBtn.mas_bottom).offset(LINESPACING);
        make.height.mas_equalTo(30);
    }];
    
    //        NSArray *cat3Arr2 = @[self.recoverSeedBtn, self.recoverAddressBtn];
    //        [cat3Arr2 mas_distributeViewsAlongAxis:MASAxisTypeHorizontal withFixedSpacing:10 leadSpacing:30 tailSpacing:30];
    //        [cat3Arr2 mas_makeConstraints:^(MASConstraintMaker *make) {
    //            make.top.mas_equalTo(self.getDevInfoBtn.mas_bottom).offset(20);
    //            make.height.mas_equalTo(30);
    //        }];
    
    
    NSArray *cat4Arr1 = @[self.getAddressBtn, self.getDeviceCheckCodeBtn, self.signAbortBtn];
    [cat4Arr1 mas_distributeViewsAlongAxis:MASAxisTypeHorizontal withFixedSpacing:10 leadSpacing:30 tailSpacing:30];
    [cat4Arr1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.deviceCategoryBtn.mas_bottom).offset(LINESPACING);
        make.height.mas_equalTo(30);
    }];
    NSArray *cat4Arr2 = @[self.ETHSignBtn, self.EOSSignBtn, self.CYBSignBtn];
    [cat4Arr2 mas_distributeViewsAlongAxis:MASAxisTypeHorizontal withFixedSpacing:10 leadSpacing:30 tailSpacing:30];
    [cat4Arr2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.getDevInfoBtn.mas_bottom).offset(LINESPACING);
        make.height.mas_equalTo(30);
    }];
    NSArray *cat4Arr3 = @[self.ETHSignNewBtn, self.EOSSignNewBtn, self.CYBSignNewBtn];
    [cat4Arr3 mas_distributeViewsAlongAxis:MASAxisTypeHorizontal withFixedSpacing:10 leadSpacing:30 tailSpacing:30];
    [cat4Arr3 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.ETHSignBtn.mas_bottom).offset(LINESPACING);
        make.height.mas_equalTo(30);
    }];
    NSArray *cat4Arr4 = @[self.SwitchSignBtn, self.abortButton2Btn];
    [cat4Arr4 mas_distributeViewsAlongAxis:MASAxisTypeHorizontal withFixedSpacing:10 leadSpacing:30 tailSpacing:30];
    [cat4Arr4 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.ETHSignNewBtn.mas_bottom).offset(LINESPACING);
        make.height.mas_equalTo(30);
    }];
    
    NSArray *cat5Arr1 = @[self.getImageListBtn, self.setImageNameBtn, self.getImageNameBtn];
    [cat5Arr1 mas_distributeViewsAlongAxis:MASAxisTypeHorizontal withFixedSpacing:10 leadSpacing:30 tailSpacing:30];
    [cat5Arr1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.deviceCategoryBtn.mas_bottom).offset(LINESPACING);
        make.height.mas_equalTo(30);
    }];
    NSArray *cat5Arr2 = @[self.setImageDataBtn, self.showImageBtn, self.setLogoImageBtn];
    [cat5Arr2 mas_distributeViewsAlongAxis:MASAxisTypeHorizontal withFixedSpacing:10 leadSpacing:30 tailSpacing:30];
    [cat5Arr2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.getDevInfoBtn.mas_bottom).offset(LINESPACING);
        make.height.mas_equalTo(30);
    }];
    
    
    
    [self.view addSubview:self.clearLogBtn];
    [self.clearLogBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.getFWVersionBtn.mas_bottom).offset(LINESPACING);
        make.left.mas_equalTo(self.initiPinBtn.mas_left);
        make.height.mas_equalTo(30);
        make.right.mas_equalTo(self.initiPinBtn.mas_right);
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidDisappear:(BOOL)animated {
    if (self.savedDevice) {
        [self freeContextBtnAction];
    }
}

- (UIButton *)deviceCategoryBtn
{
    if (!_deviceCategoryBtn) {
        _deviceCategoryBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_deviceCategoryBtn setTitle:@"Device" forState:UIControlStateNormal];
        [_deviceCategoryBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        _deviceCategoryBtn.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium];
        [_deviceCategoryBtn setBackgroundColor:[UIColor lightGrayColor]];
        [_deviceCategoryBtn addTarget:self action:@selector(categoryAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _deviceCategoryBtn;
}

- (UIButton *)fPrintCategoryBtn
{
    if (!_fPrintCategoryBtn) {
        _fPrintCategoryBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_fPrintCategoryBtn setTitle:@"FPrint" forState:UIControlStateNormal];
        [_fPrintCategoryBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        _fPrintCategoryBtn.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium];
        [_fPrintCategoryBtn setBackgroundColor:[UIColor lightGrayColor]];
        [_fPrintCategoryBtn addTarget:self action:@selector(categoryAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _fPrintCategoryBtn;
}

- (UIButton *)InitCategoryBtn
{
    if (!_InitCategoryBtn) {
        _InitCategoryBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_InitCategoryBtn setTitle:@"Init" forState:UIControlStateNormal];
        [_InitCategoryBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        _InitCategoryBtn.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium];
        [_InitCategoryBtn setBackgroundColor:[UIColor lightGrayColor]];
        [_InitCategoryBtn addTarget:self action:@selector(categoryAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _InitCategoryBtn;
}

- (UIButton *)walletCategoryBtn
{
    if (!_walletCategoryBtn) {
        _walletCategoryBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_walletCategoryBtn setTitle:@"Wallet" forState:UIControlStateNormal];
        [_walletCategoryBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        _walletCategoryBtn.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium];
        [_walletCategoryBtn setBackgroundColor:[UIColor lightGrayColor]];
        [_walletCategoryBtn addTarget:self action:@selector(categoryAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _walletCategoryBtn;
}

- (UIButton *)imageCategoryBtn
{
    if (!_imageCategoryBtn) {
        _imageCategoryBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_imageCategoryBtn setTitle:@"Image" forState:UIControlStateNormal];
        [_imageCategoryBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        _imageCategoryBtn.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium];
        [_imageCategoryBtn setBackgroundColor:[UIColor lightGrayColor]];
        [_imageCategoryBtn addTarget:self action:@selector(categoryAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _imageCategoryBtn;
}

- (void)categoryAction:(id)sender
{
    for (UIButton *btn in _categoryList) {
        if (sender == btn) {
            btn.backgroundColor = [UIColor whiteColor];
        } else {
            btn.backgroundColor = [UIColor brownColor];
        }
    }
    if (sender == _deviceCategoryBtn) {
        [self showCategory:_deviceCategoryList];
    } else if (sender == _fPrintCategoryBtn) {
        [self showCategory:_fPrintCategoryList];
    } else if (sender == _InitCategoryBtn) {
        [self showCategory:_InitCategoryList];
    } else if (sender == _walletCategoryBtn) {
        [self showCategory:_walletCategoryList];
    } else if (sender == _imageCategoryBtn) {
        [self showCategory:_imageCategoryList];
    }
}

- (UIButton *)signAbortBtn
{
    if (!_signAbortBtn) {
        _signAbortBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_signAbortBtn setTitle:@"AbortSign" forState:UIControlStateNormal];
        [_signAbortBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        _signAbortBtn.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium];
        [_signAbortBtn setBackgroundColor:[UIColor lightGrayColor]];
        [_signAbortBtn addTarget:self action:@selector(signAbortBtnAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _signAbortBtn;
}

- (UIButton *)abortBtn
{
    if (!_abortBtn) {
        _abortBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_abortBtn setTitle:@"Abort" forState:UIControlStateNormal];
        [_abortBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        _abortBtn.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium];
        [_abortBtn setBackgroundColor:[UIColor lightGrayColor]];
        [_abortBtn addTarget:self action:@selector(abortBtnAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _abortBtn;
}

- (UIButton *)abortButton1Btn
{
    if (!_abortButton1Btn) {
        _abortButton1Btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_abortButton1Btn setTitle:@"AbortButton" forState:UIControlStateNormal];
        [_abortButton1Btn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        _abortButton1Btn.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium];
        [_abortButton1Btn setBackgroundColor:[UIColor lightGrayColor]];
        [_abortButton1Btn addTarget:self action:@selector(abortButtonBtnAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _abortButton1Btn;
}

- (UIButton *)abortButton2Btn
{
    if (!_abortButton2Btn) {
        _abortButton2Btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_abortButton2Btn setTitle:@"AbortButton" forState:UIControlStateNormal];
        [_abortButton2Btn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        _abortButton2Btn.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium];
        [_abortButton2Btn setBackgroundColor:[UIColor lightGrayColor]];
        [_abortButton2Btn addTarget:self action:@selector(abortButtonBtnAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _abortButton2Btn;
}

- (void) abortButtonBtnAction
{
    self.abortButtonFlag = YES;
}

- (UIButton *)clearLogBtn
{
    if (!_clearLogBtn) {
        _clearLogBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_clearLogBtn setTitle:@"ClearLog" forState:UIControlStateNormal];
        [_clearLogBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        _clearLogBtn.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium];
        [_clearLogBtn setBackgroundColor:[UIColor lightGrayColor]];
        [_clearLogBtn addTarget:self action:@selector(clearLogBtnAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _clearLogBtn;
}

- (UIButton *)clearScreenBtn
{
    if (!_clearScreenBtn) {
        _clearScreenBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_clearScreenBtn setTitle:@"ClearScreen" forState:UIControlStateNormal];
        [_clearScreenBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        _clearScreenBtn.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium];
        [_clearScreenBtn setBackgroundColor:[UIColor lightGrayColor]];
        [_clearScreenBtn addTarget:self action:@selector(clearScreenBtnAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _clearScreenBtn;
}

- (UIButton *)powerOffBtn
{
    if (!_powerOffBtn) {
        _powerOffBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_powerOffBtn setTitle:@"PowerOff" forState:UIControlStateNormal];
        [_powerOffBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        _powerOffBtn.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium];
        [_powerOffBtn setBackgroundColor:[UIColor lightGrayColor]];
        [_powerOffBtn addTarget:self action:@selector(powerOffBtnAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _powerOffBtn;
}

- (UIButton *)writeSNBtn
{
    if (!_writeSNBtn) {
        _writeSNBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_writeSNBtn setTitle:@"WriteSN" forState:UIControlStateNormal];
        [_writeSNBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        _writeSNBtn.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium];
        [_writeSNBtn setBackgroundColor:[UIColor lightGrayColor]];
        [_writeSNBtn addTarget:self action:@selector(writeSNBtnAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _writeSNBtn;
}

- (UIButton *)getImageListBtn
{
    if (!_getImageListBtn) {
        _getImageListBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_getImageListBtn setTitle:@"GetList" forState:UIControlStateNormal];
        [_getImageListBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        _getImageListBtn.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium];
        [_getImageListBtn setBackgroundColor:[UIColor lightGrayColor]];
        [_getImageListBtn addTarget:self action:@selector(getImageListBtnAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _getImageListBtn;
}

- (void)getImageListBtnAction
{
    [self printLog:@"ready to call PAEW_GetImageList"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int devIdx = 0;
        void *ppPAEWContext = (void*)self.savedDevice;
        int iRtn = PAEW_RET_UNKNOWN_FAIL;
        size_t nImageCount = 0;
        iRtn = PAEW_GetImageList(ppPAEWContext, devIdx, NULL, &nImageCount);
        if (iRtn != PAEW_RET_SUCCESS) {
            [self printLog:@"PAEW_GetImageList returns failed: %@", [Utils errorCodeToString:iRtn]];
        } else {
            self->imageCount = nImageCount;
            [self printLog:@"PAEW_GetImageList returns success, imageCount is: %d", nImageCount];
        }
        
    });
}

- (UIButton *)setImageNameBtn
{
    if (!_setImageNameBtn) {
        _setImageNameBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_setImageNameBtn setTitle:@"SetName" forState:UIControlStateNormal];
        [_setImageNameBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        _setImageNameBtn.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium];
        [_setImageNameBtn setBackgroundColor:[UIColor lightGrayColor]];
        [_setImageNameBtn addTarget:self action:@selector(setImageNameBtnAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _setImageNameBtn;
}

- (void)setImageNameBtnAction
{
    if (self->imageCount <= 0) {
        [self printLog:@"invalid image count, please call GetImageList first!"];
        return;
    }
    NSMutableArray *arr = [NSMutableArray new];
    for (int i = 0; i < imageCount; i++) {
        [arr addObject:[NSString stringWithFormat:@"%zu", i]];
    }
    int index = [PickerViewAlert doModal:self title:@"please select image index:" dataSouce:arr];
    if (index < 0) {
        return;
    }
    self->_inputView =[ToolInputView toolInputViewWithCallback:^(NSString *name) {
        self->_inputView = nil;
        if (name.length == 0 || name.length > PAEW_IMAGE_NAME_MAX_LEN) {
            [self printLog:@"invalid image name length, valid name length is between 0 and %d", PAEW_IMAGE_NAME_MAX_LEN];
            return;
        }
        name = [name stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
        [self printLog:@"ready to call PAEW_SetImageName"];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            int devIdx = 0;
            void *ppPAEWContext = (void*)self.savedDevice;
            int iRtn = PAEW_SetImageName(ppPAEWContext, devIdx, index, [name UTF8String], name.length);
            if (iRtn != PAEW_RET_SUCCESS) {
                [self printLog:@"PAEW_SetImageName returns failed: %@", [Utils errorCodeToString:iRtn]];
                return;
            }
            [self printLog:@"PAEW_SetImageName returns success, set image name to '%@' at index %d", name, index];
        });
        
    }];
    
    
    /*[self printLog:@"ready to call PAEW_GetImageList"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int devIdx = 0;
        void *ppPAEWContext = (void*)self.savedDevice;
        int iRtn = PAEW_RET_UNKNOWN_FAIL;
        size_t nImageCount = 0;
        iRtn = PAEW_SetImageName(ppPAEWContext, devIdx, <#const unsigned char nImageIndex#>, <#const unsigned char *const pbImageName#>, <#const size_t nImageNameLen#>)
        if (iRtn != PAEW_RET_SUCCESS) {
            [self printLog:@"PAEW_GetImageList returns failed: %@", [Utils errorCodeToString:iRtn]];
        } else {
            self->imageCount = nImageCount;
            [self printLog:@"PAEW_GetImageList returns success, imageCount is: %d", nImageCount];
        }
        
    });*/
}

- (UIButton *)getImageNameBtn
{
    if (!_getImageNameBtn) {
        _getImageNameBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_getImageNameBtn setTitle:@"GetName" forState:UIControlStateNormal];
        [_getImageNameBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        _getImageNameBtn.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium];
        [_getImageNameBtn setBackgroundColor:[UIColor lightGrayColor]];
        [_getImageNameBtn addTarget:self action:@selector(getImageNameBtnAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _getImageNameBtn;
}

- (void)getImageNameBtnAction
{
    if (self->imageCount <= 0) {
        [self printLog:@"invalid image count, please call GetImageList first!"];
        return;
    }
    NSMutableArray *arr = [NSMutableArray new];
    for (int i = 0; i < imageCount; i++) {
        [arr addObject:[NSString stringWithFormat:@"%d", i]];
    }
    int index = [PickerViewAlert doModal:self title:@"please select image index:" dataSouce:arr];
    if (index < 0) {
        return;
    }
    [self printLog:@"ready to call PAEW_GetImageName"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int devIdx = 0;
        void *ppPAEWContext = (void*)self.savedDevice;
        unsigned char bImageName[PAEW_IMAGE_NAME_MAX_LEN] = {0};
        size_t nImageNameLen = PAEW_IMAGE_NAME_MAX_LEN;
        int iRtn = PAEW_GetImageName(ppPAEWContext, devIdx, index, bImageName, &nImageNameLen);
        if (iRtn != PAEW_RET_SUCCESS) {
            [self printLog:@"PAEW_GetImageName returns failed: %@", [Utils errorCodeToString:iRtn]];
            return;
        }
        NSString *name = [NSString stringWithUTF8String:bImageName];
        [self printLog:@"PAEW_GetImageName returns success, image name at index %d is '%@' ", index, name];
    });
}

- (UIButton *)setImageDataBtn
{
    if (!_setImageDataBtn) {
        _setImageDataBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_setImageDataBtn setTitle:@"SetData" forState:UIControlStateNormal];
        [_setImageDataBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        _setImageDataBtn.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium];
        [_setImageDataBtn setBackgroundColor:[UIColor lightGrayColor]];
        [_setImageDataBtn addTarget:self action:@selector(setImageDataBtnAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _setImageDataBtn;
}

- (void)setImageDataBtnAction
{
#define byte Byte
    byte imageData[][1024] = {
        {(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xE0,(byte)0x03,(byte)0xFF,(byte)0x0F,(byte)0xFF,(byte)0xC1,(byte)0xFC,(byte)0x1C,(byte)0x3E,(byte)0x0C,(byte)0x3F,(byte)0x80,(byte)0x7F,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xE0,(byte)0x00,(byte)0xFF,(byte)0x0F,(byte)0xFF,(byte)0xC1,(byte)0xFC,(byte)0x1C,(byte)0x3C,(byte)0x04,(byte)0x3E,(byte)0x00,(byte)0x3F,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xE0,(byte)0x00,(byte)0x3F,(byte)0x0F,(byte)0xFF,(byte)0xE0,(byte)0xF8,(byte)0x3C,(byte)0x38,(byte)0x00,(byte)0x3E,(byte)0x00,(byte)0x1F,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xE0,(byte)0x00,(byte)0x1F,(byte)0x0F,(byte)0xFF,(byte)0xE0,(byte)0xF8,(byte)0x3C,(byte)0x38,(byte)0x78,(byte)0x3C,(byte)0x1E,(byte)0x0F,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xE0,(byte)0xFC,(byte)0x0F,(byte)0x0F,(byte)0xFF,(byte)0xF0,(byte)0x70,(byte)0x7C,(byte)0x38,(byte)0x7C,(byte)0x3C,(byte)0x3F,(byte)0x0F,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xE0,(byte)0xFE,(byte)0x0F,(byte)0x0F,(byte)0xFF,(byte)0xF8,(byte)0x70,(byte)0xFC,(byte)0x38,(byte)0x7C,(byte)0x38,(byte)0x7F,(byte)0x0F,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xE0,(byte)0xFF,(byte)0x07,(byte)0x0F,(byte)0xFF,(byte)0xF8,(byte)0x20,(byte)0xFC,(byte)0x3C,(byte)0x3C,(byte)0x38,(byte)0x7F,(byte)0x07,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xE0,(byte)0xFF,(byte)0x07,(byte)0x0F,(byte)0xFF,(byte)0xFC,(byte)0x01,(byte)0xFC,(byte)0x3C,(byte)0x00,(byte)0x38,(byte)0x7F,(byte)0x07,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xE0,(byte)0xFF,(byte)0x87,(byte)0x0F,(byte)0xFF,(byte)0xFE,(byte)0x03,(byte)0xFC,(byte)0x3F,(byte)0x00,(byte)0x38,(byte)0x7F,(byte)0x07,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xE0,(byte)0xFF,(byte)0x87,(byte)0x07,(byte)0xFF,(byte)0xFE,(byte)0x03,(byte)0xFC,(byte)0x3F,(byte)0xFC,(byte)0x38,(byte)0x3F,(byte)0x0F,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xE0,(byte)0xFF,(byte)0x87,(byte)0x07,(byte)0xFF,(byte)0xFF,(byte)0x07,(byte)0xFC,(byte)0x3F,(byte)0xFC,(byte)0x3C,(byte)0x3F,(byte)0x0F,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xE0,(byte)0xFF,(byte)0x87,(byte)0x00,(byte)0x7F,(byte)0xFE,(byte)0x03,(byte)0xFC,(byte)0x3C,(byte)0xF8,(byte)0x7C,(byte)0x0C,(byte)0x0F,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xE0,(byte)0xFF,(byte)0x87,(byte)0x00,(byte)0x7F,(byte)0xFC,(byte)0x01,(byte)0xFC,(byte)0x3C,(byte)0x00,(byte)0x7E,(byte)0x00,(byte)0x1F,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xE0,(byte)0xFF,(byte)0x07,(byte)0x08,(byte)0x7F,(byte)0xFC,(byte)0x21,(byte)0xFC,(byte)0x3C,(byte)0x00,(byte)0xFF,(byte)0x00,(byte)0x3F,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xE0,(byte)0xFF,(byte)0x07,(byte)0x0E,(byte)0x7F,(byte)0xF8,(byte)0x30,(byte)0xFC,(byte)0x3F,(byte)0x83,(byte)0xFF,(byte)0xC0,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xE0,(byte)0xFE,(byte)0x0F,(byte)0xFF,(byte)0xFF,(byte)0xF8,(byte)0x70,(byte)0x7F,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xE0,(byte)0xF8,(byte)0x0F,(byte)0xFF,(byte)0xFF,(byte)0xF0,(byte)0x78,(byte)0x7F,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xE0,(byte)0x00,(byte)0x1F,(byte)0xFF,(byte)0xFF,(byte)0xE0,(byte)0xF8,(byte)0x3E,(byte)0x7F,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xE0,(byte)0x00,(byte)0x3F,(byte)0xFF,(byte)0xFF,(byte)0xE0,(byte)0xFC,(byte)0x3C,(byte)0x3F,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xE0,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xC1,(byte)0xFC,(byte)0x1C,(byte)0x3F,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFC,(byte)0x3F,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00},
        {(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0x7F,(byte)0xC7,(byte)0xE0,(byte)0x01,(byte)0xC0,(byte)0x00,(byte)0x8F,(byte)0xF8,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFE,(byte)0xFF,(byte)0xBF,(byte)0xD7,(byte)0xEF,(byte)0xFE,(byte)0xDF,(byte)0xFE,(byte)0xD7,(byte)0xF5,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFD,(byte)0x80,(byte)0xDF,(byte)0xD7,(byte)0xE8,(byte)0x03,(byte)0x50,(byte)0x00,(byte)0xEB,(byte)0xEB,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFB,(byte)0x7F,(byte)0x6F,(byte)0xD7,(byte)0xEB,(byte)0xFD,(byte)0x57,(byte)0xFF,(byte)0xF5,(byte)0xD7,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFA,(byte)0xFF,(byte)0xAF,(byte)0xD7,(byte)0xEB,(byte)0xFD,(byte)0x57,(byte)0xFF,(byte)0xF5,(byte)0xD7,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFA,(byte)0xFF,(byte)0x8F,(byte)0xD7,(byte)0xEB,(byte)0xFD,(byte)0x57,(byte)0xFF,(byte)0xFA,(byte)0xAF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFA,(byte)0xFF,(byte)0xFF,(byte)0xD7,(byte)0xEB,(byte)0xFD,(byte)0x57,(byte)0xFF,(byte)0xFD,(byte)0x5F,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFA,(byte)0xFF,(byte)0xFF,(byte)0xAB,(byte)0xE8,(byte)0x00,(byte)0xD0,(byte)0x03,(byte)0xFD,(byte)0x5F,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFA,(byte)0xFF,(byte)0xFF,(byte)0xAB,(byte)0xEF,(byte)0xFE,(byte)0xDF,(byte)0xFB,(byte)0xFE,(byte)0xBF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFA,(byte)0xFF,(byte)0xFF,(byte)0x6D,(byte)0xE8,(byte)0x02,(byte)0xD0,(byte)0x03,(byte)0xFD,(byte)0x5F,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFA,(byte)0xFF,(byte)0xFF,(byte)0x55,(byte)0xEB,(byte)0xFD,(byte)0x57,(byte)0xFF,(byte)0xFD,(byte)0x5F,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFB,(byte)0x7F,(byte)0x8E,(byte)0xBA,(byte)0xEB,(byte)0xFD,(byte)0x57,(byte)0xFF,(byte)0xFA,(byte)0xAF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFD,(byte)0xBF,(byte)0x6E,(byte)0xBA,(byte)0xEB,(byte)0xFD,(byte)0x57,(byte)0xFF,(byte)0xF5,(byte)0xD7,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFE,(byte)0xC0,(byte)0xDD,(byte)0x7D,(byte)0x68,(byte)0x03,(byte)0x50,(byte)0x00,(byte)0xF5,(byte)0xD7,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x7F,(byte)0xBB,(byte)0x7D,(byte)0xAF,(byte)0xFE,(byte)0xDF,(byte)0xFE,(byte)0xEB,(byte)0xEB,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x80,(byte)0x78,(byte)0xFE,(byte)0x20,(byte)0x01,(byte)0xC0,(byte)0x00,(byte)0xC7,(byte)0xF1,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xF0,(byte)0x00,(byte)0x3E,(byte)0x03,(byte)0xFC,(byte)0x03,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xF0,(byte)0x00,(byte)0x3C,(byte)0x01,(byte)0xF0,(byte)0x01,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xF0,(byte)0x00,(byte)0x38,(byte)0x00,(byte)0xF0,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xF1,(byte)0xFF,(byte)0xF1,(byte)0xFC,(byte)0x63,(byte)0xF8,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xF1,(byte)0xFF,(byte)0xE3,(byte)0xFE,(byte)0x23,(byte)0xF8,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xF1,(byte)0xFF,(byte)0xE3,(byte)0xFE,(byte)0x3F,(byte)0xF8,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xF1,(byte)0xFF,(byte)0xE3,(byte)0xFE,(byte)0x3F,(byte)0xC0,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xF0,(byte)0x00,(byte)0xE3,(byte)0xFE,(byte)0x3C,(byte)0x01,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xF0,(byte)0x00,(byte)0xE3,(byte)0xFE,(byte)0x30,(byte)0x03,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xF0,(byte)0x00,(byte)0xE3,(byte)0xFE,(byte)0x20,(byte)0x1F,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xF1,(byte)0xFF,(byte)0xE3,(byte)0xFE,(byte)0x23,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xF1,(byte)0xFF,(byte)0xE3,(byte)0xFE,(byte)0x23,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xF1,(byte)0xFF,(byte)0xF1,(byte)0xFC,(byte)0x63,(byte)0xF8,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xF0,(byte)0x00,(byte)0x38,(byte)0x00,(byte)0xE0,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xF0,(byte)0x00,(byte)0x3C,(byte)0x01,(byte)0xF0,(byte)0x01,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xF0,(byte)0x00,(byte)0x3E,(byte)0x03,(byte)0xF8,(byte)0x07,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00},
        {(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFC,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xF9,(byte)0xFF,(byte)0xFF,(byte)0x3F,(byte)0xFF,(byte)0x9F,(byte)0xFC,(byte)0x7F,(byte)0xFF,(byte)0xC7,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xF0,(byte)0x7F,(byte)0xFC,(byte)0x1F,(byte)0xFE,(byte)0x0F,(byte)0xFC,(byte)0x7F,(byte)0xFF,(byte)0x83,(byte)0xFE,(byte)0x00,(byte)0x7F,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xE0,(byte)0x3F,(byte)0xF8,(byte)0x0F,(byte)0xFF,(byte)0x0F,(byte)0xFC,(byte)0x7F,(byte)0xFF,(byte)0x80,(byte)0xFE,(byte)0x00,(byte)0x3F,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xF0,(byte)0x1F,(byte)0xF0,(byte)0x0F,(byte)0xFF,(byte)0x87,(byte)0x1C,(byte)0x4F,(byte)0xFF,(byte)0xC0,(byte)0x7E,(byte)0x1C,(byte)0x3F,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFC,(byte)0x0F,(byte)0xE0,(byte)0x3F,(byte)0xFF,(byte)0x87,(byte)0x1C,(byte)0x43,(byte)0xFF,(byte)0xF0,(byte)0x7E,(byte)0x1C,(byte)0x3F,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFE,(byte)0x07,(byte)0xC0,(byte)0xFF,(byte)0xFF,(byte)0xC7,(byte)0x1C,(byte)0x03,(byte)0xFF,(byte)0xF8,(byte)0x3E,(byte)0x3E,(byte)0x3F,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0x03,(byte)0xC1,(byte)0xFF,(byte)0xFE,(byte)0x43,(byte)0x1C,(byte)0x03,(byte)0xFF,(byte)0xFC,(byte)0x1E,(byte)0x3E,(byte)0x3F,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0x83,(byte)0x83,(byte)0xFF,(byte)0xFC,(byte)0x43,(byte)0x1C,(byte)0x61,(byte)0xFF,(byte)0xFE,(byte)0x1E,(byte)0x3E,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xC1,(byte)0x07,(byte)0xFF,(byte)0xFC,(byte)0x63,(byte)0x1C,(byte)0x61,(byte)0xFF,(byte)0xFE,(byte)0x1E,(byte)0x3F,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xE1,(byte)0x0F,(byte)0xFF,(byte)0xFC,(byte)0x63,(byte)0x1C,(byte)0x61,(byte)0xFF,(byte)0xFF,(byte)0x1E,(byte)0x3F,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xF0,(byte)0x1F,(byte)0xFF,(byte)0xFC,(byte)0x63,(byte)0x1C,(byte)0x61,(byte)0xFF,(byte)0xFF,(byte)0x1E,(byte)0x3F,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xF0,(byte)0x1F,(byte)0xFF,(byte)0xFC,(byte)0x63,(byte)0x1C,(byte)0x61,(byte)0xFF,(byte)0xE0,(byte)0x00,(byte)0x01,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xF0,(byte)0x3F,(byte)0xFF,(byte)0xFC,(byte)0x63,(byte)0x1C,(byte)0x61,(byte)0xFF,(byte)0xE0,(byte)0x00,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xF8,(byte)0x3F,(byte)0xFF,(byte)0xFC,(byte)0x63,(byte)0x1C,(byte)0x61,(byte)0xFF,(byte)0xE0,(byte)0x00,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xF8,(byte)0x3F,(byte)0xFF,(byte)0xFC,(byte)0x63,(byte)0x1C,(byte)0x61,(byte)0xFF,(byte)0xE0,(byte)0x00,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xE0,(byte)0x00,(byte)0x00,(byte)0x0F,(byte)0xFC,(byte)0x63,(byte)0x00,(byte)0x01,(byte)0xFF,(byte)0xE1,(byte)0xFF,(byte)0xF0,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xE0,(byte)0x00,(byte)0x00,(byte)0x0F,(byte)0xFC,(byte)0x63,(byte)0x00,(byte)0x01,(byte)0xFF,(byte)0xE1,(byte)0xFF,(byte)0xF0,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xE0,(byte)0x00,(byte)0x00,(byte)0x0F,(byte)0xFC,(byte)0x63,(byte)0x00,(byte)0x01,(byte)0xFF,(byte)0xE1,(byte)0xFF,(byte)0xF0,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xE0,(byte)0x00,(byte)0x00,(byte)0x0F,(byte)0xFC,(byte)0x63,(byte)0x00,(byte)0x03,(byte)0xFF,(byte)0xE1,(byte)0xFF,(byte)0xF0,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xF8,(byte)0x7F,(byte)0xFF,(byte)0xFC,(byte)0x63,(byte)0xFC,(byte)0x7F,(byte)0xFF,(byte)0xE1,(byte)0xFF,(byte)0xF0,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xF8,(byte)0x7F,(byte)0xFF,(byte)0xFC,(byte)0x63,(byte)0xFC,(byte)0x7F,(byte)0xFF,(byte)0xE1,(byte)0xFF,(byte)0xF0,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFC,(byte)0x7F,(byte)0xFF,(byte)0xFC,(byte)0x63,(byte)0x00,(byte)0x01,(byte)0xFF,(byte)0xE0,(byte)0x00,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFC,(byte)0x7F,(byte)0xFF,(byte)0xFC,(byte)0x63,(byte)0x00,(byte)0x01,(byte)0xFF,(byte)0xE0,(byte)0x00,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFC,(byte)0x7F,(byte)0xFF,(byte)0xFF,(byte)0xE3,(byte)0x00,(byte)0x01,(byte)0xFF,(byte)0xE0,(byte)0x00,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFC,(byte)0x7F,(byte)0xFF,(byte)0xFF,(byte)0xE3,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00},
        {(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFC,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFC,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFE,(byte)0x7F,(byte)0xFE,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFC,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0x1F,(byte)0xFC,(byte)0x07,(byte)0xF9,(byte)0xFF,(byte)0xFC,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFC,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xC7,(byte)0xF8,(byte)0x1F,(byte)0xFC,(byte)0x7F,(byte)0xFC,(byte)0xFF,(byte)0xFC,(byte)0x7F,(byte)0xF8,(byte)0x00,(byte)0x3F,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xE3,(byte)0xF8,(byte)0x7F,(byte)0xFE,(byte)0x3F,(byte)0xFC,(byte)0xFF,(byte)0xFF,(byte)0x3F,(byte)0xF1,(byte)0xFC,(byte)0x3F,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xF1,(byte)0xF0,(byte)0xFF,(byte)0xFF,(byte)0x1F,(byte)0xFC,(byte)0xFF,(byte)0xFF,(byte)0x8F,(byte)0xF3,(byte)0xFE,(byte)0x7F,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xF1,(byte)0xE1,(byte)0xFF,(byte)0xFF,(byte)0x8F,(byte)0xFC,(byte)0xFF,(byte)0xFF,(byte)0xC7,(byte)0xE3,(byte)0xFE,(byte)0x7F,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xF8,(byte)0xE3,(byte)0xFF,(byte)0xFF,(byte)0x8F,(byte)0xFC,(byte)0xFF,(byte)0xFF,(byte)0xE3,(byte)0xE3,(byte)0xFE,(byte)0x7F,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xF8,(byte)0xC7,(byte)0xFF,(byte)0xFF,(byte)0xC7,(byte)0x9C,(byte)0xE3,(byte)0xFF,(byte)0xF1,(byte)0xE3,(byte)0xFE,(byte)0x7F,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFC,(byte)0x4F,(byte)0xFF,(byte)0xFF,(byte)0xC7,(byte)0x1C,(byte)0xC3,(byte)0xFF,(byte)0xF8,(byte)0xE3,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFC,(byte)0x1F,(byte)0xFF,(byte)0xFF,(byte)0xE7,(byte)0x1C,(byte)0x81,(byte)0xFF,(byte)0xFC,(byte)0x63,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFC,(byte)0x1F,(byte)0xFF,(byte)0xFE,(byte)0x63,(byte)0x1C,(byte)0xF1,(byte)0xFF,(byte)0xFE,(byte)0x33,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFE,(byte)0x3F,(byte)0xFF,(byte)0xFC,(byte)0x63,(byte)0x9C,(byte)0xF1,(byte)0xFF,(byte)0xFE,(byte)0x13,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFE,(byte)0x3F,(byte)0xFF,(byte)0xFC,(byte)0x63,(byte)0x9C,(byte)0xF1,(byte)0xFF,(byte)0xFF,(byte)0x13,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0x06,(byte)0x3F,(byte)0xFF,(byte)0xFE,(byte)0x63,(byte)0x9C,(byte)0xF1,(byte)0xFF,(byte)0xFC,(byte)0x31,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFE,(byte)0x00,(byte)0x1F,(byte)0xFF,(byte)0xFE,(byte)0x73,(byte)0x9C,(byte)0xF1,(byte)0xFF,(byte)0xFC,(byte)0x01,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFE,(byte)0x00,(byte)0x1F,(byte)0xFE,(byte)0x73,(byte)0x80,(byte)0xF1,(byte)0xFF,(byte)0xFC,(byte)0xE0,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFE,(byte)0x38,(byte)0x1F,(byte)0xFE,(byte)0x73,(byte)0x38,(byte)0x01,(byte)0xFF,(byte)0xF8,(byte)0xF8,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFE,(byte)0x3F,(byte)0xFF,(byte)0xFE,(byte)0x73,(byte)0xFC,(byte)0x41,(byte)0xFF,(byte)0xF8,(byte)0xFC,(byte)0x7F,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFE,(byte)0x3F,(byte)0xFF,(byte)0xFE,(byte)0x33,(byte)0xFC,(byte)0x7F,(byte)0xFF,(byte)0xF0,(byte)0xFC,(byte)0x7F,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFE,(byte)0x3F,(byte)0xFF,(byte)0xFE,(byte)0x71,(byte)0xFC,(byte)0x7F,(byte)0xFF,(byte)0xF1,(byte)0xFC,(byte)0x3F,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFE,(byte)0x3F,(byte)0xFF,(byte)0xFF,(byte)0xF1,(byte)0x08,(byte)0xFF,(byte)0xFF,(byte)0xE0,(byte)0x3C,(byte)0x1F,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFE,(byte)0x3F,(byte)0xFF,(byte)0xFF,(byte)0xF1,(byte)0x00,(byte)0x0F,(byte)0xFF,(byte)0xFF,(byte)0x80,(byte)0x1F,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFE,(byte)0x3F,(byte)0xFF,(byte)0xFF,(byte)0xF1,(byte)0xFE,(byte)0x01,(byte)0xFF,(byte)0xFF,(byte)0xF0,(byte)0x3F,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFE,(byte)0x1F,(byte)0xFF,(byte)0xFF,(byte)0xE1,(byte)0xFF,(byte)0xE3,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFE,(byte)0x1F,(byte)0xFF,(byte)0xFF,(byte)0xE3,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFC,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00},
        {(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xCF,(byte)0xFF,(byte)0xF1,(byte)0x1E,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x8F,(byte)0xE0,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0x3F,(byte)0xFF,(byte)0x87,(byte)0xF8,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x9F,(byte)0xC0,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0x3F,(byte)0xFF,(byte)0x83,(byte)0xF0,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x8C,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0x0F,(byte)0xFF,(byte)0x83,(byte)0xE0,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x08,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0x07,(byte)0xFF,(byte)0x81,(byte)0xC0,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x08,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0x03,(byte)0xFF,(byte)0x91,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x80,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0x01,(byte)0xFF,(byte)0x80,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x80,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0xFF,(byte)0x80,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x80,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0xFF,(byte)0x80,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x80,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0xFF,(byte)0x90,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xC0,(byte)0x00,(byte)0x07,(byte)0xFF,(byte)0xFE,(byte)0x00,(byte)0x00,(byte)0xFF,(byte)0xF0,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0x80,(byte)0x00,(byte)0x1F,(byte)0xFF,(byte)0xFF,(byte)0xC0,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0x80,(byte)0x00,(byte)0x3F,(byte)0xFF,(byte)0xFF,(byte)0xE1,(byte)0x00,(byte)0xFF,(byte)0xFE,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFE,(byte)0x00,(byte)0x00,(byte)0x7F,(byte)0xFF,(byte)0xFF,(byte)0xF9,(byte)0xC3,(byte)0xFF,(byte)0xFE,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFE,(byte)0x00,(byte)0x00,(byte)0x7F,(byte)0xE1,(byte)0xFF,(byte)0xF8,(byte)0xFF,(byte)0xFF,(byte)0xFC,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0x02,(byte)0x7F,(byte)0x80,(byte)0xFF,(byte)0xF8,(byte)0x3F,(byte)0xFF,(byte)0xFC,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0x80,(byte)0x0C,(byte)0x1F,(byte)0x0B,(byte)0xFF,(byte)0x9C,(byte)0x3F,(byte)0xFF,(byte)0xFC,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0x0C,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0x0C,(byte)0x3F,(byte)0xFF,(byte)0xFC,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFC,(byte)0x00,(byte)0x1E,(byte)0x00,(byte)0x20,(byte)0x00,(byte)0x0C,(byte)0x0F,(byte)0xFF,(byte)0xFC,(byte)0x01,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xF8,(byte)0x00,(byte)0x3E,(byte)0x03,(byte)0xFF,(byte)0xE8,(byte)0x1F,(byte)0x83,(byte)0xFF,(byte)0xFC,(byte)0x01,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xF8,(byte)0x00,(byte)0x3F,(byte)0xE7,(byte)0xFF,(byte)0xCD,(byte)0xFF,(byte)0xC1,(byte)0xFF,(byte)0xFC,(byte)0x01,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFC,(byte)0x00,(byte)0x7F,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xE0,(byte)0xFF,(byte)0xF0,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xF8,(byte)0x00,(byte)0x7F,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xE0,(byte)0x1F,(byte)0xE0,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xE0,(byte)0x00,(byte)0x7F,(byte)0xFE,(byte)0x3C,(byte)0x33,(byte)0xFF,(byte)0xF0,(byte)0x00,(byte)0x00,(byte)0x3F,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xC0,(byte)0x00,(byte)0x7F,(byte)0xFE,(byte)0x1C,(byte)0x39,(byte)0xFF,(byte)0xF8,(byte)0x00,(byte)0x00,(byte)0x3F,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xC0,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x7F,(byte)0xFF,(byte)0xF8,(byte)0x00,(byte)0x00,(byte)0x1F,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xC0,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFC,(byte)0x00,(byte)0x00,(byte)0x1F,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xE0,(byte)0x01,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFE,(byte)0x00,(byte)0x00,(byte)0x3F,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xE0,(byte)0x01,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFE,(byte)0x00,(byte)0x00,(byte)0x3F,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0x80,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFE,(byte)0x00,(byte)0x00,(byte)0x7F,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0x00,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFE,(byte)0x00,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0x00,(byte)0x00,(byte)0x7F,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFC,(byte)0x00,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFE,(byte)0x00,(byte)0x78,(byte)0x43,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFC,(byte)0x00,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFE,(byte)0x00,(byte)0x38,(byte)0x00,(byte)0xFF,(byte)0xF2,(byte)0x07,(byte)0xF8,(byte)0x00,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0x38,(byte)0x00,(byte)0xFF,(byte)0xF0,(byte)0x00,(byte)0xF8,(byte)0x00,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0x0C,(byte)0x01,(byte)0xFF,(byte)0xF0,(byte)0x00,(byte)0xF0,(byte)0x00,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0x01,(byte)0xFF,(byte)0xFF,(byte)0xF8,(byte)0x03,(byte)0x80,(byte)0x00,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFE,(byte)0x80,(byte)0x00,(byte)0x00,(byte)0xFF,(byte)0xF3,(byte)0xFC,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFE,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0xFF,(byte)0xE0,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0x01,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFC,(byte)0x00,(byte)0x00,(byte)0x01,(byte)0xFF,(byte)0xE0,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0x03,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xF8,(byte)0x00,(byte)0x00,(byte)0x1F,(byte)0xFF,(byte)0xFE,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0x07,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFC,(byte)0x00,(byte)0x1F,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x80,(byte)0x00,(byte)0x00,(byte)0x07,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFC,(byte)0x00,(byte)0x0F,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0x00,(byte)0x07,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFE,(byte)0x00,(byte)0x0F,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFE,(byte)0x00,(byte)0x00,(byte)0x07,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0x03,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFC,(byte)0x00,(byte)0x00,(byte)0x0F,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0x07,(byte)0xF8,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0x1F,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0x80,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0x3F,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xC0,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0x7F,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xF0,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xF0,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0x01,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFC,(byte)0x00,(byte)0x00,(byte)0x1C,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0x03,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFE,(byte)0x00,(byte)0x00,(byte)0x0C,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0x0F,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0x3F,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xC0,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0x7F,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xF8,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFC,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0x03,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0x03,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xF0,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0x0F,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0x0F,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFC,(byte)0x00,(byte)0x00,(byte)0x7F,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xF7,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00},
        {(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xE0,(byte)0x07,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xF4,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFD,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFE,(byte)0x38,(byte)0x1F,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xE7,(byte)0xC4,(byte)0xDF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xF7,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xDF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xF8,(byte)0x2F,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xDF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFB,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFC,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x1F,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xE7,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xD1,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xF0,(byte)0x3F,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xDF,(byte)0xF0,(byte)0x0F,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x7F,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xEF,(byte)0xE0,(byte)0x03,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x7F,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xD2,(byte)0xC0,(byte)0x00,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x7F,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xDF,(byte)0xFF,(byte)0xC0,(byte)0x80,(byte)0x00,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x7F,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xBF,(byte)0xFF,(byte)0xE0,(byte)0x18,(byte)0x00,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xAB,(byte)0xFF,(byte)0xF7,(byte)0xFF,(byte)0x7F,(byte)0xFF,(byte)0xF0,(byte)0x08,(byte)0x00,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x8F,(byte)0xFE,(byte)0x7F,(byte)0xFF,(byte)0xF2,(byte)0x60,(byte)0x00,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFE,(byte)0x37,(byte)0xFF,(byte)0x1F,(byte)0xFE,(byte)0x7F,(byte)0xFF,(byte)0xF9,(byte)0x80,(byte)0x00,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFE,(byte)0x37,(byte)0xFE,(byte)0x7F,(byte)0xF8,(byte)0x0F,(byte)0xFF,(byte)0xFA,(byte)0x5E,(byte)0x80,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFE,(byte)0x17,(byte)0xF9,(byte)0xFF,(byte)0xF0,(byte)0x03,(byte)0xFF,(byte)0xF8,(byte)0x80,(byte)0x00,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFE,(byte)0x0F,(byte)0xFF,(byte)0xFF,(byte)0xF4,(byte)0x71,(byte)0xDF,(byte)0xF8,(byte)0x40,(byte)0x00,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFE,(byte)0x2F,(byte)0xFF,(byte)0x9F,(byte)0xE4,(byte)0x68,(byte)0xFF,(byte)0xD0,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFB,(byte)0x5F,(byte)0xFF,(byte)0x9F,(byte)0xFE,(byte)0x78,(byte)0x87,(byte)0xE0,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x5F,(byte)0xFF,(byte)0x9F,(byte)0xF6,(byte)0x7C,(byte)0xA7,(byte)0x80,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0x9F,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xDF,(byte)0xE7,(byte)0x3C,(byte)0xE7,(byte)0xC0,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xB7,(byte)0x2C,(byte)0x4F,(byte)0xC0,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x7F,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xF7,(byte)0x3C,(byte)0x83,(byte)0xA0,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xF7,(byte)0xF7,(byte)0x3C,(byte)0x02,(byte)0x80,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xF3,(byte)0x77,(byte)0x3C,(byte)0x00,(byte)0x40,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xDE,(byte)0xFF,(byte)0xC2,(byte)0xF6,(byte)0x3A,(byte)0x00,(byte)0x80,(byte)0x00,(byte)0x02,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x09,(byte)0xFF,(byte)0x01,(byte)0xF2,(byte)0x32,(byte)0x81,(byte)0x80,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0xFF,(byte)0xBF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xF8,(byte)0x03,(byte)0xA3,(byte)0x42,(byte)0x9A,(byte)0x0F,(byte)0x00,(byte)0x10,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFC,(byte)0x03,(byte)0xFD,(byte)0x87,(byte)0x88,(byte)0x04,(byte)0x00,(byte)0x94,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFB,(byte)0x87,(byte)0xE1,(byte)0x0F,(byte)0xAC,(byte)0x50,(byte)0x20,(byte)0x00,(byte)0x00,(byte)0x02,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFD,(byte)0x86,(byte)0xF0,(byte)0x07,(byte)0x81,(byte)0x40,(byte)0x40,(byte)0x80,(byte)0xC0,(byte)0x04,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xF3,(byte)0x8B,(byte)0x78,(byte)0x01,(byte)0x08,(byte)0xE0,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0x69,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xE3,(byte)0xA3,(byte)0x3C,(byte)0x78,(byte)0x08,(byte)0x20,(byte)0x04,(byte)0x80,(byte)0x03,(byte)0x56,(byte)0x00,(byte)0xFD,(byte)0xFF,(byte)0x7F,(byte)0xFF,(byte)0xFF,(byte)0xA7,(byte)0xA9,(byte)0x9F,(byte)0xFF,(byte)0x00,(byte)0x7F,(byte)0x01,(byte)0x01,(byte)0xE0,(byte)0x22,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xC7,(byte)0xAB,(byte)0x9D,(byte)0xC7,(byte)0x5B,(byte)0x8D,(byte)0xC2,(byte)0x55,(byte)0x01,(byte)0x3F,(byte)0x00,(byte)0xFF,(byte)0xAE,(byte)0xFF,(byte)0xFB,(byte)0xFF,(byte)0xC7,(byte)0x83,(byte)0x81,(byte)0xF9,(byte)0x28,(byte)0x20,(byte)0x0F,(byte)0xE5,(byte)0x43,(byte)0x5F,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0x5F,(byte)0xFB,(byte)0xDD,(byte)0xC6,(byte)0xC7,(byte)0x90,(byte)0x86,(byte)0x80,(byte)0x00,(byte)0x3F,(byte)0xEC,(byte)0x34,(byte)0x3F,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0x7F,(byte)0xFF,(byte)0xFF,(byte)0xCF,(byte)0xCB,(byte)0x59,(byte)0x97,(byte)0x00,(byte)0x01,(byte)0xFF,(byte)0xEB,(byte)0xA8,(byte)0xB7,(byte)0x00,(byte)0xFF,(byte)0xF7,(byte)0x6F,(byte)0x5D,(byte)0xCB,(byte)0x93,(byte)0x6B,(byte)0xD8,(byte)0x20,(byte)0x00,(byte)0x21,(byte)0xFF,(byte)0xFF,(byte)0xFD,(byte)0xFB,(byte)0x00,(byte)0xFF,(byte)0xFA,(byte)0xAE,(byte)0x8F,(byte)0x13,(byte)0xA1,(byte)0x81,(byte)0x78,(byte)0x04,(byte)0x10,(byte)0x03,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFC,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0x43,(byte)0x02,(byte)0x0F,(byte)0xD2,(byte)0x06,(byte)0xF8,(byte)0x00,(byte)0x00,(byte)0x1C,(byte)0x7F,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0x7C,(byte)0x00,(byte)0x15,(byte)0xE0,(byte)0x0B,(byte)0xF8,(byte)0x00,(byte)0x00,(byte)0x7F,(byte)0x9F,(byte)0x7F,(byte)0xFF,(byte)0xAC,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xC1,(byte)0x00,(byte)0x01,(byte)0x80,(byte)0x0B,(byte)0xF4,(byte)0x00,(byte)0x01,(byte)0xFF,(byte)0xF1,(byte)0xFF,(byte)0xFC,(byte)0x07,(byte)0x00,(byte)0xFF,(byte)0xFC,(byte)0xEE,(byte)0x20,(byte)0x00,(byte)0x01,(byte)0x8B,(byte)0xF0,(byte)0x00,(byte)0x07,(byte)0xFF,(byte)0xFF,(byte)0xF8,(byte)0x07,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFE,(byte)0x00,(byte)0x01,(byte)0x00,(byte)0x2D,(byte)0xD0,(byte)0x00,(byte)0x1F,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFE,(byte)0xFF,(byte)0xC2,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0x00,(byte)0x13,(byte)0x9F,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xEE,(byte)0x78,(byte)0x08,(byte)0x00,(byte)0x00,(byte)0x1E,(byte)0x3F,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0x7F,(byte)0xFB,(byte)0xDD,(byte)0x02,(byte)0x00,(byte)0x02,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFD,(byte)0xFF,(byte)0xFF,(byte)0x80,(byte)0x0F,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x40,(byte)0x3F,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x87,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xDF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00},
        {(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0xFF,(byte)0x00}
        
    };
    NSArray *imageNames = @[@"Dr. Xiao", @"EOS Cybex", @"Big Brother", @"Big Brother2", @"Che Guevara", @"wsh", @"white"];
    
    
    if (self->imageCount <= 0) {
        [self printLog:@"invalid image count, please call GetImageList first!"];
        return;
    }
    
    int imgIndex = [PickerViewAlert doModal:self title:@"please select image:" dataSouce:imageNames];
    if (imgIndex < 0) {
        return;
    }
    
    NSMutableArray *arr = [NSMutableArray new];
    for (int i = 0; i < imageCount; i++) {
        [arr addObject:[NSString stringWithFormat:@"%d", i]];
    }
    int index = [PickerViewAlert doModal:self title:@"please select image index to set:" dataSouce:arr];
    if (index < 0) {
        return;
    }
    size_t destImgLen = 10240;
    NSMutableData *destImg = [NSMutableData dataWithLength:destImgLen];
    [self printLog:@"ready to call PAEW_ConvertBMP"];
    int iRtn = PAEW_ConvertBMP(imageData[imgIndex], sizeof(imageData[imgIndex]), 120, 64, [destImg bytes], &destImgLen);
    if (iRtn != PAEW_RET_SUCCESS) {
        [self printLog:@"PAEW_ShowImage returns failed: %@", [Utils errorCodeToString:iRtn]];
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int devIdx = 0;
        void *ppPAEWContext = (void*)self.savedDevice;
        int iRtn = PAEW_SetImageData(ppPAEWContext, devIdx, index, [destImg bytes], destImgLen);
        if (iRtn != PAEW_RET_SUCCESS) {
            [self printLog:@"PAEW_SetImageData returns failed: %@", [Utils errorCodeToString:iRtn]];
            return;
        }
        [self printLog:@"PAEW_SetImageData on index %d returns success", index];
    });
    
}

- (UIButton *)showImageBtn
{
    if (!_showImageBtn) {
        _showImageBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_showImageBtn setTitle:@"ShowImg" forState:UIControlStateNormal];
        [_showImageBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        _showImageBtn.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium];
        [_showImageBtn setBackgroundColor:[UIColor lightGrayColor]];
        [_showImageBtn addTarget:self action:@selector(showImageBtnAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _showImageBtn;
}

- (void)showImageBtnAction
{
    if (self->imageCount <= 0) {
        [self printLog:@"invalid image count, please call GetImageList first!"];
        return;
    }
    NSMutableArray *arr = [NSMutableArray new];
    for (int i = 0; i < imageCount; i++) {
        [arr addObject:[NSString stringWithFormat:@"%d", i]];
    }
    int index = [PickerViewAlert doModal:self title:@"please select image index:" dataSouce:arr];
    if (index < 0) {
        return;
    }
    
    NSArray *arrType = @[@"PAEW_LCD_CLEAR", @"PAEW_LCD_SHOW_LOGO", @"PAEW_LCD_CLEAR_SHOW_LOGO"];
    
    int type = [PickerViewAlert doModal:self title:@"please select show type:" dataSouce:arrType];
    if (type < 0) {
        return;
    }
    [self printLog:@"ready to call PAEW_ShowImage"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int devIdx = 0;
        void *ppPAEWContext = (void*)self.savedDevice;
        int iRtn = PAEW_ShowImage(ppPAEWContext, devIdx, index, type);
        if (iRtn != PAEW_RET_SUCCESS) {
            [self printLog:@"PAEW_ShowImage returns failed: %@", [Utils errorCodeToString:iRtn]];
            return;
        }
        [self printLog:@"PAEW_ShowImage returns success, current image index is %d", index];
    });
}

- (UIButton *)setLogoImageBtn
{
    if (!_setLogoImageBtn) {
        _setLogoImageBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_setLogoImageBtn setTitle:@"SetLogo" forState:UIControlStateNormal];
        [_setLogoImageBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        _setLogoImageBtn.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium];
        [_setLogoImageBtn setBackgroundColor:[UIColor lightGrayColor]];
        [_setLogoImageBtn addTarget:self action:@selector(setLogoImageBtnAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _setLogoImageBtn;
}

- (void)setLogoImageBtnAction
{
    if (self->imageCount <= 0) {
        [self printLog:@"invalid image count, please call GetImageList first!"];
        return;
    }
    NSMutableArray *arr = [NSMutableArray new];
    for (int i = 0; i < imageCount; i++) {
        [arr addObject:[NSString stringWithFormat:@"%d", i]];
    }
    int index = [PickerViewAlert doModal:self title:@"please select image index:" dataSouce:arr];
    if (index < 0) {
        return;
    }
    
    [self printLog:@"ready to call PAEW_SetLogoImage"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int devIdx = 0;
        void *ppPAEWContext = (void*)self.savedDevice;
        int iRtn = PAEW_SetLogoImage(ppPAEWContext, devIdx, index);
        if (iRtn != PAEW_RET_SUCCESS) {
            [self printLog:@"PAEW_SetLogoImage returns failed: %@", [Utils errorCodeToString:iRtn]];
            return;
        }
        [self printLog:@"PAEW_SetLogoImage returns success, current logi index is %d", index];
    });
}



- (void)powerOffBtnAction
{
    [self printLog:@"ready to call PAEW_PowerOff"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int devIdx = 0;
        void *ppPAEWContext = (void*)self.savedDevice;
        int iRtn = PAEW_RET_UNKNOWN_FAIL;
        iRtn = PAEW_PowerOff(ppPAEWContext, devIdx);
        if (iRtn != PAEW_RET_SUCCESS) {
            [self printLog:@"PAEW_PowerOff returns failed: %@", [Utils errorCodeToString:iRtn]];
        } else {
            [self printLog:@"PAEW_PowerOff returns success"];
        }
        
    });
}

- (void)writeSNBtnAction
{
    self->_inputView =[ToolInputView toolInputViewWithCallback:^(NSString *number) {
        self->_inputView = nil;
        if (number.length != 15) {
            [self printLog:@"Invalid SN input"];
            return ;
        }
        BOOL snValid = YES;
        for (int i = 0; i < number.length; i++) {
            char c = [number UTF8String][i];
            if (!((c >= '0' && c <= '9') || (c >= 'a' && c<= 'z') || (c >= 'A' && c <= 'Z'))) {
                snValid = NO;
            }
        }
        if (!snValid) {
            [self printLog:@"Invalid SN input"];
            return;
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            int devIdx = 0;
            void *ppPAEWContext = (void*)self.savedDevice;
            int iRtn = PAEW_RET_UNKNOWN_FAIL;
            unsigned char serial[PAEW_DEV_INFO_SN_LEN] = {0};
            memcpy(serial, [number UTF8String], 15);
            [self printLog:@"ready to call PAEW_WriteSN"];
            iRtn = PAEW_WriteSN(ppPAEWContext, devIdx, serial, PAEW_DEV_INFO_SN_LEN);
            if (iRtn != PAEW_RET_SUCCESS) {
                [self printLog:@"PAEW_WriteSN returns failed: %@", [Utils errorCodeToString:iRtn]];
            } else {
                [self printLog:@"PAEW_WriteSN returns success"];
            }
        });
        
    }];
}

- (void)clearScreenBtnAction
{
    [self printLog:@"ready to call PAEW_ClearLCD"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int devIdx = 0;
        void *ppPAEWContext = (void*)self.savedDevice;
        int iRtn = PAEW_RET_UNKNOWN_FAIL;
        iRtn = PAEW_ClearLCD(ppPAEWContext, devIdx);
        if (iRtn != PAEW_RET_SUCCESS) {
            [self printLog:@"PAEW_ClearLCD returns failed: %@", [Utils errorCodeToString:iRtn]];
        } else {
            [self printLog:@"PAEW_ClearLCD returns success"];
        }
        
    });
}

- (void)clearLogBtnAction
{
    self->logCounter = 0;
    if ([NSThread isMainThread]) {
        self.in_outTextView.text = @"";
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.in_outTextView.text = @"";
        });
    }
}

- (void)abortBtnAction
{
    self.abortBtnState = YES;
    __weak typeof(self) weakSelf = self;
    self.abortHandelBlock = ^(BOOL abortState) {
        if (!abortState) {
            return ;
        }
        __strong typeof(weakSelf) strongSelf = weakSelf;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            int devIdx = 0;
            uint64_t temp = strongSelf.savedDevice;
            void *ppPAEWContext = (void*)temp;
            int iRtn = PAEW_RET_UNKNOWN_FAIL;
            
            strongSelf.abortBtnState = NO;
            [strongSelf printLog:@"ready to call PAEW_AbortFP"];
            [strongSelf.abortCondition lock];
            iRtn = PAEW_AbortFP(ppPAEWContext, devIdx);
            [strongSelf.abortCondition signal];
            [strongSelf.abortCondition unlock];
            
            if (iRtn != PAEW_RET_SUCCESS) {
                [strongSelf printLog:@"PAEW_AbortFP returns failed %@", [Utils errorCodeToString:iRtn]];
                return ;
            }
            
            [strongSelf printLog:@"PAEW_AbortFP returns success"];
        });
    };
    
}

- (UIButton *)calibrateFPBtn
{
    if (!_calibrateFPBtn) {
        _calibrateFPBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_calibrateFPBtn setTitle:@"CalibrateFP" forState:UIControlStateNormal];
        [_calibrateFPBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        _calibrateFPBtn.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium];
        [_calibrateFPBtn setBackgroundColor:[UIColor lightGrayColor]];
        [_calibrateFPBtn addTarget:self action:@selector(calibrateFPBtnAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _calibrateFPBtn;
}

- (void)calibrateFPBtnAction
{
    [self printLog:@"ready to call PAEW_CalibrateFP"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int devIdx = 0;
        void *ppPAEWContext = (void*)self.savedDevice;
        int iRtn = PAEW_RET_UNKNOWN_FAIL;
        iRtn = PAEW_CalibrateFP(ppPAEWContext, devIdx);
        if (iRtn != PAEW_RET_SUCCESS) {
            [self printLog:@"PAEW_CalibrateFP returns failed: %@", [Utils errorCodeToString:iRtn]];
        } else {
            [self printLog:@"PAEW_CalibrateFP returns success"];
        }
        
    });
}

- (UIButton *)freeContextBtn
{
    if (!_freeContextBtn) {
        _freeContextBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_freeContextBtn setTitle:@"FreeContext" forState:UIControlStateNormal];
        [_freeContextBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        _freeContextBtn.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium];
        [_freeContextBtn setBackgroundColor:[UIColor lightGrayColor]];
        [_freeContextBtn addTarget:self action:@selector(freeContextBtnAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _freeContextBtn;
}

- (void)freeContextBtnAction
{
    [self printLog:@"ready to call PAEW_FreeContext"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        void *ppPAEWContext = (void*)self.savedDevice;
        int iRtn = PAEW_RET_UNKNOWN_FAIL;
        
        iRtn = PAEW_FreeContext(ppPAEWContext);
        if (iRtn != PAEW_RET_SUCCESS) {
            [self printLog:@"PAEW_FreeContext returns failed: %@", [Utils errorCodeToString:iRtn]];
        } else {
            self.savedDevice = NULL;
            [self printLog:@"PAEW_FreeContext returns success"];
        }
    });
}

- (UIButton *)getAddressBtn
{
    if (!_getAddressBtn) {
        _getAddressBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_getAddressBtn setTitle:@"GetAddress" forState:UIControlStateNormal];
        [_getAddressBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        _getAddressBtn.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium];
        [_getAddressBtn setBackgroundColor:[UIColor lightGrayColor]];
        [_getAddressBtn addTarget:self action:@selector(getAddressBtnAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _getAddressBtn;
}

- (UIButton *)getDeviceCheckCodeBtn
{
    if (!_getDeviceCheckCodeBtn) {
        _getDeviceCheckCodeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_getDeviceCheckCodeBtn setTitle:@"DevChkCode" forState:UIControlStateNormal];
        [_getDeviceCheckCodeBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        _getDeviceCheckCodeBtn.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium];
        [_getDeviceCheckCodeBtn setBackgroundColor:[UIColor lightGrayColor]];
        [_getDeviceCheckCodeBtn addTarget:self action:@selector(getDeviceCheckCodeAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _getDeviceCheckCodeBtn;
}

- (void)getDeviceCheckCodeAction
{
    [self printLog:@"ready to call PAEW_GetTradeAddress"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int devIdx = 0;
        void *ppPAEWContext = (void*)self.savedDevice;
        int iRtn = PAEW_RET_UNKNOWN_FAIL;
        unsigned char *pbCheckCode = NULL;
        size_t nAddressLen = 1024;
        
        iRtn = PAEW_GetDeviceCheckCode(ppPAEWContext, devIdx, pbCheckCode, &nAddressLen);
        if (iRtn == PAEW_RET_SUCCESS) {
            pbCheckCode = (unsigned char *)malloc(nAddressLen);
            memset(pbCheckCode, 0, nAddressLen);
            iRtn = PAEW_GetDeviceCheckCode(ppPAEWContext, 0, pbCheckCode, &nAddressLen);
            if (iRtn != PAEW_RET_SUCCESS) {
                
                [self printLog:@"PAEW_GetDeviceCheckCode returns failed: %@", [Utils errorCodeToString:iRtn]];
            } else {
                [self printLog:@"DeviceCheckCode is: %@", [Utils bytesToHexString:pbCheckCode length:nAddressLen]];
                [self printLog:@"PAEW_GetDeviceCheckCode returns success"];
            }
            if (pbCheckCode) {
                free(pbCheckCode);
            }
        } else {
            [self printLog:@"PAEW_GetDeviceCheckCode returns failed: %@", [Utils errorCodeToString:iRtn]];
        }
        
        
    });
}

- (void)getAddressBtnAction
{
    byte coinTypes[] = {PAEW_COIN_TYPE_ETH, PAEW_COIN_TYPE_EOS, PAEW_COIN_TYPE_CYB};
    NSArray *coinNames = @[@"ETH", @"EOS", @"CYB"];
    int selectedCoin = [PickerViewAlert doModal:self title:@"please select coin type:" dataSouce:coinNames];
    if (selectedCoin < 0) {
        return;
    }
    byte coinType = coinTypes[selectedCoin];
    NSString *coinName = coinNames[selectedCoin];
    
    NSArray *showTypeNames = @[@"DO NOT show on screen", @"Show on screen"];
    int selectedType = [PickerViewAlert doModal:self title:@"please select coin type:" dataSouce:showTypeNames];
    if (selectedType < 0) {
        return;
    }
    //0 value for do not show address on device, non zero value for show address on device
    byte showType = (byte)selectedType;
    uint32_t *puiDerivePath;
    size_t derivePathLen;
    switch (coinType) {
        case PAEW_COIN_TYPE_ETH:
            puiDerivePath = puiDerivePathETH;
            derivePathLen = sizeof(puiDerivePathETH)/sizeof(puiDerivePathETH[0]);
            break;
        case PAEW_COIN_TYPE_EOS:
            puiDerivePath = puiDerivePathEOS;
            derivePathLen = sizeof(puiDerivePathEOS)/sizeof(puiDerivePathEOS[0]);
            break;
        case PAEW_COIN_TYPE_CYB:
            puiDerivePath = puiDerivePathCYB;
            derivePathLen = sizeof(puiDerivePathCYB)/sizeof(puiDerivePathCYB[0]);
            break;
        default:
            return;
    }
    
    
    [self printLog:@"ready to call PAEW_GetTradeAddress on %@", coinName];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int devIdx = 0;
        void *ppPAEWContext = (void*)self.savedDevice;
        int iRtn = PAEW_RET_UNKNOWN_FAIL;
        unsigned char bAddress[1024] = {0};
        size_t nAddressLen = 1024;
        
        iRtn = PAEW_DeriveTradeAddress(ppPAEWContext, devIdx, coinType, puiDerivePath, derivePathLen);
        if (iRtn != PAEW_RET_SUCCESS) {
            [self printLog:@"PAEW_GetTradeAddress failed due to PAEW_DeriveTradeAddress on %@ returns : %@", coinName, [Utils errorCodeToString:iRtn]];
        } else {
            iRtn = PAEW_GetTradeAddress_Ex(ppPAEWContext, devIdx, PAEW_COIN_TYPE_ETH, showType, bAddress, &nAddressLen, PutState_Callback, NULL);
            if (iRtn != PAEW_RET_SUCCESS) {
                [self printLog:@"PAEW_GetTradeAddress on %@ failed returns : %@", coinName, [Utils errorCodeToString:iRtn]];
            } else {
                [self printLog:@"PAEW_GetTradeAddress on %@ success, address is %@", coinName, [NSString stringWithUTF8String:(char *)bAddress]];
            }
            if (showType) {
                //0 means logo
                PAEW_ShowImage(ppPAEWContext, devIdx, 0, PAEW_LCD_CLEAR_SHOW_LOGO);
            }
        }
    });
}

- (UIButton *)recoverSeedBtn
{
    if (!_recoverSeedBtn) {
        _recoverSeedBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_recoverSeedBtn setTitle:@"recoverSeed" forState:UIControlStateNormal];
        [_recoverSeedBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        _recoverSeedBtn.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium];
        [_recoverSeedBtn setBackgroundColor:[UIColor lightGrayColor]];
        [_recoverSeedBtn addTarget:self action:@selector(recoverSeedBtnAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _recoverSeedBtn;
}

- (void)recoverSeedBtnAction
{
    //    iRtn = PAEW_RecoverSeedFromMne((const unsigned char *)szMneWord, strlen(szMneWord), pbSeedData, &nSeedLen);

    [self printLog:@"ready to call PAEW_RecoverSeedFromMne"];
    NSString *number = @"mass dust captain baby mass dust captain baby mass dust captain baby mass dust captain baby mass electric";
    [self printLog:@"mnemonics to Recover are: %@", number];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        unsigned char bSeedData[1024] = {0};
        size_t nSeedLen = 64;
        unsigned char bPrivKey[1024] = {0};
        size_t nPrivKeyLen = 1024;
        unsigned char bAddress[1024] = {0};
        size_t nAddressLen = 1024;
        int iRtn = PAEW_RecoverSeedFromMne((const unsigned char *)[number UTF8String], number.length, bSeedData, &nSeedLen);
        if (iRtn != PAEW_RET_SUCCESS) {
            [self printLog:@"PAEW_RecoverSeedFromMne returns failed: %@", [Utils errorCodeToString:iRtn]];
        } else {
            [self printLog:@"seed is: %@", [Utils bytesToHexString:bSeedData length:nSeedLen]];
            [self printLog:@"PAEW_RecoverSeedFromMne returns success"];
            
            iRtn = PAEW_GetTradeAddressFromSeed(bSeedData, nSeedLen, puiDerivePathETH, sizeof(puiDerivePathETH)/sizeof(puiDerivePathETH[0]), bPrivKey, &nPrivKeyLen, 0, PAEW_COIN_TYPE_ETH, bAddress, &nAddressLen);//0 value for do not show address on device, non zero value for show address on device
            if (iRtn != PAEW_RET_SUCCESS) {
                [self printLog:@"PAEW_GetTradeAddressFromSeed on ETH failed returns : %@", [Utils errorCodeToString:iRtn]];
            } else {
                [self printLog:@"PAEW_GetTradeAddressFromSeed on ETH success, address is 0x%@", [NSString stringWithUTF8String:(char *)bAddress]];
            }
            
            nAddressLen = 1024;
            memset(bAddress, 0, 1024);
            nPrivKeyLen = 1024;
            memset(bPrivKey, 0, 1024);
            
            iRtn = PAEW_GetTradeAddressFromSeed(bSeedData, nSeedLen, puiDerivePathEOS, sizeof(puiDerivePathEOS)/sizeof(puiDerivePathEOS[0]), bPrivKey, &nPrivKeyLen, 0, PAEW_COIN_TYPE_EOS, bAddress, &nAddressLen);
            if (iRtn != PAEW_RET_SUCCESS) {
                [self printLog:@"PAEW_GetTradeAddressFromSeed on EOS failed returns : %@", [Utils errorCodeToString:iRtn]];
            } else {
                [self printLog:@"PAEW_GetTradeAddressFromSeed on EOS success, address is %@", [NSString stringWithUTF8String:(char *)bAddress]];
            }
            
//            iRtn = PAEW_DeriveTradeAddress(ppPAEWContext, devIdx, PAEW_COIN_TYPE_EOS, puiDerivePathEOS, sizeof(puiDerivePathEOS)/sizeof(puiDerivePathEOS[0]));
//            if (iRtn != PAEW_RET_SUCCESS) {
//                [self printLog:@"PAEW_GetTradeAddress failed due to PAEW_DeriveTradeAddress on EOS returns : %@", [Utils errorCodeToString:iRtn]];
//            } else {
//                iRtn = PAEW_GetTradeAddress(ppPAEWContext, devIdx, PAEW_COIN_TYPE_EOS, showOnScreen, bAddress, &nAddressLen);
//                if (iRtn != PAEW_RET_SUCCESS) {
//                    [self printLog:@"PAEW_GetTradeAddress on EOS failed returns : %@", [Utils errorCodeToString:iRtn]];
//                } else {
//                    //EOS address format:  Address(ASCII) + '\0' + Signature(Hex)
//                    if (showOnScreen) {
//                        PAEW_ClearLCD(ppPAEWContext, devIdx);
//                    }
//                    size_t addressLen = strlen(bAddress);
//                    NSString *signature = [Utils bytesToHexString:[NSData dataWithBytes:bAddress + addressLen + 1 length:nAddressLen - addressLen - 1] ];
//                    [self printLog:@"PAEW_GetTradeAddress on EOS success, address is %@, signature is: %@", [NSString stringWithUTF8String:(char *)bAddress], signature];
//                }
//            }
            
            nAddressLen = 1024;
            memset(bAddress, 0, 1024);
            nPrivKeyLen = 1024;
            memset(bPrivKey, 0, 1024);
            
            iRtn = PAEW_GetTradeAddressFromSeed(bSeedData, nSeedLen, puiDerivePathCYB, sizeof(puiDerivePathCYB)/sizeof(puiDerivePathCYB[0]), bPrivKey, &nPrivKeyLen, 0, PAEW_COIN_TYPE_CYB, bAddress, &nAddressLen);
            if (iRtn != PAEW_RET_SUCCESS) {
                [self printLog:@"PAEW_GetTradeAddressFromSeed on CYB failed returns : %@", [Utils errorCodeToString:iRtn]];
            } else {
                [self printLog:@"PAEW_GetTradeAddressFromSeed on CYB success, address is %@", [NSString stringWithUTF8String:(char *)bAddress]];
            }
        }
    });
    
}

//- (UIButton *)recoverAddressBtn
//{
//    if (!_recoverAddressBtn) {
//        _recoverAddressBtn = [UIButton buttonWithType:UIButtonTypeCustom];
//        [_recoverAddressBtn setTitle:@"ImportMNE" forState:UIControlStateNormal];
//        [_recoverAddressBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
//        _recoverAddressBtn.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium];
//        [_recoverAddressBtn setBackgroundColor:[UIColor lightGrayColor]];
//        [_recoverAddressBtn addTarget:self action:@selector(recoverAddressBtnAction) forControlEvents:UIControlEventTouchUpInside];
//    }
//    return _importMNEBtn;
//}

- (void)recoverAddressBtnAction
{
    //iRtn = PAEW_GetTradeAddressFromSeed(pbSeed, nSeedLen, puiDerivePath, nDerivePathLen, pbPrivateKey, &nPrivateKeyLen, 0, (const unsigned char)coinType, pbTradeAddress, &nTradeAddressLen);

    [self printLog:@"ready to call PAEW_GetTradeAddressFromSeed"];
    NSString *number = @"mass dust captain baby mass dust captain baby mass dust captain baby mass dust captain baby mass electric";
    [self printLog:@"mnemonics to recover are: %@", number];
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        int devIdx = 0;
//        void *ppPAEWContext = (void*)self.savedDevice;
//        int iRtn = PAEW_RET_UNKNOWN_FAIL;
//        unsigned char seedData[1024] = {0};
//        size_t seedLen = 1024;
//        unsigned char bAddress[1024] = {0};
//        size_t nAddressLen = 1024;
//
//        iRtn = PAEW_GetTradeAddressFromSeed(seedData, seedLen, PAEW_COIN_TYPE_ETH, puiDerivePathETH, sizeof(puiDerivePathETH)/sizeof(puiDerivePathETH[0]));
//        unsigned char showOnScreen = 1;//0 value for do not show address on device, non zero value for show address on device
//        if (iRtn != PAEW_RET_SUCCESS) {
//            [self printLog:@"PAEW_GetTradeAddress failed due to PAEW_DeriveTradeAddress on ETH returns : %@", [Utils errorCodeToString:iRtn]];
//        } else {
//            iRtn = PAEW_GetTradeAddress(ppPAEWContext, devIdx, PAEW_COIN_TYPE_ETH, showOnScreen, bAddress, &nAddressLen);
//            if (iRtn != PAEW_RET_SUCCESS) {
//                [self printLog:@"PAEW_GetTradeAddress on ETH failed returns : %@", [Utils errorCodeToString:iRtn]];
//            } else {
//                //returned address is hex string only, so we should add '0x' at the begining manually
//                if (showOnScreen) {
//                    PAEW_ClearLCD(ppPAEWContext, devIdx);
//                }
//                [self printLog:@"PAEW_GetTradeAddress on ETH success, address is 0x%@", [NSString stringWithUTF8String:(char *)bAddress]];
//            }
//        }
//
//        nAddressLen = 1024;
//        memset(bAddress, 0, 1024);
//
//        iRtn = PAEW_DeriveTradeAddress(ppPAEWContext, devIdx, PAEW_COIN_TYPE_EOS, puiDerivePathEOS, sizeof(puiDerivePathEOS)/sizeof(puiDerivePathEOS[0]));
//        if (iRtn != PAEW_RET_SUCCESS) {
//            [self printLog:@"PAEW_GetTradeAddress failed due to PAEW_DeriveTradeAddress on EOS returns : %@", [Utils errorCodeToString:iRtn]];
//        } else {
//            iRtn = PAEW_GetTradeAddress(ppPAEWContext, devIdx, PAEW_COIN_TYPE_EOS, showOnScreen, bAddress, &nAddressLen);
//            if (iRtn != PAEW_RET_SUCCESS) {
//                [self printLog:@"PAEW_GetTradeAddress on EOS failed returns : %@", [Utils errorCodeToString:iRtn]];
//            } else {
//                //EOS address format:  Address(ASCII) + '\0' + Signature(Hex)
//                if (showOnScreen) {
//                    PAEW_ClearLCD(ppPAEWContext, devIdx);
//                }
//                size_t addressLen = strlen(bAddress);
//                NSString *signature = [Utils bytesToHexString:[NSData dataWithBytes:bAddress + addressLen + 1 length:nAddressLen - addressLen - 1] ];
//                [self printLog:@"PAEW_GetTradeAddress on EOS success, address is %@, signature is: %@", [NSString stringWithUTF8String:(char *)bAddress], signature];
//            }
//        }
//
//        nAddressLen = 1024;
//        memset(bAddress, 0, 1024);
//
//        iRtn = PAEW_DeriveTradeAddress(ppPAEWContext, devIdx, PAEW_COIN_TYPE_CYB, puiDerivePathCYB, sizeof(puiDerivePathEOS)/sizeof(puiDerivePathEOS[0]));
//        if (iRtn != PAEW_RET_SUCCESS) {
//            [self printLog:@"PAEW_GetTradeAddress failed due to PAEW_DeriveTradeAddress on CYB returns : %@", [Utils errorCodeToString:iRtn]];
//        } else {
//            iRtn = PAEW_GetTradeAddress(ppPAEWContext, devIdx, PAEW_COIN_TYPE_CYB, showOnScreen, bAddress, &nAddressLen);
//            if (iRtn != PAEW_RET_SUCCESS) {
//                [self printLog:@"PAEW_GetTradeAddress on CYB failed returns : %@", [Utils errorCodeToString:iRtn]];
//            } else {
//                if (showOnScreen) {
//                    PAEW_ClearLCD(ppPAEWContext, devIdx);
//                }
//                [self printLog:@"PAEW_GetTradeAddress on CYB success, address is %@", [NSString stringWithUTF8String:(char *)bAddress]];
//            }
//        }
    });
    
}

- (UIButton *)importMNEBtn
{
    if (!_importMNEBtn) {
        _importMNEBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_importMNEBtn setTitle:@"ImportMNE" forState:UIControlStateNormal];
        [_importMNEBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        _importMNEBtn.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium];
        [_importMNEBtn setBackgroundColor:[UIColor lightGrayColor]];
        [_importMNEBtn addTarget:self action:@selector(importMNEBtnAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _importMNEBtn;
}

- (void)importMNEBtnAction
{
    [self printLog:@"ready to call PAEW_ImportSeed"];
    NSString *number = @"mass dust captain baby mass dust captain baby mass dust captain baby mass dust captain baby mass electric";
    [self printLog:@"mnemonics to import are: %@", number];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int devIdx = 0;
        void *ppPAEWContext = (void*)self.savedDevice;
        
        int iRtn = PAEW_ImportSeed(ppPAEWContext, devIdx, (const unsigned char *)[number UTF8String], number.length);
        if (iRtn != PAEW_RET_SUCCESS) {
            [self printLog:@"PAEW_ImportSeed returns failed: %@", [Utils errorCodeToString:iRtn]];
        } else {
            [self printLog:@"PAEW_ImportSeed returns success"];
        }
    });
    
}

- (UIButton *)ETHSignBtn
{
    if (!_ETHSignBtn) {
        _ETHSignBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_ETHSignBtn setTitle:@"ETHSign" forState:UIControlStateNormal];
        [_ETHSignBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        _ETHSignBtn.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium];
        [_ETHSignBtn setBackgroundColor:[UIColor lightGrayColor]];
        [_ETHSignBtn addTarget:self action:@selector(ETHSignBtnAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _ETHSignBtn;
}

- (UIButton *)EOSSignBtn
{
    if (!_EOSSignBtn) {
        _EOSSignBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_EOSSignBtn setTitle:@"EOSSign" forState:UIControlStateNormal];
        [_EOSSignBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        _EOSSignBtn.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium];
        [_EOSSignBtn setBackgroundColor:[UIColor lightGrayColor]];
        [_EOSSignBtn addTarget:self action:@selector(EOSSignBtnAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _EOSSignBtn;
}

- (UIButton *)CYBSignBtn
{
    if (!_CYBSignBtn) {
        _CYBSignBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_CYBSignBtn setTitle:@"CYBSign" forState:UIControlStateNormal];
        [_CYBSignBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        _CYBSignBtn.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium];
        [_CYBSignBtn setBackgroundColor:[UIColor lightGrayColor]];
        [_CYBSignBtn addTarget:self action:@selector(CYBSignBtnAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _CYBSignBtn;
}

- (UIButton *)ETHSignNewBtn
{
    if (!_ETHSignNewBtn) {
        _ETHSignNewBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_ETHSignNewBtn setTitle:@"ETHSignNew" forState:UIControlStateNormal];
        [_ETHSignNewBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        _ETHSignNewBtn.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium];
        [_ETHSignNewBtn setBackgroundColor:[UIColor lightGrayColor]];
        [_ETHSignNewBtn addTarget:self action:@selector(ETHSignNewBtnAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _ETHSignNewBtn;
}

- (UIButton *)EOSSignNewBtn
{
    if (!_EOSSignNewBtn) {
        _EOSSignNewBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_EOSSignNewBtn setTitle:@"EOSSignNew" forState:UIControlStateNormal];
        [_EOSSignNewBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        _EOSSignNewBtn.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium];
        [_EOSSignNewBtn setBackgroundColor:[UIColor lightGrayColor]];
        [_EOSSignNewBtn addTarget:self action:@selector(EOSSignNewBtnAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _EOSSignNewBtn;
}

- (UIButton *)CYBSignNewBtn
{
    if (!_CYBSignNewBtn) {
        _CYBSignNewBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_CYBSignNewBtn setTitle:@"CYBSignNew" forState:UIControlStateNormal];
        [_CYBSignNewBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        _CYBSignNewBtn.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium];
        [_CYBSignNewBtn setBackgroundColor:[UIColor lightGrayColor]];
        [_CYBSignNewBtn addTarget:self action:@selector(CYBSignNewBtnAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _CYBSignNewBtn;
}

- (UIButton *)SwitchSignBtn
{
    if (!_SwitchSignBtn) {
        _SwitchSignBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_SwitchSignBtn setTitle:@"SwitchSignMethod" forState:UIControlStateNormal];
        [_SwitchSignBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        _SwitchSignBtn.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium];
        [_SwitchSignBtn setBackgroundColor:[UIColor lightGrayColor]];
        [_SwitchSignBtn addTarget:self action:@selector(SwitchSignBtnAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _SwitchSignBtn;
}

- (void)SwitchSignBtnAction
{
    self.switchSignFlag = YES;
}

- (void)signAbortBtnAction
{
    self.abortSignFlag = YES;
}

- (void)ETHSignNewBtnAction
{
    self.switchSignFlag = NO;
    self.abortSignFlag = NO;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int devIdx = 0;
        void *ppPAEWContext = (void*)self.savedDevice;
        int iRtn = PAEW_RET_UNKNOWN_FAIL;
        unsigned char nCoinType = PAEW_COIN_TYPE_ETH;
        uint32_t puiDerivePath[] = {0, 0x8000002c, 0x8000003c, 0x80000000, 0x00000000, 0x00000000};
        [self printLog:@"ready for eth signature"];
        iRtn = PAEW_DeriveTradeAddress(ppPAEWContext, devIdx, nCoinType, puiDerivePath, sizeof(puiDerivePath)/sizeof(puiDerivePath[0]));
        if (iRtn != PAEW_RET_SUCCESS) {
            [self printLog:@"eth signature failed due to PAEW_DeriveTradeAddress returns : %@", [Utils errorCodeToString:iRtn]];
            return ;
        }
        
        unsigned char transaction[] = { 0xec,  0x09,  0x85,  0x04,  0xa8,  0x17,  0xc8,  0x00,  0x82,  0x52,  0x08,  0x94,  0x35,  0x35,  0x35,  0x35,  0x35,  0x35,  0x35,  0x35,  0x35,  0x35,  0x35,  0x35,  0x35,  0x35,  0x35,  0x35,  0x35,  0x35,  0x35,  0x35,  0x88,  0x0d,  0xe0,  0xb6,  0xb3,  0xa7,  0x64,  0x00,  0x00,  0x80,  0x01,  0x80,  0x80};
        unsigned char pbTXSig[1024] = {0};
        size_t pnTXSigLen = 1024;
        BOOL pinVerified = NO;
        unsigned char authType = PAEW_SIGN_AUTH_TYPE_FP;
        
        iRtn = PAEW_ETH_SetTX(ppPAEWContext, devIdx, transaction, sizeof(transaction));
        if (iRtn != PAEW_RET_SUCCESS) {
            [self printLog:@"eth signature failed due to PAEW_CYB_SetTX returns :", [Utils errorCodeToString:iRtn]];
            return;
        }
        
        int lastResult = PAEW_RET_SUCCESS;
        unsigned char lastAuthType = authType;
        BOOL needAbort = NO;
        [self printLog:@"default auth type: %@", (authType == PAEW_SIGN_AUTH_TYPE_FP ? @"Fingerprint" : @"PIN")];
        while (YES) {
            //check abort sign flag
            if (self.abortSignFlag) {
                self.abortSignFlag = NO;
                iRtn = PAEW_AbortSign(ppPAEWContext, devIdx);
                if (iRtn == PAEW_RET_SUCCESS) {
                    [self printLog: @"eth signature abort"];
                    needAbort = false;
                    break;
                } else {
                    [self printLog:@"PAEW_AbortSign returns failed: %@", [Utils errorCodeToString:iRtn]];
                    needAbort = true;
                    break;
                }
            }
            
            //check switch sign flag
            if (self.switchSignFlag) {
                self.switchSignFlag = false;
                if (authType == PAEW_SIGN_AUTH_TYPE_FP) {
                    authType = PAEW_SIGN_AUTH_TYPE_PIN;
                } else if (authType == PAEW_SIGN_AUTH_TYPE_PIN) {
                    authType = PAEW_SIGN_AUTH_TYPE_FP;
                }
                //clear last getsign result
                lastResult = PAEW_RET_SUCCESS;
                pinVerified = NO;
            }
            if (lastAuthType != authType) {
                if (authType != PAEW_SIGN_AUTH_TYPE_FP && authType != PAEW_SIGN_AUTH_TYPE_PIN)  {
                    int type = [PickerViewAlert doModal:self title:@"Please select verify method" dataSouce:@[@"Fingerprint", @"PIN"]];
                    if (type < 0) {
                        [self printLog:@"user cancelled"];
                        needAbort = true;
                        break;
                    }
                    authType = type == 0 ? PAEW_SIGN_AUTH_TYPE_FP : PAEW_SIGN_AUTH_TYPE_PIN;
                }
                lastAuthType = authType;
                [self printLog:@"auth type changed, current auth type: %@", (authType == PAEW_SIGN_AUTH_TYPE_FP ? @"Fingerprint" : @"PIN")];
                iRtn = PAEW_SwitchSign(ppPAEWContext, devIdx);
            }
            //if auth type is PIN, PAEW_VerifySignPIN must be called
            if ((authType == PAEW_SIGN_AUTH_TYPE_PIN) && (!pinVerified)) {
                NSString *pin = [TextFieldViewAlert doModal:self title:@"Please input PIN" message:@"Please input your PIN to continue" isPassword:YES minLengthRequired:6 keyboardType:UIKeyboardTypeNumberPad];
                if (!pin) {
                    authType = PAEW_SIGN_AUTH_TYPE_FP;
                    pinVerified = NO;
                    [self printLog:@"user canceled PIN input"];
                    continue;
                }
                iRtn = PAEW_VerifySignPIN(ppPAEWContext, devIdx, [pin cStringUsingEncoding:NSUTF8StringEncoding]);
                if (iRtn != PAEW_RET_SUCCESS) {
                    pinVerified = false;
                    [self printLog:@"PAEW_VerifySignPIN returns failed: %@", [Utils errorCodeToString:iRtn]];
                    continue;
                }
                pinVerified = YES;
            }
            //after all, loop to get sign result
            iRtn = PAEW_ETH_GetSignResult(ppPAEWContext, devIdx, authType, pbTXSig, &pnTXSigLen);
            
            if (iRtn == PAEW_RET_SUCCESS) {
                [self printLog:@"eth signature succeeded with signature: %@", [Utils bytesToHexString:pbTXSig length:pnTXSigLen]];
                needAbort = false;
                break;
            } else if (lastResult != iRtn) {
                [self printLog:@"%@ signature status : %@", (authType == PAEW_SIGN_AUTH_TYPE_FP ? @"Fingerprint" : @"PIN"), [Utils errorCodeToString:iRtn]];
                lastResult = iRtn;
                //notify here: loop for pin and loop for fp have different loop conditions
                if (authType == PAEW_SIGN_AUTH_TYPE_FP) {
                    if (lastResult == PAEW_RET_NO_VERIFY_COUNT) {
                        //like wechat, if fp verify count ran out, switch to pin verify
                        self.switchSignFlag = true;
                        continue;
                    }
                    if (lastResult != PAEW_RET_DEV_WAITING
                        && lastResult != PAEW_RET_DEV_FP_COMMON_ERROR
                        && lastResult != PAEW_RET_DEV_FP_NO_FINGER
                        && lastResult != PAEW_RET_DEV_FP_NOT_FULL_FINGER) {
                        [self printLog:@"eth signature failed" ];
                        needAbort = true;
                        break;
                    }
                } else if (authType == PAEW_SIGN_AUTH_TYPE_PIN) {
                    if (lastResult != PAEW_RET_DEV_WAITING) {
                        [self printLog:@"eth signature failed" ];
                        needAbort = true;
                        break;
                    }
                }
            }
            
            //finally, call abort if PAEW_ETH_GetSignResult returns non PAEW_RET_SUCCESS values
            if (needAbort) {
                iRtn = PAEW_AbortSign(ppPAEWContext, devIdx);
            }
        }
    });
}

- (void)EOSSignNewBtnAction
{
    self.switchSignFlag = NO;
    self.abortSignFlag = NO;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int devIdx = 0;
        void *ppPAEWContext = (void*)self.savedDevice;
        int iRtn = PAEW_RET_UNKNOWN_FAIL;
        unsigned char nCoinType = PAEW_COIN_TYPE_EOS;
        uint32_t puiDerivePath[] = {0, 0x8000002C, 0x800000c2, 0x80000000, 0x00000000, 0x00000000};
        [self printLog:@"ready for eos signature"];
        iRtn = PAEW_DeriveTradeAddress(ppPAEWContext, devIdx, nCoinType, puiDerivePath, sizeof(puiDerivePath)/sizeof(puiDerivePath[0]));
        if (iRtn != PAEW_RET_SUCCESS) {
            [self printLog:@"eos signature failed due to PAEW_DeriveTradeAddress returns : %@", [Utils errorCodeToString:iRtn]];
            return ;
        }
        
        unsigned char transaction[] = {0x74, 0x09, 0x70, 0xd9, 0xff, 0x01, 0xb5, 0x04, 0x63, 0x2f, 0xed, 0xe1, 0xad, 0xc3, 0xdf, 0xe5, 0x59, 0x90, 0x41, 0x5e, 0x4f, 0xde, 0x01, 0xe1, 0xb8, 0xf3, 0x15, 0xf8, 0x13, 0x6f, 0x47, 0x6c, 0x14, 0xc2, 0x67, 0x5b, 0x01, 0x24, 0x5f, 0x70, 0x5d, 0xd7, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0xa6, 0x82, 0x34, 0x03, 0xea, 0x30, 0x55, 0x00, 0x00, 0x00, 0x57, 0x2d, 0x3c, 0xcd, 0xcd, 0x01, 0x20, 0x29, 0xc2, 0xca, 0x55, 0x7a, 0x73, 0x57, 0x00, 0x00, 0x00, 0x00, 0xa8, 0xed, 0x32, 0x32, 0x21, 0x20, 0x29, 0xc2, 0xca, 0x55, 0x7a, 0x73, 0x57, 0x90, 0x55, 0x8c, 0x86, 0x77, 0x95, 0x4c, 0x3c, 0x10, 0x27, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x04, 0x45, 0x4f, 0x53, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
        unsigned char pbTXSig[1024] = {0};
        size_t pnTXSigLen = 1024;
        BOOL pinVerified = NO;
        unsigned char authType = PAEW_SIGN_AUTH_TYPE_FP;
        
        iRtn = PAEW_EOS_SetTX(ppPAEWContext, devIdx, transaction, sizeof(transaction));
        if (iRtn != PAEW_RET_SUCCESS) {
            [self printLog:@"eos signature failed due to PAEW_EOS_SetTX returns :", [Utils errorCodeToString:iRtn]];
            return;
        }
        
        int lastResult = PAEW_RET_SUCCESS;
        unsigned char lastAuthType = authType;
        BOOL needAbort = NO;
        [self printLog:@"default auth type: %@", (authType == PAEW_SIGN_AUTH_TYPE_FP ? @"Fingerprint" : @"PIN")];
        while (YES) {
            //check abort sign flag
            if (self.abortSignFlag) {
                self.abortSignFlag = NO;
                iRtn = PAEW_AbortSign(ppPAEWContext, devIdx);
                if (iRtn == PAEW_RET_SUCCESS) {
                    [self printLog: @"eos signature abort"];
                    needAbort = false;
                    break;
                } else {
                    [self printLog:@"PAEW_AbortSign returns failed: %@", [Utils errorCodeToString:iRtn]];
                    needAbort = true;
                    break;
                }
            }
            
            //check switch sign flag
            if (self.switchSignFlag) {
                self.switchSignFlag = false;
                if (authType == PAEW_SIGN_AUTH_TYPE_FP) {
                    authType = PAEW_SIGN_AUTH_TYPE_PIN;
                } else if (authType == PAEW_SIGN_AUTH_TYPE_PIN) {
                    authType = PAEW_SIGN_AUTH_TYPE_FP;
                }
                //clear last getsign result
                lastResult = PAEW_RET_SUCCESS;
                pinVerified = NO;
            }
            if (lastAuthType != authType) {
                if (authType != PAEW_SIGN_AUTH_TYPE_FP && authType != PAEW_SIGN_AUTH_TYPE_PIN)  {
                    int type = [PickerViewAlert doModal:self title:@"Please select verify method" dataSouce:@[@"Fingerprint", @"PIN"]];
                    if (type < 0) {
                        [self printLog:@"user cancelled"];
                        needAbort = true;
                        break;
                    }
                    authType = type == 0 ? PAEW_SIGN_AUTH_TYPE_FP : PAEW_SIGN_AUTH_TYPE_PIN;
                }
                lastAuthType = authType;
                [self printLog:@"auth type changed, current auth type: %@", (authType == PAEW_SIGN_AUTH_TYPE_FP ? @"Fingerprint" : @"PIN")];
                iRtn = PAEW_SwitchSign(ppPAEWContext, devIdx);
            }
            //if auth type is PIN, PAEW_VerifySignPIN must be called
            if ((authType == PAEW_SIGN_AUTH_TYPE_PIN) && (!pinVerified)) {
                NSString *pin = [TextFieldViewAlert doModal:self title:@"Please input PIN" message:@"Please input your PIN to continue" isPassword:YES minLengthRequired:6 keyboardType:UIKeyboardTypeNumberPad];
                if (!pin) {
                    authType = PAEW_SIGN_AUTH_TYPE_FP;
                    pinVerified = NO;
                    [self printLog:@"user canceled PIN input"];
                    continue;
                }
                iRtn = PAEW_VerifySignPIN(ppPAEWContext, devIdx, [pin cStringUsingEncoding:NSUTF8StringEncoding]);
                if (iRtn != PAEW_RET_SUCCESS) {
                    pinVerified = false;
                    [self printLog:@"PAEW_VerifySignPIN returns failed: %@", [Utils errorCodeToString:iRtn]];
                    continue;
                }
                pinVerified = YES;
            }
            //after all, loop to get sign result
            iRtn = PAEW_EOS_GetSignResult(ppPAEWContext, devIdx, authType, pbTXSig, &pnTXSigLen);
            
            if (iRtn == PAEW_RET_SUCCESS) {
                [self printLog:@"eos signature succeeded with signature: %s", pbTXSig];
                needAbort = false;
                break;
            } else if (lastResult != iRtn) {
                [self printLog:@"%@ signature status : %@", (authType == PAEW_SIGN_AUTH_TYPE_FP ? @"Fingerprint" : @"PIN"), [Utils errorCodeToString:iRtn]];
                lastResult = iRtn;
                //notify here: loop for pin and loop for fp have different loop conditions
                if (authType == PAEW_SIGN_AUTH_TYPE_FP) {
                    if (lastResult == PAEW_RET_NO_VERIFY_COUNT) {
                        //like wechat, if fp verify count ran out, switch to pin verify
                        self.switchSignFlag = true;
                        continue;
                    }
                    if (lastResult != PAEW_RET_DEV_WAITING
                        && lastResult != PAEW_RET_DEV_FP_COMMON_ERROR
                        && lastResult != PAEW_RET_DEV_FP_NO_FINGER
                        && lastResult != PAEW_RET_DEV_FP_NOT_FULL_FINGER) {
                        [self printLog:@"eos signature failed" ];
                        needAbort = true;
                        break;
                    }
                } else if (authType == PAEW_SIGN_AUTH_TYPE_PIN) {
                    if (lastResult != PAEW_RET_DEV_WAITING) {
                        [self printLog:@"eos signature failed" ];
                        needAbort = true;
                        break;
                    }
                }
            }
            
            //finally, call abort if PAEW_EOS_GetSignResult returns non PAEW_RET_SUCCESS values
            if (needAbort) {
                iRtn = PAEW_AbortSign(ppPAEWContext, devIdx);
            }
        }
    });
}

- (void)CYBSignNewBtnAction
{
    self.switchSignFlag = NO;
    self.abortSignFlag = NO;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int devIdx = 0;
        void *ppPAEWContext = (void*)self.savedDevice;
        int iRtn = PAEW_RET_UNKNOWN_FAIL;
        unsigned char nCoinType = PAEW_COIN_TYPE_CYB;
        uint32_t puiDerivePath[] = {0, 0, 1, 0x00000080, 0x00000000, 0x00000000};
        [self printLog:@"ready for cyb signature"];
        iRtn = PAEW_DeriveTradeAddress(ppPAEWContext, devIdx, nCoinType, puiDerivePath, sizeof(puiDerivePath)/sizeof(puiDerivePath[0]));
        if (iRtn != PAEW_RET_SUCCESS) {
            [self printLog:@"cyb signature failed due to PAEW_DeriveTradeAddress returns : %@", [Utils errorCodeToString:iRtn]];
            return ;
        }
        
        unsigned char transaction[] = {0x26,0xe9,
            0xbf,0x22,0x06,0xa1,
            0xd1,0x5c,0x7e,0x5b,
            0x01,0x00,
            0xe8,0x03,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
            0x80,0xaf,0x02,
            0x80,0xaf,0x02,
            0x0a,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
            0x00,
            0x01,0x04,
            0x0a,0x7a,0x68,0x61,0x6e,0x67,0x73,0x79,0x31,0x33,0x33,
            0x03,0x43,0x59,0x42,
            0x03,0x43,0x59,0x42,
            0x05,
            0x05,
            0x00};
        unsigned char pbTXSig[1024] = {0};
        size_t pnTXSigLen = 1024;
        BOOL pinVerified = NO;
        unsigned char authType = PAEW_SIGN_AUTH_TYPE_FP;
        
        iRtn = PAEW_CYB_SetTX(ppPAEWContext, devIdx, transaction, sizeof(transaction));
        if (iRtn != PAEW_RET_SUCCESS) {
            [self printLog:@"cyb signature failed due to PAEW_CYB_SetTX returns :", [Utils errorCodeToString:iRtn]];
            return;
        }
        
        int lastResult = PAEW_RET_SUCCESS;
        unsigned char lastAuthType = authType;
        BOOL needAbort = NO;
        [self printLog:@"default auth type: %@", (authType == PAEW_SIGN_AUTH_TYPE_FP ? @"Fingerprint" : @"PIN")];
        while (YES) {
            //check abort sign flag
            if (self.abortSignFlag) {
                self.abortSignFlag = NO;
                iRtn = PAEW_AbortSign(ppPAEWContext, devIdx);
                if (iRtn == PAEW_RET_SUCCESS) {
                    [self printLog: @"cyb signature abort"];
                    needAbort = false;
                    break;
                } else {
                    [self printLog:@"PAEW_AbortSign returns failed: %@", [Utils errorCodeToString:iRtn]];
                    needAbort = true;
                    break;
                }
            }
            
            //check switch sign flag
            if (self.switchSignFlag) {
                self.switchSignFlag = false;
                if (authType == PAEW_SIGN_AUTH_TYPE_FP) {
                    authType = PAEW_SIGN_AUTH_TYPE_PIN;
                } else if (authType == PAEW_SIGN_AUTH_TYPE_PIN) {
                    authType = PAEW_SIGN_AUTH_TYPE_FP;
                }
                //clear last getsign result
                lastResult = PAEW_RET_SUCCESS;
                pinVerified = NO;
            }
            if (lastAuthType != authType) {
                if (authType != PAEW_SIGN_AUTH_TYPE_FP && authType != PAEW_SIGN_AUTH_TYPE_PIN)  {
                    int type = [PickerViewAlert doModal:self title:@"Please select verify method" dataSouce:@[@"Fingerprint", @"PIN"]];
                    if (type < 0) {
                        [self printLog:@"user cancelled"];
                        needAbort = true;
                        break;
                    }
                    authType = type == 0 ? PAEW_SIGN_AUTH_TYPE_FP : PAEW_SIGN_AUTH_TYPE_PIN;
                }
                lastAuthType = authType;
                [self printLog:@"auth type changed, current auth type: %@", (authType == PAEW_SIGN_AUTH_TYPE_FP ? @"Fingerprint" : @"PIN")];
                iRtn = PAEW_SwitchSign(ppPAEWContext, devIdx);
            }
            //if auth type is PIN, PAEW_VerifySignPIN must be called
            if ((authType == PAEW_SIGN_AUTH_TYPE_PIN) && (!pinVerified)) {
                NSString *pin = [TextFieldViewAlert doModal:self title:@"Please input PIN" message:@"Please input your PIN to continue" isPassword:YES minLengthRequired:6 keyboardType:UIKeyboardTypeNumberPad];
                if (!pin) {
                    authType = PAEW_SIGN_AUTH_TYPE_FP;
                    pinVerified = NO;
                    [self printLog:@"user canceled PIN input"];
                    continue;
                }
                iRtn = PAEW_VerifySignPIN(ppPAEWContext, devIdx, [pin cStringUsingEncoding:NSUTF8StringEncoding]);
                if (iRtn != PAEW_RET_SUCCESS) {
                    pinVerified = false;
                    [self printLog:@"PAEW_VerifySignPIN returns failed: %@", [Utils errorCodeToString:iRtn]];
                    continue;
                }
                pinVerified = YES;
            }
            //after all, loop to get sign result
            iRtn = PAEW_CYB_GetSignResult(ppPAEWContext, devIdx, authType, pbTXSig, &pnTXSigLen);
            
            if (iRtn == PAEW_RET_SUCCESS) {
                [self printLog:@"CYB signature succeeded with signature: %@", [Utils bytesToHexString:pbTXSig length:pnTXSigLen]];
                needAbort = false;
                break;
            } else if (lastResult != iRtn) {
                [self printLog:@"%@ signature status : %@", (authType == PAEW_SIGN_AUTH_TYPE_FP ? @"Fingerprint" : @"PIN"), [Utils errorCodeToString:iRtn]];
                lastResult = iRtn;
                //notify here: loop for pin and loop for fp have different loop conditions
                if (authType == PAEW_SIGN_AUTH_TYPE_FP) {
                    if (lastResult == PAEW_RET_NO_VERIFY_COUNT) {
                        //like wechat, if fp verify count ran out, switch to pin verify
                        self.switchSignFlag = true;
                        continue;
                    }
                    if (lastResult != PAEW_RET_DEV_WAITING
                        && lastResult != PAEW_RET_DEV_FP_COMMON_ERROR
                        && lastResult != PAEW_RET_DEV_FP_NO_FINGER
                        && lastResult != PAEW_RET_DEV_FP_NOT_FULL_FINGER) {
                        [self printLog:@"CYB signature failed" ];
                        needAbort = true;
                        break;
                    }
                } else if (authType == PAEW_SIGN_AUTH_TYPE_PIN) {
                    if (lastResult != PAEW_RET_DEV_WAITING) {
                        [self printLog:@"CYB signature failed" ];
                        needAbort = true;
                        break;
                    }
                }
            }
            
            //finally, call abort if PAEW_CYB_GetSignResult returns non PAEW_RET_SUCCESS values
            if (needAbort) {
                iRtn = PAEW_AbortSign(ppPAEWContext, devIdx);
            }
        }
    });
}

//This method is deprecated, keep it only for compatible with old cards
//Please refer to CYBSignNewBtnAction implementation to sign in a recommended procedure
- (void)CYBSignBtnAction
{
    [self printLog:@"ready to call PAEW_CYB_TXSign_Ex"];
    int rtn = [self getAuthType];
    if (rtn != PAEW_RET_SUCCESS) {
        [self printLog:@"user canceled PAEW_CYB_TXSign_Ex"];
        return;
    }
    if (self->nAuthType == PAEW_SIGN_AUTH_TYPE_PIN) {
        rtn = [self getPIN];
        if (rtn != PAEW_RET_SUCCESS) {
            [self printLog:@"user canceled PAEW_CYB_TXSign_Ex"];
            return;
        }
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int devIdx = 0;
        void *ppPAEWContext = (void*)self.savedDevice;
        int iRtn = PAEW_RET_UNKNOWN_FAIL;
        unsigned char nCoinType = PAEW_COIN_TYPE_CYB;
        uint32_t puiDerivePath[] = {0, 0, 1, 0x00000080, 0x00000000, 0x00000000};
        iRtn = PAEW_DeriveTradeAddress(ppPAEWContext, devIdx, nCoinType, puiDerivePath, sizeof(puiDerivePath)/sizeof(puiDerivePath[0]));
        if (iRtn != PAEW_RET_SUCCESS) {
            [self printLog:@"PAEW_CYB_TXSign_Ex failed due to PAEW_DeriveTradeAddress returns : %@", [Utils errorCodeToString:iRtn]];
            return ;
        }
        
        unsigned char transaction[] = {0x26,0xe9,
            0xbf,0x22,0x06,0xa1,
            0xd1,0x5c,0x7e,0x5b,
            0x01,0x00,
            0xe8,0x03,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
            0x80,0xaf,0x02,
            0x80,0xaf,0x02,
            0x0a,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
            0x00,
            0x01,0x04,
            0x0a,0x7a,0x68,0x61,0x6e,0x67,0x73,0x79,0x31,0x33,0x33,
            0x03,0x43,0x59,0x42,
            0x03,0x43,0x59,0x42,
            0x05,
            0x05,
            0x00};
        unsigned char *pbTXSig = (unsigned char *)malloc(1024);
        size_t pnTXSigLen = 1024;
        signCallbacks callBack;
        callBack.getAuthType = GetAuthType;
        callBack.getPIN = GetPin;
        callBack.putSignState = PutSignState;
        selfClass->lastSignState = PAEW_RET_SUCCESS;
        //This method is deprecated, keep it only for compatible with old card
        iRtn = PAEW_CYB_TXSign_Ex(ppPAEWContext, devIdx, transaction, sizeof(transaction), pbTXSig, &pnTXSigLen, &callBack, 0);
        if (iRtn) {
            [self printLog:@"PAEW_CYB_TXSign_Ex returns failed: %@", [Utils errorCodeToString:iRtn]];
            return ;
        }
        [self printLog:@"CYB signature is: %@", [Utils bytesToHexString:[NSData dataWithBytes:pbTXSig length:pnTXSigLen]]];
        [self printLog:@"PAEW_CYB_TXSign_Ex returns success"];
    });
}

//This method is deprecated, keep it only for compatible with old cards
//Please refer to EOSSignNewBtnAction implementation to sign in a recommended procedure
- (void)EOSSignBtnAction
{
    [self printLog:@"ready to call PAEW_EOS_TXSign_Ex"];
    int rtn = [self getAuthType];
    if (rtn != PAEW_RET_SUCCESS) {
        [self printLog:@"user canceled PAEW_EOS_TXSign_Ex"];
        return;
    }
    if (self->nAuthType == PAEW_SIGN_AUTH_TYPE_PIN) {
        rtn = [self getPIN];
        if (rtn != PAEW_RET_SUCCESS) {
            [self printLog:@"user canceled PAEW_EOS_TXSign_Ex"];
            return;
        }
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int devIdx = 0;
        void *ppPAEWContext = (void*)self.savedDevice;
        int iRtn = PAEW_RET_UNKNOWN_FAIL;
        unsigned char nCoinType = PAEW_COIN_TYPE_EOS;
        uint32_t puiDerivePath[] = {0, 0x8000002C, 0x800000c2, 0x80000000, 0x00000000, 0x00000000};
        iRtn = PAEW_DeriveTradeAddress(ppPAEWContext, devIdx, nCoinType, puiDerivePath, sizeof(puiDerivePath)/sizeof(puiDerivePath[0]));
        if (iRtn != PAEW_RET_SUCCESS) {
            [self printLog:@"PAEW_EOS_TXSign_Ex failed due to PAEW_DeriveTradeAddress returns : %@", [Utils errorCodeToString:iRtn]];
            return ;
        }
        
        unsigned char transaction[] = {0x74, 0x09, 0x70, 0xd9, 0xff, 0x01, 0xb5, 0x04, 0x63, 0x2f, 0xed, 0xe1, 0xad, 0xc3, 0xdf, 0xe5, 0x59, 0x90, 0x41, 0x5e, 0x4f, 0xde, 0x01, 0xe1, 0xb8, 0xf3, 0x15, 0xf8, 0x13, 0x6f, 0x47, 0x6c, 0x14, 0xc2, 0x67, 0x5b, 0x01, 0x24, 0x5f, 0x70, 0x5d, 0xd7, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0xa6, 0x82, 0x34, 0x03, 0xea, 0x30, 0x55, 0x00, 0x00, 0x00, 0x57, 0x2d, 0x3c, 0xcd, 0xcd, 0x01, 0x20, 0x29, 0xc2, 0xca, 0x55, 0x7a, 0x73, 0x57, 0x00, 0x00, 0x00, 0x00, 0xa8, 0xed, 0x32, 0x32, 0x21, 0x20, 0x29, 0xc2, 0xca, 0x55, 0x7a, 0x73, 0x57, 0x90, 0x55, 0x8c, 0x86, 0x77, 0x95, 0x4c, 0x3c, 0x10, 0x27, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x04, 0x45, 0x4f, 0x53, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
        unsigned char *pbTXSig = (unsigned char *)malloc(1024);
        size_t pnTXSigLen = 1024;
        signCallbacks callBack;
        callBack.getAuthType = GetAuthType;
        callBack.getPIN = GetPin;
        callBack.putSignState = PutSignState;
        selfClass->lastSignState = PAEW_RET_SUCCESS;
        //This method is deprecated, keep it only for compatible with old cards
        iRtn = PAEW_EOS_TXSign_Ex(ppPAEWContext, devIdx, transaction, sizeof(transaction), pbTXSig, &pnTXSigLen, &callBack, 0);
        if (iRtn) {
            [self printLog:@"PAEW_EOS_TXSign_Ex returns failed: %@", [Utils errorCodeToString:iRtn]];
            return ;
        }
        [self printLog:@"EOS signature: %@" ,[[NSString alloc] initWithBytes:pbTXSig length:pnTXSigLen encoding:NSASCIIStringEncoding]];
        [self printLog:@"PAEW_EOS_TXSign_Ex returns success"];
    });
}

//This method is deprecated, keep it only for compatible with old cards
//Please refer to ETHSignNewBtnAction implementation to sign in a recommended procedure
- (void)ETHSignBtnAction
{
    [self printLog:@"ready to call PAEW_ETH_TXSign_Ex"];
    int rtn = [self getAuthType];
    if (rtn != PAEW_RET_SUCCESS) {
        [self printLog:@"user canceled PAEW_ETH_TXSign_Ex"];
        return;
    }
    if (self->nAuthType == PAEW_SIGN_AUTH_TYPE_PIN) {
        rtn = [self getPIN];
        if (rtn != PAEW_RET_SUCCESS) {
            [self printLog:@"user canceled PAEW_ETH_TXSign_Ex"];
            return;
        }
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int devIdx = 0;
        void *ppPAEWContext = (void*)self.savedDevice;
        int iRtn = PAEW_RET_UNKNOWN_FAIL;
        unsigned char nCoinType = PAEW_COIN_TYPE_ETH;
        uint32_t puiDerivePath[] = {0, 0x8000002c, 0x8000003c, 0x80000000, 0x00000000, 0x00000000};
        iRtn = PAEW_DeriveTradeAddress(ppPAEWContext, devIdx, nCoinType, puiDerivePath, sizeof(puiDerivePath)/sizeof(puiDerivePath[0]));
        if (iRtn != PAEW_RET_SUCCESS) {
            [self printLog:@"PAEW_ETH_TXSign_Ex failed due to PAEW_DeriveTradeAddress returns : %@", [Utils errorCodeToString:iRtn]];
            return ;
        }
        
        unsigned char transaction[] = { 0xec,  0x09,  0x85,  0x04,  0xa8,  0x17,  0xc8,  0x00,  0x82,  0x52,  0x08,  0x94,  0x35,  0x35,  0x35,  0x35,  0x35,  0x35,  0x35,  0x35,  0x35,  0x35,  0x35,  0x35,  0x35,  0x35,  0x35,  0x35,  0x35,  0x35,  0x35,  0x35,  0x88,  0x0d,  0xe0,  0xb6,  0xb3,  0xa7,  0x64,  0x00,  0x00,  0x80,  0x01,  0x80,  0x80};
        unsigned char *pbTXSig = (unsigned char *)malloc(1024);
        size_t pnTXSigLen = 1024;
        signCallbacks callBack;
        callBack.getAuthType = GetAuthType;
        callBack.getPIN = GetPin;
        callBack.putSignState = PutSignState;
        selfClass->lastSignState = PAEW_RET_SUCCESS;
        //This method is deprecated, keep it only for compatible with old cards
        iRtn = PAEW_ETH_TXSign_Ex(ppPAEWContext, devIdx, transaction, sizeof(transaction), pbTXSig,  &pnTXSigLen, &callBack, 0);
        if (iRtn) {
            [self printLog:@"PAEW_ETH_TXSign_Ex returns failed: %@", [Utils errorCodeToString:iRtn]];
            return ;
        }
        [self printLog:@"ETH signature is: %@", [Utils bytesToHexString:[NSData dataWithBytes:pbTXSig length:pnTXSigLen]]];
        [self printLog:@"PAEW_ETH_TXSign_Ex returns success"];
    });
}

- (UIButton *)genSeedBtn
{
    if (!_genSeedBtn) {
        _genSeedBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_genSeedBtn setTitle:@"GenSeed" forState:UIControlStateNormal];
        [_genSeedBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        _genSeedBtn.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium];
        [_genSeedBtn setBackgroundColor:[UIColor lightGrayColor]];
        [_genSeedBtn addTarget:self action:@selector(genSeedBtnAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _genSeedBtn;
}

- (void)genSeedBtnAction
{
    [self printLog:@"ready to call PAEW_GenerateSeed_GetMnes"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int devIdx = 0;
        void *ppPAEWContext = (void*)self.savedDevice;
        int iRtn = PAEW_RET_UNKNOWN_FAIL;
        unsigned char nSeedLen = 32;
        unsigned char pbMneWord[PAEW_MNE_MAX_LEN] = {0};
        size_t pnMneWordLen = sizeof(pbMneWord);
        size_t  pnCheckIndex[PAEW_MNE_INDEX_MAX_COUNT] = { 0 };
        size_t pnCheckIndexCount = PAEW_MNE_INDEX_MAX_COUNT;
        iRtn = PAEW_GenerateSeed_GetMnes(ppPAEWContext, devIdx, nSeedLen, pbMneWord, &pnMneWordLen, pnCheckIndex, &pnCheckIndexCount);
        if (iRtn != PAEW_RET_SUCCESS) {
            [self printLog:@"PAEW_GenerateSeed_GetMnes returns failed: %@", [Utils errorCodeToString:iRtn]];
            return;
        }
        [self printLog:@"PAEW_GenerateSeed_GetMnes returns success"];
        [self printLog:@"seed generated, mnemonics are: %s", pbMneWord];
        NSString *mne = [NSString stringWithUTF8String:pbMneWord];
        NSMutableString *mneStr = [NSMutableString new];
        NSArray *mneArr = [mne componentsSeparatedByString:@" "];
        for (int i = 0; i < mneArr.count; i++) {
            [mneStr appendString:mneArr[i]];
            //6 words in one line
            if ((i % 6) == 5) {
                if (i != (mneArr.count - 1)) {
                    [mneStr appendString:@"\n"];
                }
            } else {
                [mneStr appendString:@" "];
            }
        }
        //NSData *pbMneWordData = [NSData dataWithBytes:pbMneWord length:pnMneWordLen];
        //NSString *pbMneWordStr = [[NSString alloc] initWithData:pbMneWordData encoding:NSASCIIStringEncoding];
        NSMutableString *tmpStr = [NSMutableString new];
        for (int i = 0; i < pnCheckIndexCount; i++) {
            [tmpStr appendString:[NSString stringWithFormat: i == 0 ? @"word%lu" : @", word%lu", pnCheckIndex[i] + 1]];
        }
        [self printLog:@"please input the words exactly as this sequence with ONE WHITESPACE between each words: %@", tmpStr];
        
        NSMutableString *input = [NSMutableString new];
        for (int i = 0; i < pnCheckIndexCount; i++) {
            [input appendString:mneArr[pnCheckIndex[i]]];
            if (i != (pnCheckIndexCount - 1)) {
                [input appendString:@" "];
            }
        }
        
         [self printLog:@"words to input are:: %@", input];
        
        iRtn = PAEW_GenerateSeed_CheckMnes(ppPAEWContext, devIdx, (unsigned char *)[input UTF8String], input.length);
        if (iRtn != PAEW_RET_SUCCESS) {
            [self printLog:@"PAEW_GenerateSeed_CheckMnes returns failed: %@", [Utils errorCodeToString:iRtn]];
            return;
        }
        [self printLog:@"PAEW_GenerateSeed_CheckMnes returns success"];
    });
}

- (UIButton *)formatBtn
{
    if (!_formatBtn) {
        _formatBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_formatBtn setTitle:@"Format" forState:UIControlStateNormal];
        [_formatBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        _formatBtn.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium];
        [_formatBtn setBackgroundColor:[UIColor lightGrayColor]];
        [_formatBtn addTarget:self action:@selector(formatBtnAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _formatBtn;
}

- (void)formatBtnAction
{
    [self printLog:@"ready to call PAEW_Format_Ex"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int devIdx = 0;
        void *ppPAEWContext = (void*)self.savedDevice;
        int iRtn = PAEW_RET_UNKNOWN_FAIL;
        
        iRtn = PAEW_Format_Ex(ppPAEWContext, devIdx, PutState_Callback, NULL);
        if (iRtn != PAEW_RET_SUCCESS) {
            [self printLog:@"PAEW_Format_Ex returns failed: %@", [Utils errorCodeToString:iRtn]];
            return ;
        } else {
            [self printLog:@"PAEW_Format_Ex returns success"];
        }
    });
    
}

- (UIButton *)deleteFPBtn
{
    if (!_deleteFPBtn) {
        _deleteFPBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_deleteFPBtn setTitle:@"DeleteFP" forState:UIControlStateNormal];
        [_deleteFPBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        _deleteFPBtn.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium];
        [_deleteFPBtn setBackgroundColor:[UIColor lightGrayColor]];
        [_deleteFPBtn addTarget:self action:@selector(deleteFPBtnAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _deleteFPBtn;
}

- (void)deleteFPBtnAction
{
    [self printLog:@"ready to call PAEW_DeleteFP"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        FingerPrintID   *localFPList = 0;
        int nFPCount = 0;
        int devIdx = 0;
        void *ppPAEWContext = (void*)self.savedDevice;
        int iRtn = PAEW_RET_UNKNOWN_FAIL;
        iRtn = PAEW_DeleteFP(ppPAEWContext, devIdx, localFPList, nFPCount);
        
        if (iRtn != PAEW_RET_SUCCESS) {
            [self printLog:@"PAEW_DeleteFP returns failed: %@", [Utils errorCodeToString:iRtn]];
            return ;
        } else {
            [self printLog:@"PAEW_DeleteFP returns success"];
        }
    });
}

- (UIButton *)verifyFPBtn
{
    if (!_verifyFPBtn) {
        _verifyFPBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_verifyFPBtn setTitle:@"VerifyFP" forState:UIControlStateNormal];
        [_verifyFPBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        _verifyFPBtn.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium];
        [_verifyFPBtn setBackgroundColor:[UIColor lightGrayColor]];
        [_verifyFPBtn addTarget:self action:@selector(verifyFPBtnAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _verifyFPBtn;
}

- (void)verifyFPBtnAction
{
    self.abortBtnState = NO;
    [self printLog:@"ready to call PAEW_VerifyFP"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int devIdx = 0;
        void *ppPAEWContext = (void*)self.savedDevice;
        int iRtn = PAEW_RET_UNKNOWN_FAIL;
        iRtn = PAEW_VerifyFP(ppPAEWContext, devIdx);
        if (iRtn != PAEW_RET_SUCCESS) {
             [self printLog:@"PAEW_VerifyFP returns failed: %@", [Utils errorCodeToString:iRtn]];
            return ;
        }
        
        int lastRtn = PAEW_RET_SUCCESS;
        do {
            iRtn = PAEW_GetFPState(ppPAEWContext, devIdx);
            if (lastRtn != iRtn) {
                [self printLog:[Utils errorCodeToString:iRtn]];
                lastRtn = iRtn;
            }
            if (self.abortBtnState) {
                [self.abortCondition lock];
                !self.abortHandelBlock ? : self.abortHandelBlock(YES);
                [self.abortCondition wait];
                [self.abortCondition unlock];
                self.abortBtnState = NO;
            }
        } while (iRtn == PAEW_RET_DEV_WAITING);
        if (iRtn != PAEW_RET_SUCCESS) {
            [self printLog:@"PAEW_VerifyFP failed due to PAEW_GetFPState returns: %@", [Utils errorCodeToString:iRtn]];
            return ;
        }
        
        size_t          nFPListCount = 1;
        FingerPrintID   *fpIDList = (FingerPrintID *)malloc(sizeof(FingerPrintID) * nFPListCount);
        memset(fpIDList, 0, sizeof(FingerPrintID) * nFPListCount);
        iRtn = PAEW_GetVerifyFPList(ppPAEWContext, devIdx, fpIDList, &nFPListCount);
        if (iRtn != PAEW_RET_SUCCESS) {
            [self printLog:@"PAEW_VerifyFP failed due to PAEW_GetVerifyFPList returns: %@", [Utils errorCodeToString:iRtn]];
        } else {
            if (nFPListCount != 1) {
                [self printLog:@"PAEW_VerifyFP successe but nFPListCount is: %d", nFPListCount];
            } else {
                [self printLog:@"PAEW_VerifyFP successe with No.%u fingerprint verified", fpIDList[0].data[0]];
            }
        }
        free(fpIDList);
    });
    
}


- (void)enrollFPBtnAction
{
    self.abortBtnState = NO;
    [self printLog:@"ready to call PAEW_EnrollFP, during the whole enroll process, you can tap Abort button to abort at any time"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int devIdx = 0;
        void *ppPAEWContext = (void*)self.savedDevice;
        int startEnrollS = PAEW_EnrollFP(ppPAEWContext, devIdx);
        if (startEnrollS != PAEW_RET_SUCCESS) {
            [self printLog:@"PAEW_EnrollFP returns failed: %@", [Utils errorCodeToString:startEnrollS]];
            return ;
        }
        
        int iRtn = PAEW_RET_UNKNOWN_FAIL;
        int lastRtn = PAEW_RET_SUCCESS;
        do {
            
            iRtn = PAEW_GetFPState(ppPAEWContext, devIdx);
            if (lastRtn != iRtn) {
                [self printLog:@"fpstate:%@", [Utils errorCodeToString:iRtn]];
                lastRtn = iRtn;
            }
            if (self.abortBtnState) {
                [self.abortCondition lock];
                !self.abortHandelBlock ? : self.abortHandelBlock(YES);
                [self.abortCondition wait];
                [self.abortCondition unlock];
                self.abortBtnState = NO;
            }
        } while ((iRtn == PAEW_RET_DEV_WAITING) || (iRtn == PAEW_RET_DEV_FP_GOOG_FINGER) || (iRtn == PAEW_RET_DEV_FP_REDUNDANT) || (iRtn == PAEW_RET_DEV_FP_BAD_IMAGE) || (iRtn == PAEW_RET_DEV_FP_NO_FINGER) || (iRtn == PAEW_RET_DEV_FP_NOT_FULL_FINGER));
        if (iRtn != PAEW_RET_SUCCESS) {
            [self printLog:@"PAEW_EnrollFP failed due to PAEW_GetFPState returns: %@", [Utils errorCodeToString:iRtn]];
            return ;
        }
        [self printLog:@"PAEW_EnrollFP returns success"];
    });
    
}

- (UIButton *)enrollFPBtn
{
    if (!_enrollFPBtn) {
        _enrollFPBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_enrollFPBtn setTitle:@"EnrollFP" forState:UIControlStateNormal];
        [_enrollFPBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        _enrollFPBtn.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium];
        [_enrollFPBtn setBackgroundColor:[UIColor lightGrayColor]];
        [_enrollFPBtn addTarget:self action:@selector(enrollFPBtnAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _enrollFPBtn;
}

- (UIButton *)getFPListBtn
{
    if (!_getFPListBtn) {
        _getFPListBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_getFPListBtn setTitle:@"GetFPList" forState:UIControlStateNormal];
        [_getFPListBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        _getFPListBtn.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium];
        [_getFPListBtn setBackgroundColor:[UIColor lightGrayColor]];
        [_getFPListBtn addTarget:self action:@selector(getFPListBtnAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _getFPListBtn;
}

- (void)getFPListBtnAction
{
    [self printLog:@"ready to call PAEW_GetFPList"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int devIdx = 0;
        void *ppPAEWContext = (void*)self.savedDevice;
        size_t nListLen = 0;
        FingerPrintID *pFPList = NULL;
        int iRtn = PAEW_RET_UNKNOWN_FAIL;
        iRtn = PAEW_GetFPList(ppPAEWContext, devIdx, 0, &nListLen);
        if (iRtn != PAEW_RET_SUCCESS) {
            [self printLog:@"PAEW_GetFPList returns failed: %@", [Utils errorCodeToString:iRtn]];
            return ;
        } else if (nListLen == 0) {
            [self printLog:@"0 fingerprint exists"];
            [self printLog:@"PAEW_GetFPList returns success"];
            return ;
        } else {
            pFPList = (FingerPrintID *)malloc(sizeof(FingerPrintID) * nListLen);
            iRtn = PAEW_GetFPList(ppPAEWContext, devIdx, pFPList, &nListLen);
            if (iRtn == PAEW_RET_SUCCESS) {
                NSMutableString *strIndex = [NSMutableString new];
                for (int i = 0; i < nListLen; i++) {
                    [strIndex appendFormat:i == 0 ? @"No.%u" : @", No.%u", pFPList[i].data[0]];
                }
                [self printLog:(nListLen <= 1) ? @"%zu fingerprint exists at index: %@" : @"%zu fingerprints exist at index: %@", nListLen, strIndex];
                [self printLog:@"PAEW_GetFPList returns success"];
            } else {
                [self printLog:@"PAEW_GetFPList returns failed: %@", [Utils errorCodeToString:iRtn]];
            }
            free(pFPList);
        }
    });
}

- (UIButton *)changePinBtn
{
    if (!_changePinBtn) {
        _changePinBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_changePinBtn setTitle:@"ChangePin" forState:UIControlStateNormal];
        [_changePinBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        _changePinBtn.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium];
        [_changePinBtn setBackgroundColor:[UIColor lightGrayColor]];
        [_changePinBtn addTarget:self action:@selector(changePinBtnAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _changePinBtn;
}

- (void)changePinBtnAction
{
    NSString *oldpin = nil;
    NSString *newpin = nil;
    NSString *newpinConfirm = nil;
    oldpin = [TextFieldViewAlert doModal:self
                                   title:@"Input current PIN"
                                 message:@"Please input your current PIN"
                              isPassword:YES
                       minLengthRequired:6
                            keyboardType:UIKeyboardTypeNumberPad];
    if (!oldpin) {
        return;
    }
    newpin = [TextFieldViewAlert doModal:self
                                title:@"Input new PIN"
                              message:@"Please input your new PIN"
                           isPassword:YES
                    minLengthRequired:6
                         keyboardType:UIKeyboardTypeNumberPad];
    if (!newpin) {
        return;
    }
    newpinConfirm = [TextFieldViewAlert doModal:self
                                       title:@"Input new PIN again"
                                     message:@"Please input your new PIN again"
                                  isPassword:YES
                           minLengthRequired:6
                                keyboardType:UIKeyboardTypeNumberPad];
    if (!newpin || ![newpin isEqualToString:newpinConfirm]) {
        [self printLog:@"new pin not match"];
        return;
    }
    
    [self printLog:@"ready to call PAEW_ChangePIN_Input_Ex"];
    self.abortButtonFlag = NO;
    self->lastButtonState = PAEW_RET_SUCCESS;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int devIdx = 0;
        void *ppPAEWContext = (void*)self.savedDevice;
        int initState = PAEW_ChangePIN_Input_Ex(ppPAEWContext, devIdx, [oldpin UTF8String], [newpin UTF8String], PutState_Callback, NULL);
        if (initState == PAEW_RET_SUCCESS) {
            [self printLog:@"PAEW_ChangePIN_Input_Ex returns success"];
        } else {
            [self printLog:@"PAEW_ChangePIN_Input_Ex returns failed: %@", [Utils errorCodeToString:initState]];
        }
    });
}

- (UIButton *)verifyPinBtn
{
    if (!_verifyPinBtn) {
        _verifyPinBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_verifyPinBtn setTitle:@"VerifyPin" forState:UIControlStateNormal];
        [_verifyPinBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        _verifyPinBtn.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium];
        [_verifyPinBtn setBackgroundColor:[UIColor lightGrayColor]];
        [_verifyPinBtn addTarget:self action:@selector(verifyPinBtnAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _verifyPinBtn;
}

- (void)verifyPinBtnAction
{
    NSString *pin = nil;
    pin = [TextFieldViewAlert doModal:self
                                title:@"Input PIN"
                              message:@"Please input your PIN"
                           isPassword:YES
                    minLengthRequired:6
                         keyboardType:UIKeyboardTypeNumberPad];
    if (!pin) {
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int devIdx = 0;
        void *ppPAEWContext = (void*)self.savedDevice;
        [self printLog:@"ready to call PAEW_VerifyPIN"];
        int initState = PAEW_VerifyPIN(ppPAEWContext, devIdx, [pin UTF8String]);
        if (initState == PAEW_RET_SUCCESS) {
            [self printLog:@"PAEW_VerifyPIN returns success"];
        } else {
            [self printLog:@"PAEW_VerifyPIN returns failed: %@", [Utils errorCodeToString:initState]];
        }
    });
}

- (UIButton *)initiPinBtn
{
    if (!_initiPinBtn) {
        _initiPinBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_initiPinBtn setTitle:@"InitiPin" forState:UIControlStateNormal];
        [_initiPinBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        _initiPinBtn.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium];
        [_initiPinBtn setBackgroundColor:[UIColor lightGrayColor]];
        [_initiPinBtn addTarget:self action:@selector(initiPinBtnAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _initiPinBtn;
}

- (void)initiPinBtnAction
{
    NSString *pin = nil;
    NSString *pinConfirm = nil;
    pin = [TextFieldViewAlert doModal:self
                                title:@"Input new PIN"
                              message:@"Please input your new PIN"
                           isPassword:YES
                    minLengthRequired:6
                         keyboardType:UIKeyboardTypeNumberPad];
    if (!pin) {
        return;
    }
    pinConfirm = [TextFieldViewAlert doModal:self
                                       title:@"Input new PIN again"
                                     message:@"Please input your new PIN again"
                                  isPassword:YES
                           minLengthRequired:6
                                keyboardType:UIKeyboardTypeNumberPad];
    if (!pin || ![pin isEqualToString:pinConfirm]) {
        [self printLog:@"pin not match"];
        return;
    }
    self.abortButtonFlag = NO;
    self->lastButtonState = PAEW_RET_SUCCESS;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int devIdx = 0;
        void *ppPAEWContext = (void*)self.savedDevice;
        [self printLog:@"ready to call PAEW_InitPIN_Ex"];
        int initState = PAEW_InitPIN_Ex(ppPAEWContext, devIdx, [pin UTF8String], PutState_Callback, NULL);
        if (initState == PAEW_RET_SUCCESS) {
            [self printLog:@"PAEW_InitPIN_Ex returns success"];
        } else {
            [self printLog:@"PAEW_InitPIN_Ex returns failed: %@", [Utils errorCodeToString:initState]];
        }
    });
}

- (UIButton *)getFWVersionBtn
{
    if (!_getFWVersionBtn) {
        _getFWVersionBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_getFWVersionBtn setTitle:@"GetFWVer" forState:UIControlStateNormal];
        [_getFWVersionBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        _getFWVersionBtn.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium];
        [_getFWVersionBtn setBackgroundColor:[UIColor lightGrayColor]];
        [_getFWVersionBtn addTarget:self action:@selector(getFWVersionBtnAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _getFWVersionBtn;
}

- (void)getFWVersionBtnAction
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int devIdx = 0;
        void *ppPAEWContext = (void*)self.savedDevice;
        [self printLog:@"ready to call PAEW_GetFWVersion"];
        PAEW_FWVersion version = {0};
        int initState = PAEW_GetFWVersion(ppPAEWContext, devIdx, &version);
        if (initState == PAEW_RET_SUCCESS) {
            NSString *algVer = [Utils bytesToHexString:version.pbAlgVersion length:version.nAlgVersionLen];
            NSString *majorVer = [Utils bytesToHexString:version.pbMajorVersion length:sizeof(version.pbMajorVersion)];
            NSString *minorVer = [Utils bytesToHexString:version.pbMinorVersion length:sizeof(version.pbMinorVersion)];
            NSString *loaderVer = [Utils bytesToHexString:version.pbLoaderVersion length:sizeof(version.pbLoaderVersion)];
            NSString *loaderChipVer = [Utils bytesToHexString:version.pbLoaderChipVersion length:sizeof(version.pbLoaderChipVersion)];
            NSString *userChipVer = [Utils bytesToHexString:version.pbUserChipVersion length:sizeof(version.pbUserChipVersion)];
            [self printLog:@"PAEW_GetFWVersion returns success, algVer is %@, majorVer is %@, minorVer is %@, loaderChipVer is %@, loaderVer is %@, userChipVer is %@, isUserFW: %hh02X", algVer, majorVer, minorVer, loaderChipVer, loaderVer, userChipVer, version.nIsUserFW];
        } else {
            [self printLog:@"PAEW_GetFWVersion returns failed: %@", [Utils errorCodeToString:initState]];
        }
    });
}

- (UIButton *)getBatteryStateBtn
{
    if (!_getBatteryStateBtn) {
        _getBatteryStateBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_getBatteryStateBtn setTitle:@"GetBatt" forState:UIControlStateNormal];
        [_getBatteryStateBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        _getBatteryStateBtn.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium];
        [_getBatteryStateBtn setBackgroundColor:[UIColor lightGrayColor]];
        [_getBatteryStateBtn addTarget:self action:@selector(getBatteryStateBtnAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _getBatteryStateBtn;
}

- (void) getBatteryStateBtnAction
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int devIdx = 0;
        void *ppPAEWContext = (void*)self.savedDevice;
        [self printLog:@"ready to call PAEW_GetBatteryValue"];
        unsigned char pbBatteryValue[2] = {0};
        size_t nBatteryValueLen = 2;
        int initState = PAEW_GetBatteryValue(ppPAEWContext, devIdx, pbBatteryValue, &nBatteryValueLen);
        if (initState == PAEW_RET_SUCCESS) {
            [self printLog:@"PAEW_GetBatteryValue returns success, power source is: %hh02X, battery level is 0x%hh02X", pbBatteryValue[0], pbBatteryValue[1]];
        } else {
            [self printLog:@"PAEW_GetBatteryValue returns failed: %@", [Utils errorCodeToString:initState]];
        }
    });
}

- (UIButton *)updateCOSBtn
{
    if (!_updateCOSBtn) {
        _updateCOSBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_updateCOSBtn setTitle:@"UpdateCOS" forState:UIControlStateNormal];
        [_updateCOSBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        _updateCOSBtn.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium];
        [_updateCOSBtn setBackgroundColor:[UIColor lightGrayColor]];
        [_updateCOSBtn addTarget:self action:@selector(updateCOSBtnAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _updateCOSBtn;
}



- (void)updateCOSBtnAction
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int devIdx = 0;
        void *ppPAEWContext = (void*)self.savedDevice;
        NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *filePath = [documentPath stringByAppendingString:@"/WOOKONG_BIO_COS.bin"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            [self printLog: @"WOOKONG_BIO_COS.bin does not exists"];
            return;
        }
        NSData *data = [NSData dataWithContentsOfFile:filePath];
        if (!data) {
            [self printLog: @"WOOKONG_BIO_COS.bin read failed"];
            return;
        }
        [self printLog:@"ready to call PAEW_ClearCOS"];
        int iRtn = PAEW_ClearCOS(ppPAEWContext, devIdx);
        if (iRtn == PAEW_RET_SUCCESS) {
            [self printLog:@"PAEW_ClearCOS returns success"];
            //MUST sleep 5 seconds at least after clear COS completed
            [NSThread sleepForTimeInterval:5.0];
        } else {
            [self printLog:@"PAEW_ClearCOS returns failed: %@", [Utils errorCodeToString:iRtn]];
        }
        [self printLog:@"ready to call PAEW_UpdateCOS_Ex"];
        self->updateProgress = 0;
        NSDate *start = [NSDate new];
        iRtn = PAEW_UpdateCOS_Ex(ppPAEWContext, devIdx, 0, [data bytes], data.length, UpdateCOSProgressCallback, nil);
        NSTimeInterval timeNumber = start.timeIntervalSinceNow;
        [self printLog:@"PAEW_UpdateCOS_Ex costs %@ senconds", timeNumber];
        if (iRtn == PAEW_RET_SUCCESS) {
            [self printLog:@"PAEW_UpdateCOS_Ex returns success"];
            //MUST sleep 5 seconds at least after update COS completed
            [NSThread sleepForTimeInterval:5.0];
            //MUST free context and reconnect to device otherwise all operations will be unavailable
        } else {
            [self printLog:@"PAEW_UpdateCOS_Ex returns failed: %@", [Utils errorCodeToString:iRtn]];
            return;
        }
    });
}

- (UIButton *)getDevInfoBtn
{
    if (!_getDevInfoBtn) {
        _getDevInfoBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_getDevInfoBtn setTitle:@"GetDevInfo" forState:UIControlStateNormal];
        [_getDevInfoBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        _getDevInfoBtn.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium];
        [_getDevInfoBtn setBackgroundColor:[UIColor lightGrayColor]];
        [_getDevInfoBtn addTarget:self action:@selector(getDevInfoBtnAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _getDevInfoBtn;
}

- (void)getDevInfoBtnAction
{
    if (self.savedDevice) {
        //        继续执行
    } else {
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        void *ppPAEWContext = (void*)self.savedDevice;
        size_t            i = 0;
        PAEW_DevInfo    devInfo;
        uint32_t        nDevInfoType = 0;
        nDevInfoType = PAEW_DEV_INFOTYPE_COS_TYPE | PAEW_DEV_INFOTYPE_COS_VERSION | PAEW_DEV_INFOTYPE_SN | PAEW_DEV_INFOTYPE_CHAIN_TYPE | PAEW_DEV_INFOTYPE_PIN_STATE | PAEW_DEV_INFOTYPE_LIFECYCLE;
        [self printLog:@"ready to call PAEW_GetDevInfo"];
        int devInfoState = PAEW_GetDevInfo(ppPAEWContext, i, nDevInfoType, &devInfo);
        if (devInfoState == PAEW_RET_SUCCESS) {
            [self printLog:@"ucPINState: %02X", devInfo.ucPINState];
            [self printLog:@"ucCOSType: %02X", devInfo.ucCOSType];
            for (int i = 0; i < PAEW_DEV_INFO_SN_LEN; i++) {
                if (devInfo.pbSerialNumber[i] == 0xFF) {
                    devInfo.pbSerialNumber[i] = 0;
                }
            }
            [self printLog:@"SerialNumber: %@", [NSString stringWithUTF8String:(char *)devInfo.pbSerialNumber]];
            [self printLog:@"PAEW_GetDevInfo returns Success"];
        } else {
            [self printLog:@"PAEW_GetDevInfo returns failed: %@", [Utils errorCodeToString:devInfoState]];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            
        });
    });
}

- (UITextView *)in_outTextView
{
    if (!_in_outTextView) {
        _in_outTextView = [[UITextView alloc] init];
        _in_outTextView.font = [UIFont fontWithName:@"Arial" size:12.5f];
        _in_outTextView.textColor = [UIColor colorWithRed:51/255.0f green:51/255.0f blue:51/255.0f alpha:1.0f];
        _in_outTextView.backgroundColor = [UIColor whiteColor];
        _in_outTextView.textAlignment = NSTextAlignmentLeft;
        _in_outTextView.autocorrectionType = UITextAutocorrectionTypeNo;
        _in_outTextView.layer.borderColor = [UIColor greenColor].CGColor;
        _in_outTextView.layer.borderWidth = 1;
        _in_outTextView.layer.cornerRadius =5;
        _in_outTextView.autocapitalizationType = UITextAutocapitalizationTypeNone;
        _in_outTextView.keyboardType = UIKeyboardTypeASCIICapable;
        _in_outTextView.returnKeyType = UIReturnKeyDefault;
        _in_outTextView.scrollEnabled = YES;
        _in_outTextView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        _in_outTextView.editable = false;
    }
    return _in_outTextView;
}

- (void)showMessageWithInt:(int)retValue
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString* strResult = [Utils errorCodeToString:retValue];
        [LCProgressHUD showMessage:strResult];
    });
}

- (NSCondition *)abortCondition
{
    if (!_abortCondition) {
        _abortCondition = [[NSCondition alloc] init];
    }
    return _abortCondition;
}

- (int)getAuthType
{
    int sel = [PickerViewAlert doModal:selfClass title:@"Please choose signature verify method:" dataSouce:@[@"fingerprint", @"PIN"]];
    self->authTypeCached = YES;
    int rtn = PAEW_RET_DEV_OP_CANCEL;
    if (sel >= 0) {
        switch (sel) {
            case 0:
                selfClass->nAuthType = PAEW_SIGN_AUTH_TYPE_FP;
                rtn = PAEW_RET_SUCCESS;
                break;
            case 1:
                selfClass->nAuthType = PAEW_SIGN_AUTH_TYPE_PIN;
                rtn = PAEW_RET_SUCCESS;
                break;
            default:
                selfClass->nAuthType = -1;
                rtn = PAEW_RET_DEV_OP_CANCEL;
        }
    }
    self->authTypeResult = rtn;
    return rtn;
}

-(int)getPIN
{
    NSString *pin = [TextFieldViewAlert doModal:selfClass
                                          title:@"Input PIN:"
                                        message:@"Please input your pin"
                                     isPassword:YES
                              minLengthRequired:6
                                   keyboardType:UIKeyboardTypeNumberPad];
    self->pinCached = YES;
    int rtn = PAEW_RET_DEV_OP_CANCEL;
    if (pin) {
        self->pin = pin;
        rtn = PAEW_RET_SUCCESS;
    }
    self->pinResult = rtn;
    return rtn;
}

- (void)printLog:(NSString *)format, ...
{
    logCounter++;
    va_list args;
    va_start(args, format);
    NSString *str = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    if ([NSThread isMainThread]) {
        self.in_outTextView.text =  [self.in_outTextView.text stringByAppendingFormat:@"[%zu]%@\n", logCounter, str];
        [self.in_outTextView scrollRangeToVisible:NSMakeRange(self.in_outTextView.text.length, 1)];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.in_outTextView.text = [self.in_outTextView.text stringByAppendingFormat:@"[%zu]%@\n", self->logCounter, str];
            [self.in_outTextView scrollRangeToVisible:NSMakeRange(self.in_outTextView.text.length, 1)];
        });
    }
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
