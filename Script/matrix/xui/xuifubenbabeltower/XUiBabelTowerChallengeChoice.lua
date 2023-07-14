local CONDITION_COLOR = {
    [true] = XUiHelper.Hexcolor2Color("CE2525FF"),
    [false] = CS.UnityEngine.Color.black,
}

local XUiBabelTowerChallengeChoice = XClass(nil, "XUiBabelTowerChallengeChoice")
local UiButtonState = CS.UiButtonState
local CSXTextManagerGetText = CS.XTextManager.GetText
local XUiGridBabelChallengeItem = require("XUi/XUiFubenBabelTower/XUiGridBabelChallengeItem")

function XUiBabelTowerChallengeChoice:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.name = "XUiBabelTowerChallengeChoice"

    XTool.InitUiObject(self)
    self.ChallengeItemList = {}
    self.ChallengeBtnCompList = {}

    self.BtnGuideMask.CallBack = function() self:OnBtnGuideMaskClick() end
end

function XUiBabelTowerChallengeChoice:Init(uiRoot)
    self.UiRoot = uiRoot
end

function XUiBabelTowerChallengeChoice:SetItemData(itemData)
    self.BuffGoupDatas = itemData
    self.BuffGroupId = itemData.BuffGroupId
    self.GuideId = itemData.GuideId
    self.StageId = itemData.StageId
    self.TeamId = itemData.TeamId
    self.BuffGroupDetails = XFubenBabelTowerConfigs.GetBabelBuffGroupConfigs(self.BuffGroupId)
    self.BuffGroupTemplate = XFubenBabelTowerConfigs.GetBabelTowerBuffGroupTemplate(self.BuffGroupId)

    self.TxtChallengeName.text = self.BuffGroupDetails.Name
    self:InitChallengeList()
end

function XUiBabelTowerChallengeChoice:OnBtnGuideMaskClick()
    if self.GuideId then
        if not XDataCenter.FubenBabelTowerManager.IsStageGuideAuto(self.GuideId) then
            XUiManager.TipMsg(CS.XTextManager.GetText("BabelTowerGuideStageCanntSelect"))
            return
        end
    end
    self.BtnGuideMask.gameObject:SetActiveEx(false)
end

function XUiBabelTowerChallengeChoice:InitChallengeList()
    for i = 1, #self.BuffGroupTemplate.BuffId do
        local buffId = self.BuffGroupTemplate.BuffId[i]
        local buffTemplate = XFubenBabelTowerConfigs.GetBabelTowerBuffTemplate(buffId)
        local buffConfigs = XFubenBabelTowerConfigs.GetBabelBuffConfigs(buffId)
        if not self.ChallengeItemList[i] then
            local go = CS.UnityEngine.Object.Instantiate(self.GridChallenge)
            go.transform:SetParent(self.GridContent.transform, false)
            self.ChallengeItemList[i] = XUiGridBabelChallengeItem.New(go, self, i, XFubenBabelTowerConfigs.TYPE_CHALLENGE)
        end
        self.ChallengeItemList[i].GameObject:SetActiveEx(true)
        self.ChallengeItemList[i]:UpdateBuff(buffTemplate, buffConfigs, i, XFubenBabelTowerConfigs.TYPE_CHALLENGE)
        self.ChallengeBtnCompList[i] = self.ChallengeItemList[i]:GetXUiButtonComp()
        self.ChallengeBtnCompList[i]:ShowTag(false)

        local isLock = self:IsBuffLock(buffId)
        if isLock then
            self.ChallengeBtnCompList[i]:SetButtonState(UiButtonState.Disable)
        end
    end

    local isAutoGuide = XDataCenter.FubenBabelTowerManager.IsStageGuideAuto(self.GuideId)
    if isAutoGuide then
        self.GridContent:Init(self.ChallengeBtnCompList, function(index) self:OnChallengeChoiceItemClick(index) end)
        self.GridContent.CanDisSelect = true
        self.GridContent.CurSelectId = self.BuffGoupDatas.CurSelectId

        if self.BuffGoupDatas.IsFirstInit then
            local cache = XDataCenter.FubenBabelTowerManager.GetBuffListCacheByStageId(self.StageId, self.TeamId)
            local index = self:GetBuffIndexByGroupId(self.BuffGroupId, cache[self.BuffGroupId])
            if index ~= -1 then
                self.GridContent:SelectIndex(index)
            end
            self.BuffGoupDatas.IsFirstInit = false
        end
    else
        self:InitAutoStageGuide()
    end
    self.BtnGuideMask.gameObject:SetActiveEx(not isAutoGuide)


    for i = #self.BuffGroupTemplate.BuffId + 1, #self.ChallengeItemList do
        self.ChallengeItemList[i].GameObject:SetActiveEx(false)
    end

    local isHard = XFubenBabelTowerConfigs.IsBuffGroupHard(self.BuffGroupId)
    self.ImgBgHard.gameObject:SetActiveEx(isHard)
    self.TxtChallengeName.color = CONDITION_COLOR[isHard]
end

function XUiBabelTowerChallengeChoice:GetBuffIndexByGroupId(groupId, buffId)
    local index = -1
    if not buffId then return index end
    local groupDatas = XFubenBabelTowerConfigs.GetBabelTowerBuffGroupTemplate(groupId)
    for i = 1, #groupDatas.BuffId do
        if buffId == groupDatas.BuffId[i] then
            index = i
            break
        end
    end
    return index
end

function XUiBabelTowerChallengeChoice:InitAutoStageGuide()
    local stageGuideTemplate = XFubenBabelTowerConfigs.GetBabelTowerStageGuideTemplate(self.GuideId)

    local selectBuffId = nil
    for index, buffGroupId in pairs(stageGuideTemplate.BuffGroup or {}) do
        if buffGroupId == self.BuffGroupId then
            selectBuffId = stageGuideTemplate.BuffId[index]
        end
    end

    for i = 1, #self.BuffGroupTemplate.BuffId do
        if selectBuffId and selectBuffId == self.BuffGroupTemplate.BuffId[i] then
            self.ChallengeBtnCompList[i]:SetButtonState(UiButtonState.Select)
            self.ChallengeBtnCompList[i]:ShowTag(true)
        else
            self.ChallengeBtnCompList[i]:SetButtonState(UiButtonState.Disable)
            self.ChallengeBtnCompList[i]:ShowTag(false)
        end
        self.ChallengeBtnCompList[i].enabled = false
    end
end

-- buttonGroup方式选中
function XUiBabelTowerChallengeChoice:OnChallengeChoiceItemClick(index)
    local currentSelectBuffId = self.BuffGroupTemplate.BuffId[index]
    if self:IsBuffLock(currentSelectBuffId) then
        local openLevel = XFubenBabelTowerConfigs.GetStageDifficultLockBuffIdOpenLevel(self.StageId, currentSelectBuffId)
        openLevel = openLevel <= XFubenBabelTowerConfigs.Difficult.Count and openLevel + 1 or openLevel
        local diffName = XFubenBabelTowerConfigs.GetStageDifficultName(self.StageId, openLevel)
        local tip = CSXTextManagerGetText("BabelTowerStageLevelBuffLocked", diffName)
        XUiManager.TipMsg(tip)
        return
    end

    if self.BuffGoupDatas.SelectedBuffId == currentSelectBuffId then
        self.BuffGoupDatas.SelectedBuffId = nil
        self.BuffGoupDatas.CurSelectId = -1
    else
        -- 取消检查
        local currentCount = 0
        for k, v in pairs(self.UiRoot.UiRoot.TeamList) do
            if v > 0 then
                currentCount = currentCount + 1
            end
        end

        local selectBuffLimitCount = XFubenBabelTowerConfigs.GetBuffTeamLimitCount(currentSelectBuffId)
        if selectBuffLimitCount < currentCount then
            self.ChallengeBtnCompList[index]:SetButtonState(CS.UiButtonState.Normal)
            XUiManager.TipError(XUiHelper.GetText("BabelTowerTeamSelectLimit"))
            return 
        end
        self.BuffGoupDatas.SelectedBuffId = currentSelectBuffId
        self.BuffGoupDatas.CurSelectId = index
    end
    self.UiRoot:UpdateChoosedChallengeDatas(self.BuffGroupId, self.BuffGoupDatas.SelectedBuffId)
end

function XUiBabelTowerChallengeChoice:GetBuffSelectStatus(buffId)
    if not self.BuffGoupDatas then return false end
    return self.BuffGoupDatas.SelectedBuffId == buffId
end

function XUiBabelTowerChallengeChoice:IsBuffListOverCount()
    return false
end

function XUiBabelTowerChallengeChoice:IsBuffLock(buffId)
    local selectDifficult = XDataCenter.FubenBabelTowerManager.GetTeamSelectDifficult(self.StageId, self.TeamId)
    local openLevel = XFubenBabelTowerConfigs.GetStageDifficultLockBuffIdOpenLevel(self.StageId, buffId)
    return openLevel and openLevel ~= 0 and selectDifficult <= openLevel or false
end

return XUiBabelTowerChallengeChoice