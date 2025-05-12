
local XUiPanelRegressionBase = require("XUi/XUiRegression3rd/XUiPanel/XUiPanelRegressionBase")

local XUiPanelRegressionMain = XClass(XUiPanelRegressionBase, "XUiPanelRegressionMain")

--region   ------------------重写父类方法 start-------------------
function XUiPanelRegressionBase:OnEnable()
    self:RefreshView()
end

function XUiPanelRegressionMain:InitCb()
    self.BtnShop.CallBack = function() 
        self:OnBtnShopClick()
    end

    self.BtnInvitation.CallBack = function()
        self:OnBtnInvitationClick()
    end

    self.BtnTitle.CallBack = function()
        self:OnBtnTitleClick()
    end
end

function XUiPanelRegressionMain:Show()
    self:Open()
end

function XUiPanelRegressionMain:Hide()
    self:Close()
end

function XUiPanelRegressionMain:UpdateTime()
    self.BtnTitle:SetNameByGroup(0, self.ViewModel:GetLeftTimeDescWithoutPrefix("FFF21F"))
end

--endregion------------------重写父类方法 finish------------------

function XUiPanelRegressionMain:OnBtnShopClick()
    if not XDataCenter.Regression3rdManager.CheckGiftShopRedPointData() then
        XDataCenter.Regression3rdManager.MarkGiftShopRedPointData()
        self.BtnShop:ShowReddot(false)
    end
    XLuaUiManager.Open("UiRegressionGiftShop")
end

function XUiPanelRegressionMain:OnBtnInvitationClick()
    XLuaUiManager.Open("UiRegressionInvitation")
end

function XUiPanelRegressionMain:OnBtnTitleClick()
    local storyId = self.ViewModel:GetStoryId()
    if not XTool.IsNumberValid(storyId) then
        return
    end
    XDataCenter.MovieManager.PlayMovie(storyId)
end

function XUiPanelRegressionMain:RefreshView()
    self:UpdateTime()
    
    self.BtnShop:ShowReddot(not XDataCenter.Regression3rdManager.CheckGiftShopRedPointData())
end


return XUiPanelRegressionMain