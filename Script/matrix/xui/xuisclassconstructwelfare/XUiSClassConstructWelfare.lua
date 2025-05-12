local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
-- 自选S级构造体礼包界面
-- 该类其实不是签到类型，只是因为服务端改动过于繁琐，强行加在signin表了。客户端做特殊处理,实际上是另一个类型
local XUiSClassConstructWelfare = XClass(nil, "XUiSClassConstructWelfare")

function XUiSClassConstructWelfare:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self:InitButton()
end

function XUiSClassConstructWelfare:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnGet, self.OnBtnGetClick)
    XUiHelper.RegisterClickEvent(self, self.BtnHelp, self.OnBtnHelpClick)
end

function XUiSClassConstructWelfare:Refresh(signId)
    self.SignId = signId
    XEventManager.DispatchEvent(XEventId.EVENT_SING_IN_OPEN_BTN, true)

    local grid = XUiGridCommon.New(self.RootUi, self.GridCommon)
    local sItemId = 94008
    grid:Refresh({TemplateId = sItemId})
end

function XUiSClassConstructWelfare:OnBtnGetClick()
    -- 如果已经领取过了 不能再领
    if not XDataCenter.SignInManager.IsShowSignIn(self.SignId, true) then
        XUiManager.TipError(CS.XTextManager.GetText("CanNotClaimRewardsRepeatedly"))
        return
    end

    XDataCenter.SignInManager.SignInRequest(self.SignId, function (rewardGoodsList)
        self.BtnGet:SetDisable(true)

        XUiManager.OpenUiObtain(rewardGoodsList, nil, function ()
            if self.RootUi and self.RootUi.OnBtnCloseClick then
                self.RootUi:OnBtnCloseClick()
            end

            if self.RootUi and self.RootUi.RefreshRightView then
                self.RootUi:RefreshRightView()
            end
        end)
    end)
end

function XUiSClassConstructWelfare:OnBtnHelpClick()
    local signInInfos = XSignInConfigs.GetSignInInfos(self.SignId)
    XUiManager.UiFubenDialogTip("", signInInfos[1].Description or "")
end

function XUiSClassConstructWelfare:OnHide()
end

function XUiSClassConstructWelfare:OnShow()
end

return XUiSClassConstructWelfare