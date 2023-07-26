-- 三头犬小队玩法 CerberusGame (活动)
local XUiCerberusGameMain = XLuaUiManager.Register(XLuaUi, "UiCerberusGameMain")
---@type XUiModelCerberusGame3D XUiModelCerberusGame3D
local XUiModelCerberusGame3D = require("XUi/XUiCerberusGame/Grid/XUiModelCerberusGame3D")

function XUiCerberusGameMain:OnAwake()
    self:InitButton()
    self:Init3DPanel()
    self:InitTimes()
end

function XUiCerberusGameMain:InitButton()
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnMainUi, function () XLuaUiManager.RunMain() end)
    self:RegisterClickEvent(self.BtnStory, self.OnBtnStoryClick)
    self:RegisterClickEvent(self.BtnChallenge, self.OnBtnChallengeClick)
    self:RegisterClickEvent(self.BtnCharacterInfo, self.OnBtnCharacterInfoClick)
    self:RegisterClickEvent(self.BtnShop, self.OnBtnShopClick)
    self:BindHelpBtn(self.BtnHelp, "CerberusHelp")
end

function XUiCerberusGameMain:Init3DPanel()
    local root = self.UiModelGo.transform
    self.Model3D = XUiModelCerberusGame3D.New(root, self)
end

function XUiCerberusGameMain:ShowSafeArea()
    self.SafeAreaContentPane.gameObject:SetActiveEx(true)
end

function XUiCerberusGameMain:HideSafeArea()
    self.SafeAreaContentPane.gameObject:SetActiveEx(false)
end

function XUiCerberusGameMain:OnChildUiClose()
    self:ShowSafeArea()
end

function XUiCerberusGameMain:OnDisable()
    self.Model3D:StopTimer()
end

function XUiCerberusGameMain:OnEnable()
    self.Super.OnEnable(self)
    self:PlayAnimation("Enable", function ()
        self.Transform:FindTransform("Loop"):GetComponent("PlayableDirector"):Play()
    end)

    self:RefreshUi()
    XDataCenter.CerberusGameManager.SetLastSelectXStoryPoint(nil)
end

function XUiCerberusGameMain:RefreshUi()
    self:RefreshTitleByTimeId()
    self:RefreshChallengeBtnByTimeId()
end

function XUiCerberusGameMain:RefreshTitleByTimeId()
    local timeId = XDataCenter.CerberusGameManager.GetActivityConfig().TimeId
    if not timeId then
        return
    end
    
    -- 活动主界面的倒计时
    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
    local leftTime = endTime - XTime.GetServerNowTimestamp()
    if leftTime and leftTime > 0 then
        self.TxtLeftTime.text = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
        self.TxtLeftTime.gameObject:SetActiveEx(true)
    end
end

-- 挑战按钮的倒计时
function XUiCerberusGameMain:RefreshChallengeBtnByTimeId()
    local isOpen = self:CheckChallengeTimeOpen()
    self.BtnChallenge:SetDisable(not isOpen)

    local timeId = XDataCenter.CerberusGameManager.GetChallengeChapterConfig().TimeId
    if not timeId then
        return
    end

    local endTime = XFunctionManager.GetStartTimeByTimeId(timeId)
    local nowTime = XTime.GetServerNowTimestamp()
    local leftTime = endTime - nowTime
    if leftTime and leftTime > 0 then
        local timeStr = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
        local text = CS.XTextManager.GetText("MoeWarScheOpenCountdown", timeStr)
        self.BtnChallenge:SetNameByGroup(0, text)
    end
end

function XUiCerberusGameMain:CheckChallengeTimeOpen()
    -- 刷新挑战入口的按钮样式
    local timeId = XDataCenter.CerberusGameManager.GetChallengeChapterConfig().TimeId
    if not XTool.IsNumberValid(timeId) then
        return true
    end

    return XFunctionManager.CheckInTimeByTimeId(timeId)
end

function XUiCerberusGameMain:InitTimes()
    local timeId = XDataCenter.CerberusGameManager.GetActivityConfig().TimeId
    if not timeId then
        return
    end
    
    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            XLuaUiManager.RunMain()
            XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
        else
            self:RefreshTitleByTimeId()
            self:RefreshChallengeBtnByTimeId()
        end
    end)
end

function XUiCerberusGameMain:OnBtnStoryClick()
    local conditionId = XDataCenter.CerberusGameManager.GetStortyChapterConfig().OpenCondition
    if XTool.IsNumberValid(conditionId) then
        local res, desc = XConditionManager.CheckCondition(conditionId)
        if not res then
            XUiManager.TipError(desc)
            return
        end
    end

    XLuaUiManager.Open("UiCerberusGameChapter", XDataCenter.CerberusGameManager.GetChapterIdList()[1]) -- 剧情关是第一个chapter 写死
end

function XUiCerberusGameMain:OnBtnChallengeClick()
    if not self:CheckChallengeTimeOpen() then
        XUiManager.TipError(CS.XTextManager.GetText("CerbrusGameChallengeLimit1"))
        return
    end

    local conditionId = XDataCenter.CerberusGameManager.GetChallengeChapterConfig().OpenCondition
    if XTool.IsNumberValid(conditionId) then
        local res, desc = XConditionManager.CheckCondition(conditionId)
        if not res then
            XUiManager.TipError(desc)
            return
        end
    end

    XLuaUiManager.Open("UiCerberusGameChallenge")
end

function XUiCerberusGameMain:OnBtnCharacterInfoClick()
    self:OpenOneChildUi("UiCerberusGameRole", self.Model3D)
    self:HideSafeArea()
end

function XUiCerberusGameMain:OnBtnShopClick()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon) then
        return
    end

    local shopIdList = XDataCenter.CerberusGameManager.GetActivityConfig().ShopId
    XShopManager.GetShopInfoList(shopIdList, function()
        XLuaUiManager.Open("UiCerberusGameShop")
    end, XShopManager.ActivityShopType.CerberusShop)
end

return XUiCerberusGameMain