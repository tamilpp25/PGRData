local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
-- 三头犬小队玩法 CerberusGame (活动)
---@class XUiCerberusGameMain:XLuaUi
local XUiCerberusGameMain = XLuaUiManager.Register(XLuaUi, "UiCerberusGameMain")

function XUiCerberusGameMain:OnAwake()
    self:InitButton()
    self:Init3DPanel()
    self:InitTimes()

    self.GridShopDic = {}
end

function XUiCerberusGameMain:InitButton()
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnMainUi, function () XLuaUiManager.RunMain() end)
    self:RegisterClickEvent(self.BtnStory, self.OnBtnStoryClick)
    self:RegisterClickEvent(self.BtnChallenge, self.OnBtnChallengeClick)
    self:RegisterClickEvent(self.BtnCharacterInfo, self.OnBtnCharacterInfoClick)
    self:RegisterClickEvent(self.BtnShop, self.OnBtnShopClick)
    self:RegisterClickEvent(self.BtnVeraFashion, self.OnBtnVeraFashionClick)
    self:BindHelpBtn(self.BtnHelp, "CerberusHelp")

    self:InitButtonCb()
end

function XUiCerberusGameMain:InitButtonCb()
end

function XUiCerberusGameMain:Init3DPanel()
    local XUiModelCerberusGame3D = require("XUi/XUiCerberusGame/Grid/XUiModelCerberusGame3D")
    local root = self.UiModelGo.transform
    ---@type XUiModelCerberusGame3D
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
    XMVCA.XCerberusGame:GetConfigByTableKey(XMVCA.XCerberusGame:GetTableKey().CerberusGameRole)
end

function XUiCerberusGameMain:OnDisable()
    self.Model3D:StopTimer()
end

function XUiCerberusGameMain:OnEnable()
    self:PlayAnimation("Enable", function ()
        self.Transform:FindTransform("Loop"):GetComponent("PlayableDirector"):Play()
    end)
    
    self:RefreshUi()
    XMVCA.XCerberusGame:SetLastSelectXStoryPoint(nil)
    self:OnEnableCb()
end

function XUiCerberusGameMain:OnEnableCb()
    self.Super.OnEnable(self)
end

function XUiCerberusGameMain:RefreshUi()
    self:RefreshShopInfo()
    self:RefreshBtnProgress()
    self:RefreshCb()
end

function XUiCerberusGameMain:RefreshLayer1BtnProgress()
    local chapterIdlist = XMVCA.XCerberusGame:GetChapterIdList()
    -- 一期
    local storyChapterId = chapterIdlist[XEnumConst.CerberusGame.ChapterIdIndex.Story]
    local challengeChapterId = chapterIdlist[XEnumConst.CerberusGame.ChapterIdIndex.Challenge]
    local cur1, total1 = XMVCA.XCerberusGame:GetProgressByChapterId(storyChapterId)
    local cur2, total2 = XMVCA.XCerberusGame:GetProgressByChapterId(challengeChapterId)
    local progress = (cur1 + cur2) / (total1 + total2) * 100
    self.BtnCommonStageGroup:SetNameByGroup(0, math.modf(progress) .. "%")
end

function XUiCerberusGameMain:RefreshLayer2BtnProgress()
end

function XUiCerberusGameMain:RefreshLayer3BtnProgress()
    local chapterIdlist = XMVCA.XCerberusGame:GetChapterIdList()
    
    local storyChapterId = chapterIdlist[XEnumConst.CerberusGame.ChapterIdIndex.Story]
    local cur1, total1 = XMVCA.XCerberusGame:GetProgressByChapterId(storyChapterId)
    local progress = cur1 / total1 * 100
    self.BtnStory:SetNameByGroup(0, math.modf(progress) .. "%")
    
    local challengeChapterId = chapterIdlist[XEnumConst.CerberusGame.ChapterIdIndex.Challenge]
    local cur1, total1 = XMVCA.XCerberusGame:GetProgressByChapterId(challengeChapterId)
    local progress = cur1 / total1 * 100
    self.BtnChallenge:SetNameByGroup(0, math.modf(progress) .. "%")
end

function XUiCerberusGameMain:RefreshBtnProgress()
    self:RefreshLayer1BtnProgress()
    self:RefreshLayer2BtnProgress()
    self:RefreshLayer3BtnProgress()
end

function XUiCerberusGameMain:RefreshCb()
    self:RefreshTitleByTimeId()
    self:RefreshChallengeBtnByTimeId()
end

function XUiCerberusGameMain:RefreshShopInfo()
    local rewardId = XMVCA.XCerberusGame:GetClientConfigValueByKey("CerberusGameShopShowReward")
    local rewards = {}
    if rewardId > 0 then
        rewards = XRewardManager.GetRewardList(rewardId) or XRewardManager.GetRewardListNotCount(rewardId)
    end

    if rewards then
        for i, item in ipairs(rewards) do
            local grid = self.GridShopDic[i]
            if not grid then
                local panelReward = self.BtnShop.TagObj
                local uiTemplate = panelReward.transform:FindTransform("GridReward")
                local ui = i == 1 and uiTemplate or CS.UnityEngine.Object.Instantiate(uiTemplate, uiTemplate.transform.parent)
                grid = XUiGridCommon.New(self, ui)
                self.GridShopDic[i] = grid
            end
            grid:Refresh(item)
            grid.GameObject:SetActive(true)
        end
    end
end

function XUiCerberusGameMain:RefreshTitleByTimeId()
    self.TxtLeftTime.gameObject:SetActiveEx(false)
end

-- 挑战按钮的倒计时
function XUiCerberusGameMain:RefreshChallengeBtnByTimeId()
    local isOpen = self:CheckChallengeTimeOpen()
    self.BtnChallenge:SetDisable(not isOpen)

    local timeId = XMVCA.XCerberusGame:GetChallengeChapterConfig().TimeId
    if not XTool.IsNumberValid(timeId) then
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
    local timeId = XMVCA.XCerberusGame:GetChallengeChapterConfig().TimeId
    if not XTool.IsNumberValid(timeId) then
        return true
    end

    return XFunctionManager.CheckInTimeByTimeId(timeId)
end

function XUiCerberusGameMain:InitTimes()
    local timeId = XMVCA.XCerberusGame:GetActivityConfig().TimeId
    if not timeId then
        return
    end
    
    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            XLuaUiManager.RunMain()
            XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
        else
            -- self:RefreshTitleByTimeId()
            -- self:RefreshChallengeBtnByTimeId()
        end
    end)
end

function XUiCerberusGameMain:OnBtnStoryClick()
    local conditionId = XMVCA.XCerberusGame:GetStortyChapterConfig().OpenCondition
    if XTool.IsNumberValid(conditionId) then
        local res, desc = XConditionManager.CheckCondition(conditionId)
        if not res then
            XUiManager.TipError(desc)
            return
        end
    end

    XLuaUiManager.Open("UiCerberusGameChapter", XMVCA.XCerberusGame:GetChapterIdList()[XEnumConst.CerberusGame.ChapterIdIndex.Story]) -- 剧情关是第一个chapter 写死
end

function XUiCerberusGameMain:OnBtnChallengeClick()
    if not self:CheckChallengeTimeOpen() then
        XUiManager.TipError(CS.XTextManager.GetText("CerbrusGameChallengeLimit1"))
        return
    end

    local conditionId = XMVCA.XCerberusGame:GetChallengeChapterConfig().OpenCondition
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

    local shopIdList = XMVCA.XCerberusGame:GetActivityConfig().ShopId
    XShopManager.GetShopInfoList(shopIdList, function()
        XLuaUiManager.Open("UiCerberusGameShop")
    end, XShopManager.ActivityShopType.CerberusShop)
end

function XUiCerberusGameMain:OnBtnVeraFashionClick()
    XDataCenter.LottoManager.OpenVeraLotto(self)
end

return XUiCerberusGameMain