local XUiBabelTowerChildSupport = XLuaUiManager.Register(XLuaUi, "UiBabelTowerChildSupport")

local XUiBabelMemberHead = require("XUi/XUiFubenBabelTower/XUiBabelMemberHead")
local XUiBabelTowerSupportChoice = require("XUi/XUiFubenBabelTower/XUiBabelTowerSupportChoice")
local XUiBabelTowerChallengeSelect = require("XUi/XUiFubenBabelTower/XUiBabelTowerChallengeSelect")

function XUiBabelTowerChildSupport:OnAwake()
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnGo.CallBack = function() self:OnBtnGoClick() end
    self.BtnSupport.CallBack = function() self:OnBtnSupportClick() end

    self.TeamMemberList = {}
    for i = 1, XFubenBabelTowerConfigs.MAX_TEAM_MEMBER do
        self.TeamMemberList[i] = XUiBabelMemberHead.New(self[string.format("TeamMember%d", i)], i)
        self.TeamMemberList[i]:ClearMemberHead()
        self.TeamMemberList[i]:SetMemberCallBack(function()
            self:OnBtnGoClick()
        end)
    end

    self.DynamicTableSupportChoice = XDynamicTableNormal.New(self.PanelSupportChoice.gameObject)
    self.DynamicTableSupportChoice:SetProxy(XUiBabelTowerSupportChoice)
    self.DynamicTableSupportChoice:SetDelegate(self)
    self.DynamicTableSupportChoice:SetDynamicEventDelegate(function(event, index, grid)
        self:OnSupportChoiceDynamicTableEvent(event, index, grid)
    end)

    self.SelectChoiceList = {}

    self.ChoosedSupportList = {}
    self.SupportBuffSelectGroup = {}

    XEventManager.AddEventListener(XEventId.EVNET_BABEL_CHALLENGE_BUFF_CHANGED, self.CheckTeamBanCharacterList, self)
end

function XUiBabelTowerChildSupport:OnStart(uiRoot, stageId, guideId, teamId, teamList, captainPos, firstFightPos)
    self.UiRoot = uiRoot
    self.StageId = stageId
    self.GuideId = guideId
    self.TeamId = teamId
    self.TeamList = teamList
    self.CaptainPos = captainPos
    self.FirstFightPos = firstFightPos
    self.BabelTowerStageTemplate = XFubenBabelTowerConfigs.GetBabelTowerStageTemplate(self.StageId)

    self:GetTotalSupportPoint()
    self:SetSupportChoiceDatas()

    -- 初始化检查一遍阵容
    self:CheckTeamBanCharacterList()
    self:InitSupportBuff()
end

function XUiBabelTowerChildSupport:OnEnable()
    self:SetTeamListDatas()
    self:ReportTeamList()
    self:OnUpdateTeamMemberEnd()
end

function XUiBabelTowerChildSupport:OnDisable()
    if self.ChoosedSupportList then
        for i = 1, #self.ChoosedSupportList do
            self.SelectChoiceList[i]:StopFx()
        end
    end
end

function XUiBabelTowerChildSupport:OnDestroy()
    if self.DelayTimer then
        XScheduleManager.UnSchedule(self.DelayTimer)
        self.DelayTimer = nil
    end
    XEventManager.RemoveEventListener(XEventId.EVNET_BABEL_CHALLENGE_BUFF_CHANGED, self.CheckTeamBanCharacterList, self)
end

function XUiBabelTowerChildSupport:RefreshSelectChoiceList(index)
    if self.ChoosedSupportList then
        local chooseCount = #self.ChoosedSupportList
        for i = 1, chooseCount do
            if not self.SelectChoiceList[i] then
                local ui = CS.UnityEngine.Object.Instantiate(self.GridSelectSupportChoice)
                ui.transform:SetParent(self.PanelChoiceContainer, false)
                ui.gameObject:SetActiveEx(true)
                self.SelectChoiceList[i] = XUiBabelTowerChallengeSelect.New(ui, self)
            end
            self.SelectChoiceList[i].GameObject:SetActiveEx(true)
            self.SelectChoiceList[i]:SetItemData(self.ChoosedSupportList[i], XFubenBabelTowerConfigs.TYPE_SUPPORT)
        end

        for i = chooseCount + 1, #self.SelectChoiceList do
            self.SelectChoiceList[i].GameObject:SetActiveEx(false)
        end

        if index and index > 0 and index <= chooseCount then
            self:CenterToGrid(self.SelectChoiceList[index], index)
            self.SelectChoiceList[index]:PlayFx()
        end
    end
end

function XUiBabelTowerChildSupport:CenterToGrid(grid, index)
    local normalizedPosition
    local count = #self.SelectChoiceList
    local itemTotalCount = #self.ChoosedSupportList
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
        self.PanelSelectSupport.verticalNormalizedPosition = math.max(0, math.min(1, (1 - normalizedPosition)))
        XScheduleManager.UnSchedule(self.DelayTimer)
    end, 50)
end

function XUiBabelTowerChildSupport:CheckTeamBanCharacterList()
    local banCharacters = XDataCenter.FubenBabelTowerManager.GetBanCharacterIdsByBuff(self.UiRoot.ChallengeBuffInfos)
    for i = 1, XFubenBabelTowerConfigs.MAX_TEAM_MEMBER do
        local curChar = self.TeamList[i]
        if curChar ~= nil and curChar ~= 0 and banCharacters[curChar] then
            self.TeamList[i] = 0
            self.TeamMemberList[i]:SetMemberInfo(self.TeamList[i], nil, self.CaptainPos)
        end
    end
end

-- 仅此一份,其他界面都以这个为准
function XUiBabelTowerChildSupport:GetTeamList()
    return self.TeamList
end

function XUiBabelTowerChildSupport:OnSupportChoiceDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        if self.SupportBuffGroup[index] then
            grid:SetItemData(self.SupportBuffGroup[index])
        end
    end
end

function XUiBabelTowerChildSupport:OnSupportSelectDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        if self.ChoosedSupportList[index] then
            grid:SetItemData(self.ChoosedSupportList[index], XFubenBabelTowerConfigs.TYPE_SUPPORT)
        end
    end
end

function XUiBabelTowerChildSupport:OnBtnBackClick()
    self.UiRoot:Switch2ChallengePhase()
end

function XUiBabelTowerChildSupport:OnBtnGoClick()
    local teamList = XDataCenter.FubenBabelTowerManager.GetCacheTeam(self.StageId, self.TeamId, self.TeamList, self.CaptainPos, self.FirstFightPos)
    local team = XDataCenter.TeamManager.CreateTeam(self.TeamId)
    team:UpdateAutoSave(true)
    team:UpdateLocalSave(false)
    team:Clear()
    team:UpdateFromTeamData(teamList)
    team:UpdateSaveCallback(function(inTeam)
        self.TeamList = inTeam:GetEntityIds()
        self.CaptainPos = inTeam:GetCaptainPos()
        self.FirstFightPos = inTeam:GetFirstFightPos()
    end)
    XLuaUiManager.Open("UiBattleRoleRoom",
            self.StageId,
            team,
            require("XUi/XUiFubenBabelTower/Room/XUiBabelTowerBattleRoleRoom")
    )
end

function XUiBabelTowerChildSupport:OnBtnSupportClick()
    -- 支援详情
    XLuaUiManager.Open("UiBabelTowerDetails", XFubenBabelTowerConfigs.TIPSTYPE_SUPPORT, self.StageId)
end

function XUiBabelTowerChildSupport:RestoreSupportBuff()
    self:GetTotalSupportPoint()
    self:SetSupportChoiceDatas()

    -- 初始化检查一遍阵容
    self:CheckTeamBanCharacterList()
    self:ReportTeamList()

    self:InitSupportBuff()
end

-- 设置支援目标战略组
function XUiBabelTowerChildSupport:SetSupportChoiceDatas()
    self:GenSupportGroupDatas()
    self:GenSupportSelectDatas()
    self.DynamicTableSupportChoice:SetDataSource(self.SupportBuffGroup)
    self.DynamicTableSupportChoice:ReloadDataASync()
end

-- 设置队伍信息:初始化
function XUiBabelTowerChildSupport:SetTeamListDatas()
    for i = 1, XFubenBabelTowerConfigs.MAX_TEAM_MEMBER do
        self.TeamMemberList[i]:SetMemberInfo(self.TeamList[i], nil, self.CaptainPos)
    end
end

-- 更新队伍信息:手动改变队伍
function XUiBabelTowerChildSupport:UpdateTeamMember(member_position, characterId)
    if member_position <= 0 or member_position > XFubenBabelTowerConfigs.MAX_TEAM_MEMBER then return end
    self.TeamList[member_position] = characterId or 0
    self.TeamMemberList[member_position]:SetMemberInfo(self.TeamList[member_position], nil, self.CaptainPos)
    self:ReportTeamList()
end

function XUiBabelTowerChildSupport:UpdateTeamInfo()
    for i = 1, XFubenBabelTowerConfigs.MAX_TEAM_MEMBER do
        local characterId = self.TeamMemberList[i].CharacterId
        self.TeamMemberList[i]:SetMemberInfo(characterId, nil, self.CaptainPos)
    end
end

-- 切换队伍结束：计算支援点
-- 不清除支援组
-- 红色显色
-- 支援点处理
-- 现有的基础上、增加超出处理
-- 控件刷新如何记住超出状态
-- 超出状态出现一定是按下状态、取消的时候变成不可点击状态、超出状态消失
-- 逻辑处理：
-- 判读是否超出：
--              是：全部选项标记超出
--                  每次取消：判读是否超出,更改标记
--              否：帮用户选上
--                  更改标记
-- 默认选中
function XUiBabelTowerChildSupport:InitSupportBuff()
    local supportBuffs = XDataCenter.FubenBabelTowerManager.GetSupportBuffListCacheByStageId(self.StageId, self.TeamId)

    -- 记录选中的
    for _, v in pairs(self.SupportBuffSelectGroup or {}) do
        if supportBuffs[v.BuffGroupId] then
            v.SelectBuffId = supportBuffs[v.BuffGroupId]
        end
    end
    self.ChoosedSupportList = {}
    for i = 1, #self.SupportBuffSelectGroup do
        local groupItem = self.SupportBuffSelectGroup[i]
        if groupItem.SelectBuffId then
            table.insert(self.ChoosedSupportList, groupItem)
        end
    end
    local availablePoint = self:GetAvailableSupportPoint()
    -- 记录全部
    for _, v in pairs(self.SupportBuffGroup or {}) do
        if supportBuffs[v.BuffGroupId] then
            v.SelectedBuffId = supportBuffs[v.BuffGroupId]
            local buffGroupTemplate = XFubenBabelTowerConfigs.GetBabelTowerBuffGroupTemplate(v.BuffGroupId)
            for idx, buffId in pairs(buffGroupTemplate.BuffId) do
                if buffId == supportBuffs[v.BuffGroupId] then
                    v.CurSelectId = idx
                    break
                end
            end
            v.IsOverCount = availablePoint < 0
        end
    end

    -- 更新界面
    self:UpdateSupportChooiceState()
    self:ReportSupportChoice()
    -- self.DynamicTableSupportSelect:SetDataSource(self.ChoosedSupportList)
    -- self.DynamicTableSupportSelect:ReloadDataASync()
    self:RefreshSelectChoiceList()
    self.ImgEmpty.gameObject:SetActiveEx(#self.ChoosedSupportList <= 0)
    self.TxtChallengeNumber.text = availablePoint
end

-- 切换队友
function XUiBabelTowerChildSupport:OnUpdateTeamMemberEnd()
    -- 计算总的支援点数
    self:GetTotalSupportPoint()

    -- self:CheckSupportSelectBuffs()
    local availableSupportPoint = self:GetAvailableSupportPoint()
    self:UpdateSupportBuffOverCountTag(availableSupportPoint)

    self:UpdateSupportChooiceState()
    self.TxtChallengeNumber.text = availableSupportPoint
end

-- 更改标记
function XUiBabelTowerChildSupport:UpdateSupportBuffOverCountTag(availablePoint)
    for _, v in pairs(self.SupportBuffGroup or {}) do
        v.IsOverCount = availablePoint < 0
    end
end

-- 清理选中支援组
function XUiBabelTowerChildSupport:CheckSupportSelectBuffs()
    local supportSelectBuffs = {}
    local usedSupportPoints = 0

    for i = 1, #self.ChoosedSupportList do
        local datas = self.ChoosedSupportList[i]
        local buffTemplate = XFubenBabelTowerConfigs.GetBabelTowerBuffTemplate(datas.SelectBuffId)
        local curCostSupportPoints = usedSupportPoints + buffTemplate.PointSub
        local isChoose = false
        if curCostSupportPoints <= self.TotalSupportPoint then
            usedSupportPoints = curCostSupportPoints
            table.insert(supportSelectBuffs, datas)
            isChoose = true
        else
            self:UnselectSupportChoice(datas.BuffGroupId)
        end

        for _, v in pairs(self.SupportBuffSelectGroup or {}) do
            if v.BuffGroupId == datas.BuffGroupId then
                local buffId = isChoose and datas.SelectBuffId or nil
                v.SelectBuffId = buffId
                break
            end
        end

    end
    self.ChoosedSupportList = supportSelectBuffs
    self:ReportSupportChoice()
    -- self.DynamicTableSupportSelect:SetDataSource(self.ChoosedSupportList)
    -- self.DynamicTableSupportSelect:ReloadDataASync()
    self:RefreshSelectChoiceList()
    self.ImgEmpty.gameObject:SetActiveEx(#self.ChoosedSupportList <= 0)
end

-- 清理支援选项
function XUiBabelTowerChildSupport:UnselectSupportChoice(buffGroupId)
    for _, v in pairs(self.SupportBuffGroup or {}) do
        if v.BuffGroupId == buffGroupId then
            v.SelectedBuffId = nil
            v.CurSelectId = -1
            break
        end
    end
end

function XUiBabelTowerChildSupport:UpdateSupportChooiceState()
    for i = 1, #self.SupportBuffGroup do
        local grid = self.DynamicTableSupportChoice:GetGridByIndex(i)
        if grid then
            grid:UpdateGridChoiceState(self:GetAvailableSupportPoint())
        end
    end
end

function XUiBabelTowerChildSupport:CalcUsedSupportPoint()
    local usedSupportPoint = 0

    for _, choosedItem in pairs(self.ChoosedSupportList or {}) do
        local buffTemplate = XFubenBabelTowerConfigs.GetBabelTowerBuffTemplate(choosedItem.SelectBuffId)
        usedSupportPoint = usedSupportPoint + (buffTemplate.PointSub or 0)
    end

    return usedSupportPoint
end

function XUiBabelTowerChildSupport:GetAvailableSupportPoint()
    return self.TotalSupportPoint - self:CalcUsedSupportPoint()
end

-- 获取支援点数，阵容一旦确定,支援点数也可以确定
function XUiBabelTowerChildSupport:GetTotalSupportPoint()

    self.TotalSupportPoint = self.BabelTowerStageTemplate.BaseSupportPoint or 0

    local characterIds = {}
    for i = 1, XFubenBabelTowerConfigs.MAX_TEAM_MEMBER do
        local characterId = self.TeamMemberList[i].CharacterId
        if characterId ~= nil and characterId ~= 0 then
            table.insert(characterIds, characterId)
        end
    end

    for i = 1, #self.BabelTowerStageTemplate.SupportConditionId do
        local supportConditionId = self.BabelTowerStageTemplate.SupportConditionId[i]
        local supportConditionTemplate = XFubenBabelTowerConfigs.GetBabelTowerSupportConditonTemplate(supportConditionId)
        if supportConditionTemplate.Condition == nil or supportConditionTemplate.Condition == 0 then
            self.TotalSupportPoint = self.TotalSupportPoint + supportConditionTemplate.PointAdd
        else
            local isConditionAvailable = XConditionManager.CheckCondition(supportConditionTemplate.Condition, characterIds)
            if isConditionAvailable then
                self.TotalSupportPoint = self.TotalSupportPoint + supportConditionTemplate.PointAdd
            end
        end
    end

    return self.TotalSupportPoint
end

-- 保存一份数据，记录玩家选中的挑战项SelectBuffList = {buffId = isSelect}
function XUiBabelTowerChildSupport:GenSupportGroupDatas()
    if self.SupportBuffGroup then return self.SupportBuffGroup end
    self.SupportBuffGroup = {}
    for i = 1, #self.BabelTowerStageTemplate.SupportBuffGroup do
        table.insert(self.SupportBuffGroup, {
            StageId = self.StageId,
            GuideId = self.GuideId,
            BuffGroupId = self.BabelTowerStageTemplate.SupportBuffGroup[i],
            SelectedBuffId = nil,
            CurSelectId = -1,
            IsOverCount = false,
        })
    end
end

function XUiBabelTowerChildSupport:GenSupportSelectDatas()
    self.SupportBuffSelectGroup = {}
    for i = 1, #self.BabelTowerStageTemplate.SupportBuffGroup do
        table.insert(self.SupportBuffSelectGroup, {
            BuffGroupId = self.BabelTowerStageTemplate.SupportBuffGroup[i],
            SelectBuffId = nil
        })
    end
end

-- 设置已选支援组
function XUiBabelTowerChildSupport:UpdateChoosedChallengeDatas(buffGroupId, buffId)
    if not self.SupportBuffSelectGroup then self:GenSupportSelectDatas() end
    self.ChoosedSupportList = {}
    for i = 1, #self.SupportBuffSelectGroup do
        local groupItem = self.SupportBuffSelectGroup[i]
        if groupItem.BuffGroupId == buffGroupId then
            groupItem.SelectBuffId = buffId
        end
        if groupItem.SelectBuffId then
            table.insert(self.ChoosedSupportList, groupItem)
        end
    end
    local index = 0
    for i = 1, #self.ChoosedSupportList do
        local groupItem = self.ChoosedSupportList[i]
        if groupItem.BuffGroupId == buffGroupId and groupItem.SelectBuffId and groupItem.SelectBuffId == buffId then
            index = i
            break
        end
    end

    self:ReportSupportChoice()
    -- self.DynamicTableSupportSelect:SetDataSource(self.ChoosedSupportList)
    -- self.DynamicTableSupportSelect:ReloadDataASync()
    self:RefreshSelectChoiceList(index)
    self.ImgEmpty.gameObject:SetActiveEx(#self.ChoosedSupportList <= 0)

    local availableSupportPoint = self:GetAvailableSupportPoint()
    self:UpdateSupportBuffOverCountTag(availableSupportPoint)
    self:UpdateSupportChooiceState()
    self.TxtChallengeNumber.text = availableSupportPoint
end

function XUiBabelTowerChildSupport:ReportSupportChoice()
    self.UiRoot:UpdateSupportBuffInfos(self.ChoosedSupportList)
end

function XUiBabelTowerChildSupport:ReportTeamList()
    self.UiRoot:UpdateTeamList(self.TeamList, self.CaptainPos, self.FirstFightPos)
end