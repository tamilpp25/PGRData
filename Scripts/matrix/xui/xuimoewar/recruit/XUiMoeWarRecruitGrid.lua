local TEXT_GROUP = {
    ["Name"] = 0,
    ["Time"] = 1,
    ["Tag1"] = 2,
    ["Tag2"] = 3,
    ["Tag3"] = 4,
}
local TAG_MAX_COUNT = 3
local CSXTextManagerGetText = CS.XTextManager.GetText
local Normal = CS.UiButtonState.Normal
local Select = CS.UiButtonState.Select
local Disable = CS.UiButtonState.Disable

local XUiMoeWarRecruitGrid = XClass(nil, "XUiMoeWarRecruitGrid")

function XUiMoeWarRecruitGrid:Ctor(ui, index)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.Index = index
    self.BtnBackground:SetButtonState(Normal)
end

function XUiMoeWarRecruitGrid:OnDisable()
    self:StopTimer()
end

function XUiMoeWarRecruitGrid:SetHelperId(helperId)
    self.HelperId = helperId
end

function XUiMoeWarRecruitGrid:Refresh()
    local helperId = self.HelperId
    if not helperId then
        return
    end

    XDataCenter.MoeWarManager.CheckIsResetHelperStatus(helperId)

    self:RefreshRoleInfo(helperId)
    self:RefreshTag(helperId)
    self:RefreshStatus(helperId)
    self:RefreshRedPoint(helperId)
    self:CheckBtnDisableAndTagIcon(helperId)
end

function XUiMoeWarRecruitGrid:RefreshRedPoint(helperId)
    local isShowRedPoint = XDataCenter.MoeWarManager.CheckHelperRedPoint(helperId)
    self.BtnBackground:ShowReddot(isShowRedPoint)
end

function XUiMoeWarRecruitGrid:RefreshStatus(helperId)
    local helperStatus = XDataCenter.MoeWarManager.GetRecruitHelperStatus(helperId)
    local isRecruitFinish = helperStatus == XMoeWarConfig.PreparationHelperStatus.RecruitFinish or helperStatus == XMoeWarConfig.PreparationHelperStatus.RecruitFinishAndCommunicating
    self.TagJindu.gameObject:SetActiveEx(not isRecruitFinish)
    self.TagMood.gameObject:SetActiveEx(isRecruitFinish)

    self:CheckStartTimer(isRecruitFinish, helperId)
    if isRecruitFinish then
        self:RefreshMood(helperId)
    else
        self:RefreshPercent(helperId)
    end
end

--刷新心情进度
function XUiMoeWarRecruitGrid:RefreshMood(helperId)
    local curMoodValue = XDataCenter.MoeWarManager.GetMoodValue(helperId)
    local moodUpLimit = XMoeWarConfig.GetPreparationHelperMoodUpLimit(helperId)
    local id = XMoeWarConfig.GetCharacterMoodId(curMoodValue)

    --当前心情值
    self.TxtMoodNum.text = string.format("%d/%d", curMoodValue, moodUpLimit)
    --当前心情值进度
    self.ImgMoodJindu.fillAmount = curMoodValue / moodUpLimit
    --当前心情进度颜色
    self.ImgMoodJindu.color = XMoeWarConfig.GetCharacterMoodColor(id)
    --当前心情图标
    local icon = XMoeWarConfig.GetCharacterMoodIcon(id)
    self.ImgMoodIcon:SetSprite(icon)
end

--刷新答题进度
function XUiMoeWarRecruitGrid:RefreshPercent(helperId)
    local currRightCount = XDataCenter.MoeWarManager.GetFinishQuestionCount(helperId)
    local totalCount = XMoeWarConfig.GetMoeWarPreparationHelperTotalQuestionCount(helperId)
    self.TxtNum.text = currRightCount .. "/" .. totalCount
    self.ImgJindu.fillAmount = totalCount > 0 and currRightCount / totalCount or 0
end

function XUiMoeWarRecruitGrid:CheckStartTimer(isRecruitFinish, helperId)
    self:StopTimer()
    if not isRecruitFinish then
        self.BtnBackground:SetNameByGroup(TEXT_GROUP["Time"], "")
        return
    end

    local nowServerTime = XTime.GetServerNowTimestamp()
    local expirationTime = XDataCenter.MoeWarManager.GetRecruitHelperExpirationTime(helperId)
    if nowServerTime >= expirationTime then
        self.BtnBackground:SetNameByGroup(TEXT_GROUP["Time"], "")
        return
    end

    local timeLimit = expirationTime - nowServerTime
    local timeLimitStr = XUiHelper.GetTime(timeLimit, XUiHelper.TimeFormatType.CHATEMOJITIMER)
    self.BtnBackground:SetNameByGroup(TEXT_GROUP["Time"], CSXTextManagerGetText("MoeWarHelperTimeLimit", timeLimitStr))
    self.Timer = XScheduleManager.ScheduleForever(function()
        nowServerTime = XTime.GetServerNowTimestamp()
        timeLimit = expirationTime - nowServerTime
        if timeLimit <= 0 then
            self:StopTimer()
            self:Refresh()
            return
        end

        if not XTool.UObjIsNil(self.BtnBackground) then
            timeLimitStr = XUiHelper.GetTime(timeLimit, XUiHelper.TimeFormatType.CHATEMOJITIMER)
            self.BtnBackground:SetNameByGroup(TEXT_GROUP["Time"], CSXTextManagerGetText("MoeWarHelperTimeLimit", timeLimitStr))
        end
    end, XScheduleManager.SECOND)
end

function XUiMoeWarRecruitGrid:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiMoeWarRecruitGrid:RefreshTag(helperId)
    local lableIds = XMoeWarConfig.GetMoeWarPreparationHelperLabelIds(helperId)
    for i, lableId in ipairs(lableIds) do
        if not TEXT_GROUP["Tag" .. i] then
            break
        end
        local label = XMoeWarConfig.GetPreparationStageTagLabelById(lableId)
        self.BtnBackground:SetNameByGroup(TEXT_GROUP["Tag" .. i], label)
    end
end

function XUiMoeWarRecruitGrid:RefreshRoleInfo(helperId)
    local robotId = XMoeWarConfig.GetMoeWarPreparationHelperRobotId(helperId)
    local characterId = XRobotManager.GetCharacterId(robotId)
    local roleName = XCharacterConfigs.GetCharacterFullNameStr(characterId)
    self.BtnBackground:SetNameByGroup(TEXT_GROUP["Name"], roleName)

    local headIcon = XMoeWarConfig.GetMoeWarPreparationHelperCirleIcon(helperId)
    self.StandIcon:SetRawImage(headIcon)
end

function XUiMoeWarRecruitGrid:CheckBtnDisableAndTagIcon(helperId)
    local helperStatus = XDataCenter.MoeWarManager.GetRecruitHelperStatus(helperId)
    local isRecruitFinish = helperStatus == XMoeWarConfig.PreparationHelperStatus.RecruitFinish
    if self.TagLock then
        self.TagLock.gameObject:SetActiveEx(not isRecruitFinish)
    end
end

function XUiMoeWarRecruitGrid:SetActive(isShow)
    self.GameObject:SetActiveEx(isShow)
end

function XUiMoeWarRecruitGrid:GetHelperId()
    return self.HelperId
end

return XUiMoeWarRecruitGrid