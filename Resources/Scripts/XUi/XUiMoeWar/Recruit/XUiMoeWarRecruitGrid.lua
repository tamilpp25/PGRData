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
    local isRecruitFinish = helperStatus == XMoeWarConfig.PreparationHelperStatus.RecruitFinish
    self.TagZhaomu.gameObject:SetActiveEx(isRecruitFinish)
    self.TagJindu.gameObject:SetActiveEx(not isRecruitFinish)

    self:CheckStartTimer(isRecruitFinish, helperId)
    self:RefreshPercent(isRecruitFinish, helperId)
end

function XUiMoeWarRecruitGrid:RefreshPercent(isRecruitFinish, helperId)
    if isRecruitFinish then
        return
    end
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
    if isRecruitFinish and self.BtnBackground.ButtonState ~= Disable then
        self.BtnBackground:SetDisable(true, false)
    elseif self.BtnBackground.ButtonState == Disable then
        self.BtnBackground:SetDisable(false)
    end

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