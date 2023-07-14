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
        BtnUiMainBtnStore = 10,
        BtnUiMainBtnRecharge = 11,
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
    }

}