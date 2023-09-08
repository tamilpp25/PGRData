local IncId = 0

XGlobalVar = {
    ScrollViewScrollDir = {
        ScrollDown = "ScrollDown", --从上往下滚
        ScrollRight = "ScrollRight" --从左往右滚
    },

    UiDesignSize = {    --ui设计尺寸
        Width = 1920,
        Height = 1080,
    },

    GetIncId = function()
        IncId = IncId + 1
        return IncId
    end,

    BtnBuriedSpotTypeLevelOne = {
        BtnUiMainBtnRoleInfo = 1,
        BtnUiMainBtnNotice = 2,
        BtnUiMainPanelAd = 3,
        BtnUiMainBtnChat = 4,
        BtnUiMainBtnRole = 5,
        BtnUiMainBtnSecond = 6,
        BtnUiMainBtnActivityEntry1 = 7,
        BtnUiMainBtnActivityEntry2 = 8,
        BtnUiMainBtnActivityEntry3 = 9,
        BtnUiMainBtnActivityEntry4 = 18,
        BtnUiMainBtnStore = 10,
        BtnUiMainBtnRecharge = 11,
        BtnUiMainBtnWeek = 12,
        BtnUiMainBtnActivityBrief = 13,
        BtnUiMainBtnMusicPlayer = 14,
        BtnUiMainBtnMail = 15,
        BtnUiMainBtnFight = 16,
        BtnUiMainBtnScreenShot = 17,
        
        BtnUiMainBtnAddFreeGem      = 21, --主界面点击黑卡
        BtnUiMainBtnAddActionPoint  = 22, --主界面点击血清
        BtnUiMainBtnAddCoin         = 23, --主界面点击螺母
        BtnUiMainBtnPassport        = 24, --主界面点击BP
        BtnUiMainBtnSet             = 25, --主界面点击设置
        BtnUiMainBtnTask            = 26, --主界面点击任务
        BtnUiMainBtnBuilding        = 27, --主界面点击宿舍
        BtnUiMainBtnDrawMain        = 28, --主界面点击研发
        BtnUiMainBtnPartner         = 29, --主界面点击辅助机
        BtnUiMainBtnGuild           = 30, --主界面点击公会
        BtnUiMainBtnMember          = 31, --主界面点击成员
        BtnUiMainBtnBag             = 32, --主界面点击仓库
        BtnUiMainBtnSocial          = 33, --主界面点击好友
        BtnUiMainBtnWelfare         = 34, --主界面点击福利
        BtnUiMainBtnMentor          = 35, --主界面点击指导
        BtnUiMainBtnEquipGuide      = 36, --主界面点击装备目标
        BtnUiMainBtnKuJieQu         = 37, --主界面点击库街区
        BtnUiMainBtnCalendar        = 38, --主界面点击新周历
    },
    BtnBuriedSpotTypeLevelTwo = {
        BtnUiPurchaseBtnTabSkip1 = 1,
        BtnUiPurchaseBtnTabSkip2 = 2,
        BtnUiPurchaseBtnTabSkip3 = 3,
        BtnUiPurchaseBtnTabSkip4 = 4,
        BtnUiPurchaseGroupTabSkip1 = 5,
        BtnUiPurchaseGroupTabSkip2 = 6,
        BtnUiPurchaseGroupTabSkip3 = 7,
        BtnUiPurchaseGroupTabSkip4 = 8,
    },
    BtnGuildDormMain = {
        BtnTabMember = 1,
        BtnTabChallenge = 2,
        BtnTabGift = 3,
        BtnGuildBtn = 4,
        BtnUi = 5,
        BtnPeople = 6,
        BtnAct = 7,
        BtnChat = 8,
        BtnChannel = 9,
        BtnSwitchGuildDorm = 10,
        BtnGift = 11,
        BtnNpcInteract = 12,
        BtnFurnitureInteract = 13,
        BtnSelect = 14,
        BtnMusicEdit = 15,
        BtnMusicInteract = 16,
        BtnGuildWarEntry = 17,
    },
    BtnPhotograph = {
        BtnUiPhotographBtnHide = 1, --横屏隐藏UI
        BtnUiPhotographBtnSet = 2, --横屏设置
        BtnUiPhotographBtnPhotographVertical = 3, --切换竖屏
        BtnUiPhotographBtnPhotograph = 4,--横屏拍照
        BtnUiPhotographPortraitBtnPhotograph = 5, --竖屏拍照
        BtnUiPhotographPortraitBtnAction = 6, --竖屏动作
        BtnUiPhotographPortraitBtnHide = 7, --竖屏隐藏UI
        BtnUiPhotographPortraitBtnSet = 8, --竖屏设置
        BtnUiPhotographPortraitBtnSynchronous = 9, --竖屏同步主界面
        BtnUiPhotographPortraitBtnScene = 10, --竖屏切换场景
        BtnUiPhotographPortraitBtnCharacter = 11, --竖屏切换角色
        BtnUiPhotographPortraitBtnFashion = 12, --竖屏同切换涂装
    },
    BtnDorm = {
        BtnUiDormBtnEntrust = 1, --委托
        BtnUiDormBtnFileDetails = 2, --文件详情
    },
}