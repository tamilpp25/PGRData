-- 三头犬小队玩法 迭代主界面
local XUiCerberusGameMain = require("XUi/XUiCerberusGame/XUiCerberusGameMain")
---@class XUiCerberusGameMainV2P9 : XUiCerberusGameMain
local XUiCerberusGameMainV2P9 = XLuaUiManager.Register(XUiCerberusGameMain, "UiCerberusGameMainV2P9")

function XUiCerberusGameMainV2P9:OnEnableCb()
    self.Super.Super.OnEnable(self)
    self:CheckBtnRedPoint()
end

function XUiCerberusGameMainV2P9:Init3DPanel()
    local XUiModelCerberusGame3D = require("XUi/XUiCerberusGame/V2P9/Grid/XUiModelCerberusGame3DV2P9")
    local root = self.UiModelGo.transform
    ---@type XUiModelCerberusGame3D
    self.Model3D = XUiModelCerberusGame3D.New(root, self)
end

function XUiCerberusGameMainV2P9:InitButtonCb()
    self:RegisterClickEvent(self.BtnFashionStory1, self.OnBtnFashionStory1Click)
    self:RegisterClickEvent(self.BtnFashionStory2, self.OnBtnFashionStory2Click)
end

function XUiCerberusGameMainV2P9:RefreshLayer1BtnProgress()
    local chapterIdlist = XMVCA.XCerberusGame:GetChapterIdList()
    -- 一期
    local storyChapterId = chapterIdlist[XEnumConst.CerberusGame.ChapterIdIndex.Story]
    local challengeChapterId = chapterIdlist[XEnumConst.CerberusGame.ChapterIdIndex.Challenge]
    local cur1, total1 = XMVCA.XCerberusGame:GetProgressByChapterId(storyChapterId)
    local cur2, total2 = XMVCA.XCerberusGame:GetProgressByChapterId(challengeChapterId)
    local progress = (cur1 + cur2) / (total1 + total2) * 100
    self.BtnCommonStageGroup:SetNameByGroup(0, math.modf(progress) .. "%")
    
    -- 二期
    local storyChapterId = chapterIdlist[XEnumConst.CerberusGame.ChapterIdIndex.FashionStory]
    local challengeChapterId = chapterIdlist[XEnumConst.CerberusGame.ChapterIdIndex.FashionChallenge]
    local cur1, total1 = XMVCA.XCerberusGame:GetProgressByChapterId(storyChapterId)
    local cur2, total2 = XMVCA.XCerberusGame:GetProgressByChapterId(challengeChapterId)
    local progress = (cur1 + cur2) / (total1 + total2) * 100
    self.BtnFashionGroup:SetNameByGroup(0, math.modf(progress) .. "%")
end

function XUiCerberusGameMainV2P9:RefreshLayer2BtnProgress()
    local chapterIdlist = XMVCA.XCerberusGame:GetChapterIdList()
    
    local storyChapterId = chapterIdlist[XEnumConst.CerberusGame.ChapterIdIndex.FashionStory]
    local cur1, total1 = XMVCA.XCerberusGame:GetProgressByChapterId(storyChapterId)
    local progress = cur1 / total1 * 100
    self.BtnFashionStory1:SetNameByGroup(0, math.modf(progress) .. "%")
    
    local challengeChapterId = chapterIdlist[XEnumConst.CerberusGame.ChapterIdIndex.FashionChallenge]
    local cur1, total1 = XMVCA.XCerberusGame:GetProgressByChapterId(challengeChapterId)
    local progress = cur1 / total1 * 100
    self.BtnFashionStory2:SetNameByGroup(0, math.modf(progress) .. "%")
end

function XUiCerberusGameMainV2P9:RefreshCb()
    self.TxtLeftTime.gameObject:SetActiveEx(false)
    self:RefreshTitleByTimeId()
end

function XUiCerberusGameMainV2P9:RefreshTitleByTimeId()
    local secondTimeId = XMVCA.XCerberusGame:GetClientConfigValueByKey("CerberusGameRound2Time")
    local timeId = secondTimeId
    if not timeId then
        return
    end
    
    -- 活动主界面的倒计时
    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
    local leftTime = endTime - XTime.GetServerNowTimestamp()
    local str = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.CHATEMOJITIMER)
    self.BtnFashionGroup:SetNameByGroup(1, CS.XTextManager.GetText("CommonRemainTime", str))

    -- 两个涂装关卡入口的倒计时
    local chapterIdlist = XMVCA.XCerberusGame:GetChapterIdList()
    local allChaptersConfig = XMVCA.XCerberusGame:GetModelCerberusGameChapter()

    local storyChapterId = chapterIdlist[XEnumConst.CerberusGame.ChapterIdIndex.FashionStory]
    local storyTimeId = allChaptersConfig[storyChapterId].TimeId
    local storyLeftTime = XFunctionManager.GetEndTimeByTimeId(storyTimeId) - XTime.GetServerNowTimestamp()
    local storyTimeStr = XUiHelper.GetTime(storyLeftTime, XUiHelper.TimeFormatType.CHATEMOJITIMER)
    local storyText = CS.XTextManager.GetText("CommonRemainTime", storyTimeStr)

    local challengeChapterId = chapterIdlist[XEnumConst.CerberusGame.ChapterIdIndex.FashionChallenge]
    local challengeTimeId = allChaptersConfig[challengeChapterId].TimeId
    local challengeLeftTime = XFunctionManager.GetEndTimeByTimeId(challengeTimeId) - XTime.GetServerNowTimestamp()
    local challengeTimeStr = XUiHelper.GetTime(challengeLeftTime, XUiHelper.TimeFormatType.CHATEMOJITIMER)
    local challengeText = CS.XTextManager.GetText("CommonRemainTime", challengeTimeStr)

    self.BtnFashionStory1:SetNameByGroup(1, storyText)
    self.BtnFashionStory2:SetNameByGroup(1, challengeText)
end

function XUiCerberusGameMainV2P9:InitTimes()
    local secondTimeId = XMVCA.XCerberusGame:GetClientConfigValueByKey("CerberusGameRound2Time")
    local timeId = secondTimeId
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
        end
    end)
end

function XUiCerberusGameMainV2P9:CheckBtnRedPoint()
    local condRedStory = XRedPointConditions.Types.CERBERUSE_GAME_CHECK_BTN_FASHION_STORY_RED
    local condRedChallenge = XRedPointConditions.Types.CERBERUSE_GAME_CHECK_BTN_FASHION_CHALLENGE_RED
    local isRedStory = XRedPointConditions.Check(condRedStory)
    local isRedChallenge = XRedPointConditions.Check(condRedChallenge)

    self.BtnFashionGroup:ShowReddot(isRedStory or isRedChallenge)
    self.BtnFashionStory1:ShowReddot(isRedStory)
    self.BtnFashionStory2:ShowReddot(isRedChallenge)
end

function XUiCerberusGameMainV2P9:OnBtnCharacterInfoClick()
    self:OpenOneChildUi("UiCerberusGameRoleV2P9", self.Model3D)
    self:HideSafeArea()
end

function XUiCerberusGameMainV2P9:OnBtnFashionStory1Click()
    XLuaUiManager.Open("UiCerberusGameChapterV2P9", XMVCA.XCerberusGame:GetChapterIdList()[XEnumConst.CerberusGame.ChapterIdIndex.FashionStory])
    XMVCA.XCerberusGame:SetBtnFashionStoryClick()
end

function XUiCerberusGameMainV2P9:OnBtnFashionStory2Click()
    XLuaUiManager.Open("UiCerberusGameChallengeV2P9")
    XMVCA.XCerberusGame:SetBtnFashionChallengeClick()
end

return XUiCerberusGameMainV2P9