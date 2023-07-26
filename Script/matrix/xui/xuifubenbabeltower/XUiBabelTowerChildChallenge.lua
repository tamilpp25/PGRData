local XUiBabelTowerChallengeChoice = require("XUi/XUiFubenBabelTower/XUiBabelTowerChallengeChoice")
local XUiBabelTowerChallengeSelect = require("XUi/XUiFubenBabelTower/XUiBabelTowerChallengeSelect")

local CSXTextManagerGetText = CS.XTextManager.GetText

---@class UiBabelTowerChildChallenge : XLuaUi
local XUiBabelTowerChildChallenge = XLuaUiManager.Register(XLuaUi, "UiBabelTowerChildChallenge")

function XUiBabelTowerChildChallenge:OnAwake()
    self.BtnNext.CallBack = function() self:OnBtnNextClick() end
    self.BtnDifficult.CallBack = function() self:OnClickBtnDifficult() end
    self.BtnChallenge.CallBack = function() self:OnBtnChallengeClick() end

    self.DynamicTableChallengeChoice = XDynamicTableNormal.New(self.PanelChallengeChoice.gameObject)
    self.DynamicTableChallengeChoice:SetProxy(XUiBabelTowerChallengeChoice)
    self.DynamicTableChallengeChoice:SetDelegate(self)
    self.DynamicTableChallengeChoice:SetDynamicEventDelegate(function(event, index, grid)
        self:OnChallengeChoiceDynamicTableEvent(event, index, grid)
    end)

    self.SelectChoiceList = {}

    self.ChoosedChallengeList = {}
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
    self:GenChallengeGroupDatas()
    self:GenChallengeSelectDatas()
    if XDataCenter.FubenBabelTowerManager.IsStageGuideAuto(self.GuideId) then
        self:InitDefaultSelect()
    else
        self:UpdateChoosedChallengeDatasByStageGuide()
    end
end

function XUiBabelTowerChildChallenge:OnEnable()
    self.DynamicTableChallengeChoice:SetDataSource(self.ChallengeBuffGroup)
    self.DynamicTableChallengeChoice:ReloadDataASync()
    self:SetChallengeScore()
end

function XUiBabelTowerChildChallenge:RefreshSelectChoiceList(index)
    if self.ChoosedChallengeList then
        local chooseCount = #self.ChoosedChallengeList
        for i = 1, chooseCount do
            if not self.SelectChoiceList[i] then
                local ui = CS.UnityEngine.Object.Instantiate(self.GridSelectChoice)
                ui.transform:SetParent(self.PanelChoiceContainer, false)
                self.SelectChoiceList[i] = XUiBabelTowerChallengeSelect.New(ui, self)
            end

            self.SelectChoiceList[i].GameObject:SetActiveEx(true)
            self.SelectChoiceList[i]:SetItemData(self.ChoosedChallengeList[i], XFubenBabelTowerConfigs.TYPE_CHALLENGE)
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
    if self.ChoosedChallengeList then
        for i = 1, #self.ChoosedChallengeList do
            self.SelectChoiceList[i]:StopFx()
        end
    end
end

function XUiBabelTowerChildChallenge:CenterToGrid(grid, index)
    local normalizedPosition
    local count = #self.SelectChoiceList
    local itemTotalCount = #self.ChoosedChallengeList
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

function XUiBabelTowerChildChallenge:OnChallengeChoiceDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        if self.ChallengeBuffGroup[index] then
            grid:SetItemData(self.ChallengeBuffGroup[index])
        end
    end
end

function XUiBabelTowerChildChallenge:OnChallengeSelectDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        if self.ChoosedChallengeList[index] then
            grid:SetItemData(self.ChoosedChallengeList[index], XFubenBabelTowerConfigs.TYPE_CHALLENGE)
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
    self.ChoosedChallengeList = {}
    local cache = XDataCenter.FubenBabelTowerManager.GetBuffListCacheByStageId(self.StageId, self.TeamId)
    for i = 1, #self.ChallengeBuffSelectGroup do
        local groupItem = self.ChallengeBuffSelectGroup[i]
        local buffId = cache[groupItem.BuffGroupId]
        groupItem.SelectBuffId = buffId
        if buffId and buffId ~= 0 and not self.UiRoot:IsBuffLock(buffId) then
            table.insert(self.ChoosedChallengeList, groupItem)
        end
    end

    self:ReportChallengeChoice()
    -- self.DynamicTableChallengeSelect:SetDataSource(self.ChoosedChallengeList)
    -- self.DynamicTableChallengeSelect:ReloadDataASync()
    self:RefreshSelectChoiceList()
    self:UpdateCurChallengeScore(self.ChoosedChallengeList)
end

function XUiBabelTowerChildChallenge:SetChallengeScore()
    local stageId = self.StageId
    local teamId = self.TeamId

    local selectDifficult = XDataCenter.FubenBabelTowerManager.GetTeamSelectDifficult(stageId, teamId)

    local recommendAblity = XFubenBabelTowerConfigs.GetStageDifficultRecommendAblity(stageId, selectDifficult)
    self.TxtAbility.text = recommendAblity

    local name = XFubenBabelTowerConfigs.GetStageDifficultName(stageId, selectDifficult)
    self.TxtDifficult.text = name

    local ratio = XFubenBabelTowerConfigs.GetStageDifficultRatio(stageId, selectDifficult)
    self.TxtRatio.text = CSXTextManagerGetText("BabelTowerUiBaseRatio", ratio)

    local maxScore = XDataCenter.FubenBabelTowerManager.GetTeamMaxScore(stageId, teamId)
    self.TxtChallengeTop.text = CSXTextManagerGetText("BabelTowerCurMaxScore", maxScore)
end

-- 保存一份数据，记录玩家选中的挑战项SelectBuffList = {buffId = isSelect}
function XUiBabelTowerChildChallenge:GenChallengeGroupDatas()
    if self.ChallengeBuffGroup then return self.ChallengeBuffGroup end
    self.ChallengeBuffGroup = {}
    for i = 1, #self.BabelTowerStageTemplate.ChallengeBuffGroup do
        local groupId = self.BabelTowerStageTemplate.ChallengeBuffGroup[i]
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

function XUiBabelTowerChildChallenge:GenChallengeSelectDatas()
    self.ChallengeBuffSelectGroup = {}
    for i = 1, #self.BabelTowerStageTemplate.ChallengeBuffGroup do
        table.insert(self.ChallengeBuffSelectGroup, {
            BuffGroupId = self.BabelTowerStageTemplate.ChallengeBuffGroup[i],
            SelectBuffId = nil,
        })
    end
end

-- 设置已选战略组
-- buffgroup组选中了一个buffId,如果buffId为空，则该buffgroup组没有选中任何一个buff
function XUiBabelTowerChildChallenge:UpdateChoosedChallengeDatas(buffGroupId, buffId)
    if not self.ChallengeBuffSelectGroup then self:GenChallengeSelectDatas() end
    -- isExist
    if self.ChoosedChallengeList and #self.ChoosedChallengeList > 0 then
        for _, v in pairs(self.ChoosedChallengeList) do
            if v.BuffGroupId == buffGroupId and buffId and v.SelectBuffId == buffId then
                return
            end
        end
    end

    self.ChoosedChallengeList = {}

    for i = 1, #self.ChallengeBuffSelectGroup do
        local groupItem = self.ChallengeBuffSelectGroup[i]
        if groupItem.BuffGroupId == buffGroupId then
            groupItem.SelectBuffId = buffId
        end
        if groupItem.SelectBuffId and groupItem.SelectBuffId ~= 0 and self.UiRoot:IsBuffLock(groupItem.SelectBuffId) then
            groupItem.SelectBuffId = nil
        end
        if groupItem.SelectBuffId then
            table.insert(self.ChoosedChallengeList, groupItem)
        end
    end

    if self.ChoosedChallengeList then
        for k = #self.ChoosedChallengeList, 1, -1 do
            local selectBuffId = self.ChoosedChallengeList[k].SelectBuffId
            if not selectBuffId or selectBuffId ~= 0 and self.UiRoot:IsBuffLock(selectBuffId) then
                table.remove(self.ChoosedChallengeList, k)
            end
        end
    end

    local index = 0
    for i = 1, #self.ChoosedChallengeList do
        local groupItem = self.ChoosedChallengeList[i]
        if groupItem.BuffGroupId == buffGroupId and groupItem.SelectBuffId and groupItem.SelectBuffId == buffId then
            index = i
            break
        end
    end

    -- 通知支持面板做一些操作
    self:ReportChallengeChoice()
    self:RefreshSelectChoiceList(index)
    self.ImgEmpty.gameObject:SetActiveEx(#self.ChoosedChallengeList <= 0)
    self:UpdateCurChallengeScore(self.ChoosedChallengeList)
end

-- 非自选战略
function XUiBabelTowerChildChallenge:UpdateChoosedChallengeDatasByStageGuide()
    local stageGuideTemplate = XFubenBabelTowerConfigs.GetBabelTowerStageGuideTemplate(self.GuideId)
    self.ChoosedChallengeList = {}
    for i = 1, #stageGuideTemplate.BuffGroup do
        table.insert(self.ChoosedChallengeList, {
            BuffGroupId = stageGuideTemplate.BuffGroup[i],
            SelectBuffId = stageGuideTemplate.BuffId[i]
        })
    end
    self:ReportChallengeChoice()
    -- self.DynamicTableChallengeSelect:SetDataSource(self.ChoosedChallengeList)
    -- self.DynamicTableChallengeSelect:ReloadDataASync()
    self:RefreshSelectChoiceList()
    self.ImgEmpty.gameObject:SetActiveEx(#self.ChoosedChallengeList <= 0)
    self:UpdateCurChallengeScore(self.ChoosedChallengeList)
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
    self.UiRoot:UpdateChallengeBuffInfos(self.ChoosedChallengeList)
end

function XUiBabelTowerChildChallenge:DealDiffRealatedData(isShowTip)
    local dataChanged = false

    if self.ChoosedChallengeList then
        for k = #self.ChoosedChallengeList, 1, -1 do
            local buffId = self.ChoosedChallengeList[k].SelectBuffId
            if buffId ~= 0 and self.UiRoot:IsBuffLock(buffId) then
                table.remove(self.ChoosedChallengeList, k)
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
            if buffId ~= 0 and self.UiRoot:IsBuffLock(buffId) then
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
        self:DealDiffRealatedData(true)
        self:ReportChallengeChoice()
        self:RefreshSelectChoiceList()
        self.DynamicTableChallengeChoice:ReloadDataASync()
        self:SetChallengeScore()
        self:UpdateCurChallengeScore(self.ChoosedChallengeList)
    end)
end

function XUiBabelTowerChildChallenge:FilterChoosedChallengeList()
    local dataChanged = self:DealDiffRealatedData()
    if dataChanged then
        self:ReportChallengeChoice()
        self:RefreshSelectChoiceList()
        self:UpdateCurChallengeScore(self.ChoosedChallengeList)
    end
end