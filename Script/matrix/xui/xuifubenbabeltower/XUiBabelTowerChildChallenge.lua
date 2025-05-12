local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiBabelTowerChallengeChoice = require("XUi/XUiFubenBabelTower/XUiBabelTowerChallengeChoice")
local XUiBabelTowerChallengeSelect = require("XUi/XUiFubenBabelTower/XUiBabelTowerChallengeSelect")

local CSXTextManagerGetText = CS.XTextManager.GetText

---@class XUiBabelTowerChildChallenge : XLuaUi
local XUiBabelTowerChildChallenge = XLuaUiManager.Register(XLuaUi, "UiBabelTowerChildChallenge")

function XUiBabelTowerChildChallenge:OnAwake()
    self.BtnNext.CallBack = function() self:OnBtnNextClick() end
    --self.BtnDifficult.CallBack = function() self:OnClickBtnDifficult() end
    self.BtnChallenge.CallBack = function() self:OnBtnChallengeClick() end

    self.DynamicTableChallengeChoice = XDynamicTableNormal.New(self.PanelChallengeChoice.gameObject)
    self.DynamicTableChallengeChoice:SetProxy(XUiBabelTowerChallengeChoice)
    self.DynamicTableChallengeChoice:SetDelegate(self)
    self.DynamicTableChallengeChoice:SetDynamicEventDelegate(function(event, index, grid)
        self:OnChallengeChoiceDynamicTableEvent(event, index, grid)
    end)

    self.SelectChoiceList = {}

    self.ChooseChallengeList = {}
    self.ChallengeBuffSelectGroup = {}
    self.RightRectTransform = self.PanelRight:GetComponent("RectTransform")
    self.GridChoice.gameObject:SetActiveEx(false)
end

---@param uiRoot UiBabelTowerBase
function XUiBabelTowerChildChallenge:OnStart(uiRoot, stageId, guideId, teamId)
    self.UiRoot = uiRoot
    self.StageId = stageId
    self.GuideId = guideId
    self.TeamId = teamId
    self.BabelTowerStageTemplate = XFubenBabelTowerConfigs.GetBabelTowerStageTemplate(self.StageId)
    self:GenChallengeGroupData()
    self:GenChallengeSelectData()
    if XDataCenter.FubenBabelTowerManager.IsStageGuideAuto(self.GuideId) then
        self:InitDefaultSelect()
    else
        self:UpdateChooseChallengeDataByStageGuide()
    end
end

function XUiBabelTowerChildChallenge:OnEnable()
    self.DynamicTableChallengeChoice:SetDataSource(self.ChallengeBuffGroup)
    self.DynamicTableChallengeChoice:ReloadDataASync()
    self:SetChallengeScore()
end

function XUiBabelTowerChildChallenge:RefreshSelectChoiceList(index)
    if self.ChooseChallengeList then
        local chooseCount = #self.ChooseChallengeList
        for i = 1, chooseCount do
            if not self.SelectChoiceList[i] then
                local ui = CS.UnityEngine.Object.Instantiate(self.GridSelectChoice)
                ui.transform:SetParent(self.PanelChoiceContainer, false)
                self.SelectChoiceList[i] = XUiBabelTowerChallengeSelect.New(ui, self)
            end

            self.SelectChoiceList[i].GameObject:SetActiveEx(true)
            self.SelectChoiceList[i]:SetItemData(self.ChooseChallengeList[i], XFubenBabelTowerConfigs.TYPE_CHALLENGE)
        end

        for i = chooseCount + 1, #self.SelectChoiceList do
            self.SelectChoiceList[i].GameObject:SetActiveEx(false)
        end
        -- 默认选中
        if index and index > 0 and index <= chooseCount then
            self:CenterToGrid(self.SelectChoiceList[index], index)
            self.SelectChoiceList[index]:PlayFx()
        end

        self.ImgEmpty.gameObject:SetActiveEx(chooseCount <= 0)
    end
end

function XUiBabelTowerChildChallenge:OnDisable()
    if self.ChooseChallengeList then
        for i = 1, #self.ChooseChallengeList do
            self.SelectChoiceList[i]:StopFx()
        end
    end
end

function XUiBabelTowerChildChallenge:CenterToGrid(grid, index)
    local normalizedPosition
    local count = #self.SelectChoiceList
    local itemTotalCount = #self.ChooseChallengeList
    local totalHeight = 0
    local curHeight = 0
    for i = 1, count do
        local itemHeight = self.SelectChoiceList[i]:GetBuffDescriptionHeight()
        totalHeight = totalHeight + itemHeight
        if i <= index then
            curHeight = curHeight + itemHeight
        end
    end

    local offset = 0
    if index + 1 <= itemTotalCount then
        offset = self.SelectChoiceList[index + 1]:GetBuffDescriptionHeight()
    end
    if curHeight > totalHeight / 2 then
        normalizedPosition = (curHeight + offset) / totalHeight
    else
        normalizedPosition = (curHeight - offset) / totalHeight
    end

    self.DelayTimer = XScheduleManager.ScheduleOnce(function()
        self.PanelSelectChallenge.verticalNormalizedPosition = math.max(0, math.min(1, (1 - normalizedPosition)))
        XScheduleManager.UnSchedule(self.DelayTimer)
    end, 50)
end

function XUiBabelTowerChildChallenge:OnDestroy()
    if self.DelayTimer then
        XScheduleManager.UnSchedule(self.DelayTimer)
        self.DelayTimer = nil
    end
end

---@param grid XUiBabelTowerChallengeChoice
function XUiBabelTowerChildChallenge:OnChallengeChoiceDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        if self.ChallengeBuffGroup[index] then
            grid:SetItemData(self.ChallengeBuffGroup[index])
        end
    end
end

function XUiBabelTowerChildChallenge:OnBtnNextClick()
    self.UiRoot:Switch2SupportPhase()
end

function XUiBabelTowerChildChallenge:OnBtnChallengeClick()
    XLuaUiManager.Open("UiBabelTowerDetails", XFubenBabelTowerConfigs.TIPSTYPE_CHALLENGE, self.StageId)
end

function XUiBabelTowerChildChallenge:InitDefaultSelect()
    self.ChooseChallengeList = {}
    local cache = XDataCenter.FubenBabelTowerManager.GetBuffListCacheByStageId(self.StageId, self.TeamId)
    for i = 1, #self.ChallengeBuffSelectGroup do
        local groupItem = self.ChallengeBuffSelectGroup[i]
        local buffId = cache[groupItem.BuffGroupId]
        groupItem.SelectBuffId = buffId
        if buffId and buffId ~= 0 and not self.UiRoot:IsBuffLock(buffId) then
            table.insert(self.ChooseChallengeList, groupItem)
        end
    end

    self:ReportChallengeChoice()
    self:RefreshSelectChoiceList()
    self:UpdateCurChallengeScore(self.ChooseChallengeList)
end

function XUiBabelTowerChildChallenge:SetChallengeScore(isRefresh)
    local stageId = self.StageId
    local teamId = self.TeamId

    local selectDifficult = XDataCenter.FubenBabelTowerManager.GetTeamSelectDifficult(stageId, teamId)

    local recommendAbility = XFubenBabelTowerConfigs.GetStageDifficultRecommendAbility(stageId, selectDifficult)
    self.TxtAbility.text = recommendAbility

    local name = XFubenBabelTowerConfigs.GetStageDifficultName(stageId, selectDifficult)
    self.TxtDifficult.text = name

    local ratio = XFubenBabelTowerConfigs.GetStageDifficultRatio(stageId, selectDifficult)
    self.TxtRatio.text = CSXTextManagerGetText("BabelTowerUiBaseRatio", ratio)

    local maxScore = XDataCenter.FubenBabelTowerManager.GetTeamMaxScore(stageId, teamId)
    self.TxtChallengeTop.text = CSXTextManagerGetText("BabelTowerCurMaxScore", maxScore)

    if isRefresh then
        self:FilterChooseChallengeList()
        self.DynamicTableChallengeChoice:ReloadDataSync()
    end
end

-- 保存一份数据，记录玩家选中的挑战项SelectBuffList = {buffId = isSelect}
function XUiBabelTowerChildChallenge:GenChallengeGroupData()
    if not XTool.IsTableEmpty(self.ChallengeBuffGroup) then
        return self.ChallengeBuffGroup
    end
    self.ChallengeBuffGroup = {}
    local buffGroupIds = self.BabelTowerStageTemplate.ChallengeBuffGroup or {}
    for _, groupId in pairs(buffGroupIds) do
        table.insert(self.ChallengeBuffGroup, {
            StageId = self.StageId,
            GuideId = self.GuideId,
            TeamId = self.TeamId,
            BuffGroupId = groupId,
            SelectedBuffId = nil,
            CurSelectId = -1,
            IsFirstInit = true
        })
    end
end

function XUiBabelTowerChildChallenge:GenChallengeSelectData()
    self.ChallengeBuffSelectGroup = {}
    local buffGroupIds = self.BabelTowerStageTemplate.ChallengeBuffGroup or {}
    for _, groupId in pairs(buffGroupIds) do
        table.insert(self.ChallengeBuffSelectGroup, {
            BuffGroupId = groupId,
            SelectBuffId = nil,
        })
    end
end

-- 设置已选战略组
-- buffGroup组选中了一个buffId,如果buffId为空，则该buffGroup组没有选中任何一个buff
function XUiBabelTowerChildChallenge:UpdateChooseChallengeData(buffGroupId, buffId)
    if not self.ChallengeBuffSelectGroup then self:GenChallengeSelectData() end
    -- isExist
    if self.ChooseChallengeList and #self.ChooseChallengeList > 0 then
        for _, v in pairs(self.ChooseChallengeList) do
            if v.BuffGroupId == buffGroupId and buffId and v.SelectBuffId == buffId then
                return
            end
        end
    end

    self.ChooseChallengeList = {}

    for i = 1, #self.ChallengeBuffSelectGroup do
        local groupItem = self.ChallengeBuffSelectGroup[i]
        if groupItem.BuffGroupId == buffGroupId then
            groupItem.SelectBuffId = buffId
        end
        if groupItem.SelectBuffId and groupItem.SelectBuffId ~= 0 and self.UiRoot:IsBuffLock(groupItem.SelectBuffId) then
            groupItem.SelectBuffId = nil
        end
        if groupItem.SelectBuffId then
            table.insert(self.ChooseChallengeList, groupItem)
        end
    end

    if self.ChooseChallengeList then
        for k = #self.ChooseChallengeList, 1, -1 do
            local selectBuffId = self.ChooseChallengeList[k].SelectBuffId
            if not selectBuffId or selectBuffId ~= 0 and self.UiRoot:IsBuffLock(selectBuffId) then
                table.remove(self.ChooseChallengeList, k)
            end
        end
    end

    local index = 0
    for i = 1, #self.ChooseChallengeList do
        local groupItem = self.ChooseChallengeList[i]
        if groupItem.BuffGroupId == buffGroupId and groupItem.SelectBuffId and groupItem.SelectBuffId == buffId then
            index = i
            break
        end
    end

    -- 通知支持面板做一些操作
    self:ReportChallengeChoice()
    self:RefreshSelectChoiceList(index)
    self.ImgEmpty.gameObject:SetActiveEx(#self.ChooseChallengeList <= 0)
    self:UpdateCurChallengeScore(self.ChooseChallengeList)
end

-- 非自选战略
function XUiBabelTowerChildChallenge:UpdateChooseChallengeDataByStageGuide()
    local stageGuideTemplate = XFubenBabelTowerConfigs.GetBabelTowerStageGuideTemplate(self.GuideId)
    self.ChooseChallengeList = {}
    for i = 1, #stageGuideTemplate.BuffGroup do
        table.insert(self.ChooseChallengeList, {
            BuffGroupId = stageGuideTemplate.BuffGroup[i],
            SelectBuffId = stageGuideTemplate.BuffId[i]
        })
    end
    self:ReportChallengeChoice()
    self:RefreshSelectChoiceList()
    self.ImgEmpty.gameObject:SetActiveEx(#self.ChooseChallengeList <= 0)
    self:UpdateCurChallengeScore(self.ChooseChallengeList)
end

function XUiBabelTowerChildChallenge:UpdateCurChallengeScore(challengeList)
    local totalChallengeScore = 0
    if self.BabelTowerStageTemplate then
        totalChallengeScore = self.BabelTowerStageTemplate.BaseScore
    end
    for _, v in pairs(challengeList or {}) do
        local buffTemplate = XFubenBabelTowerConfigs.GetBabelTowerBuffTemplate(v.SelectBuffId)
        totalChallengeScore = totalChallengeScore + (buffTemplate.ScoreAdd or 0)
    end

    local selectDifficult = XDataCenter.FubenBabelTowerManager.GetTeamSelectDifficult(self.StageId, self.TeamId)
    local ratio = XFubenBabelTowerConfigs.GetStageDifficultRatio(self.StageId, selectDifficult)
    self.TxtChallengeNumber.text = math.floor(totalChallengeScore * ratio)
end

function XUiBabelTowerChildChallenge:ReportChallengeChoice()
    self.UiRoot:UpdateChallengeBuffInfos(self.ChooseChallengeList)
end

function XUiBabelTowerChildChallenge:DealDiffRelatedData(isShowTip)
    local dataChanged = false

    if self.ChooseChallengeList then
        for k = #self.ChooseChallengeList, 1, -1 do
            local buffId = self.ChooseChallengeList[k].SelectBuffId
            if buffId ~= 0 and self.UiRoot:IsBuffLock(buffId) then
                table.remove(self.ChooseChallengeList, k)
                dataChanged = true
            end
        end
    end

    for i = 1, #self.ChallengeBuffSelectGroup do
        local groupItem = self.ChallengeBuffSelectGroup[i]
        if groupItem.SelectBuffId and groupItem.SelectBuffId ~= 0 and self.UiRoot:IsBuffLock(groupItem.SelectBuffId) then
            groupItem.SelectBuffId = nil
        end
    end

    if self.ChallengeBuffGroup then
        for k = #self.ChallengeBuffGroup, 1, -1 do
            local data = self.ChallengeBuffGroup[k]
            local buffId = data.SelectedBuffId
            if buffId and buffId ~= 0 and self.UiRoot:IsBuffLock(buffId) then
                data.SelectedBuffId = nil
                data.CurSelectId = -1
                dataChanged = true
            end
        end
    end

    if dataChanged and isShowTip then
        XUiManager.TipText("BabelTowerStageLevelBuffChanged")
    end

    return dataChanged
end

function XUiBabelTowerChildChallenge:OnClickBtnDifficult()
    XLuaUiManager.Open("UiBabelTowerSelectDiffcult", self.StageId, self.TeamId, function()
        self:DealDiffRelatedData(true)
        self:ReportChallengeChoice()
        self:RefreshSelectChoiceList()
        self.DynamicTableChallengeChoice:ReloadDataASync()
        self:SetChallengeScore()
        self:UpdateCurChallengeScore(self.ChooseChallengeList)
    end)
end

function XUiBabelTowerChildChallenge:FilterChooseChallengeList()
    local dataChanged = self:DealDiffRelatedData()
    if dataChanged then
        self:ReportChallengeChoice()
        self:RefreshSelectChoiceList()
        self:UpdateCurChallengeScore(self.ChooseChallengeList)
    end
end

return XUiBabelTowerChildChallenge
