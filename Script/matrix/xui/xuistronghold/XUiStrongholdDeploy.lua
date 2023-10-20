local XUiGridStrongholdTeam = require("XUi/XUiStronghold/XUiGridStrongholdTeam")

local CsXTextManagerGetText = CsXTextManagerGetText
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate

local CONDITION_COLOR = {
    [true] = CS.UnityEngine.Color.red,
    [false] = CS.UnityEngine.Color.black
}

local XUiStrongholdDeploy = XLuaUiManager.Register(XLuaUi, "UiStrongholdDeploy")

function XUiStrongholdDeploy:OnAwake()
    self:AutoAddListener()

    self.GridDeployTeam.gameObject:SetActiveEx(false)
    self.TxtTool1.supportRichText = true
end

function XUiStrongholdDeploy:OnStart(groupId)
    self.GroupId = groupId
    ---@type XUiGridStrongholdTeam[]
    self.TeamGrids = {}

    if self:IsPrefab() then
        self.TeamList = XDataCenter.StrongholdManager.GetTeamListClipTemp(groupId)
    else
        self.TeamList = XDataCenter.StrongholdManager.GetTeamListTemp()
        XDataCenter.StrongholdManager.KickOutInvalidMembersInTeamList(self.TeamList, groupId)

        local chapterId = XStrongholdConfigs.GetChapterIdByGroupId(groupId)
        self.TaskLimitElectric = XStrongholdConfigs.GetTaskLimitElectric(chapterId)
    end
    self.PluginAddPower = XStrongholdConfigs.GetPluginAddAbility(XEnumConst.StrongHold.AttrPluginId)
    self.MaxPluginCount = XStrongholdConfigs.GetPluginCountLimit(XEnumConst.StrongHold.AttrPluginId)
    self.PluginUseElectric = XStrongholdConfigs.GetPluginUseElectric(XEnumConst.StrongHold.AttrPluginId)

    self:KickOutAssitMemberIfBanAssit()
    self:InitView()
end

function XUiStrongholdDeploy:OnEnable()
    if self.IsEnd then
        return
    end

    if XDataCenter.StrongholdManager.OnActivityEnd() then
        self.IsEnd = true
        return
    end

    self:UpdateElectric()
    self:UpdateTeamList()
end

function XUiStrongholdDeploy:OnDestroy()
    for _, grid in pairs(self.TeamGrids) do
        if grid.OnDestroy then
            grid:OnDestroy()
        end
    end

    if not self.IsEnd and not self.IsFighting then
        if self:IsPrefab() then
            --预设模式下同步修改到服务端
            XDataCenter.StrongholdManager.SetStrongholdTeamRequest(self.TeamList)
        else
            --战斗模式下同步修改到服务端
            local isOwn = false
            XDataCenter.StrongholdManager.SetStrongholdTeamRequest(self.TeamList, isOwn)
        end
    end
end

function XUiStrongholdDeploy:OnGetEvents()
    return {
        XEventId.EVENT_STRONGHOLD_FINISH_GROUP_CHANGE,
        XEventId.EVENT_STRONGHOLD_PLUGIN_CHANGE_ACK,
        XEventId.EVENT_STRONGHOLD_ACTIVITY_END,
        XEventId.EVENT_STRONGHOLD_RUNE_CHANGE
    }
end

function XUiStrongholdDeploy:OnNotify(evt, ...)
    if self.IsEnd then
        return
    end

    if evt == XEventId.EVENT_STRONGHOLD_FINISH_GROUP_CHANGE then
        XDataCenter.StrongholdManager.KickOutInvalidMembersInTeamList(self.TeamList, self.GroupId)
        self:UpdateTeamList()
    elseif evt == XEventId.EVENT_STRONGHOLD_PLUGIN_CHANGE_ACK then
        self:UpdateElectric()
        self:UpdateTeamList()
    elseif evt == XEventId.EVENT_STRONGHOLD_RUNE_CHANGE then
        self:UpdateTeamList()
    elseif evt == XEventId.EVENT_STRONGHOLD_ACTIVITY_END then
        if XDataCenter.StrongholdManager.OnActivityEnd() then
            self.IsEnd = true
            return
        end
    end
end

function XUiStrongholdDeploy:InitView()
    local isPrefab = self:IsPrefab()
    self.TxtTiltlePrefab.gameObject:SetActiveEx(isPrefab)
    self.TxtTiltle.gameObject:SetActiveEx(not isPrefab)
    self.BtnAllocation.gameObject:SetActiveEx(not self:IsPrefab())
    local icon = XStrongholdConfigs.GetElectricIcon()
    self.RImgTool1:SetRawImage(icon)
end

function XUiStrongholdDeploy:UpdateElectric()
    local groupId = self.GroupId
    local teamList = XDataCenter.StrongholdManager.GetFighterTeamListTemp(self.TeamList, groupId)
    if not self.UseElectric then
        self.UseElectric = XDataCenter.StrongholdManager.GetTotalUseElectricEnergy(teamList)
    end
    self.TotalElectric = XDataCenter.StrongholdManager.GetTotalCanUseElectricEnergy(groupId)
    local color = XDataCenter.StrongholdManager.GetSuggestElectricColor(groupId, teamList)
    self.TxtTool1.text = string.format("%s/%s", self.UseElectric, self.TotalElectric)
    self.TxtTool1.color = color
end

function XUiStrongholdDeploy:UpdateTeamList()
    local groupId = self.GroupId
    local teamList = self.TeamList

    local isPrefab = self:IsPrefab()
    self.ImgPjzlBg.gameObject:SetActiveEx(not isPrefab)
    self.BtnSupport.gameObject:SetActiveEx(not isPrefab)
    self.BtnFight.gameObject:SetActiveEx(not isPrefab)
    self.BtnAutoTeam.gameObject:SetActiveEx(isPrefab)
    self.BtnRetreat.gameObject:SetActiveEx(
        not isPrefab and XDataCenter.StrongholdManager.CheckGroupHasFinishedStage(self.GroupId)
    )

    if not isPrefab then
        --支援方案预设模式下不显示
        local isSupportActive = XDataCenter.StrongholdManager.CheckGroupSupportAcitve(groupId, teamList)
        self.TxtOn.gameObject:SetActiveEx(isSupportActive)
        self.TxtOff.gameObject:SetActiveEx(not isSupportActive)

        --完美战术的平均战力
        local supportId = XDataCenter.StrongholdManager.GetGroupSupportId(groupId)
        local conditionIds = XStrongholdConfigs.GetSupportConditionIds(supportId)
        local requireAbility = 0
        for _, conditionId in ipairs(conditionIds) do
            local config = XConditionManager.GetConditionTemplate(conditionId)
            if config.Type == 10134 then
                requireAbility = config.Params[1]
                break
            end
        end
        local isfinished, averageAbility = XDataCenter.StrongholdManager.CheckTeamListAverageAbility(requireAbility, teamList)
        local color = isfinished and "000000" or "d92f2f"
        self.TxtPjzl.text = CsXTextManagerGetText("StrongholdDeployTxtPjzl", color, math.floor(averageAbility), requireAbility)
    end

    local requireTeamIds = XDataCenter.StrongholdManager.GetGroupRequireTeamIds(groupId)
    for index, teamId in ipairs(requireTeamIds) do
        local team = teamList[teamId]

        local grid = self.TeamGrids[index]
        if not grid then
            local checkCountCb = handler(self, self.OnCheckElectric)
            local countChangeCb = handler(self, self.OnCountChange)
            local getMaxCountCb = handler(self, self.GetMaxPluginCount)

            local go = CSUnityEngineObjectInstantiate(self.GridDeployTeam, self.PanelTeamContent)
            grid = XUiGridStrongholdTeam.New(go, function()
                self.IsFighting = true
            end, checkCountCb, countChangeCb, getMaxCountCb)
            grid:InitElectric(team:GetUseCount())
            self.TeamGrids[index] = grid
        end

        grid:Refresh(teamList, teamId, groupId, isPrefab)
        grid.GameObject:SetActiveEx(true)
    end
    for index = #requireTeamIds + 1, #self.TeamGrids do
        local grid = self.TeamGrids[index]
        if grid then
            grid.GameObject:SetActiveEx(false)
        end
    end
end

function XUiStrongholdDeploy:AutoAddListener()
    self.BtnBack.CallBack = function()
        self:OnClickBtnBack()
    end
    self.BtnMainUi.CallBack = function()
        self:OnClickBtnMainUi()
    end
    self.BtnFormation.CallBack = function()
        self:OnClickBtnFormation()
    end
    self.BtnSupport.CallBack = function()
        self:OnClickBtnSupport()
    end
    self.BtnFight.CallBack = function()
        self:OnClickBtnFight()
    end
    self.BtnRetreat.CallBack = function()
        self:OnClickBtnRetreat()
    end
    self.BtnAutoTeam.CallBack = function()
        self:OnClickBtnAutoTeam()
    end
    if self.BtnTool1 then
        self.BtnTool1.CallBack = function()
            self:OnClickBtnTool1()
        end
    end
    self:RegisterClickEvent(self.BtnAllocation, self.OnClickBtnAllocation)
end

function XUiStrongholdDeploy:OnClickBtnBack()
    self:Close()
end

function XUiStrongholdDeploy:OnClickBtnMainUi()
    XLuaUiManager.RunMain()
end

function XUiStrongholdDeploy:OnClickBtnFormation()
    if XDataCenter.StrongholdManager.CheckTeamListEmpty(self.TeamList) then
        XUiManager.TipText("StrongholdDeployQucikDeployEmpty")
        return
    end

    local teamList = XTool.Clone(self.TeamList)
    local cb = function()
        self.TeamList = teamList
        self:UpdateTeamList()
    end
    XLuaUiManager.Open("UiStrongholdQuickDeploy", self.GroupId, teamList, cb)
end

function XUiStrongholdDeploy:OnClickBtnSupport()
    XDataCenter.StrongholdManager.OpenUiSupport(self.GroupId, self.TeamList)
end

function XUiStrongholdDeploy:OnClickBtnFight()
    self.IsFighting = true
    XDataCenter.StrongholdManager.TryEnterFight(self.GroupId, nil, self.TeamList)
end

function XUiStrongholdDeploy:OnClickBtnRetreat()
    local callFunc = function()
        if not XDataCenter.StrongholdManager.CheckAnyGroupHasFinishedStage() then
            self:Close()
            return
        end

        local groupId = self.GroupId
        local cb = function()
            self:Close()
        end
        XDataCenter.StrongholdManager.ResetStrongholdGroupRequest(groupId, cb)
    end
    local title = CsXTextManagerGetText("StrongholdTeamRestartConfirmTitle")
    local content = CsXTextManagerGetText("StrongholdTeamRestartConfirmContent")
    XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, callFunc)
end

function XUiStrongholdDeploy:OnClickBtnAutoTeam()
    XDataCenter.StrongholdManager.AutoTeam(self.TeamList)
    self:UpdateTeamList()
end

function XUiStrongholdDeploy:OnClickBtnAllocation()
    -- 先找最低战力的,分到他不是最低为止,递归上面步骤
    self._Allocate = {}
    self.UseElectric = 0
    local teamList = XDataCenter.StrongholdManager.GetFighterTeamListTemp(self.TeamList, self.GroupId)
    for i, team in ipairs(teamList) do
        local tb = {}
        tb.Index = i
        tb.Power = team:GetTeamAbility()
        tb.Electric = 0
        table.insert(self._Allocate, tb)
    end
    self:AutoAllocation()
    for _, v in pairs(self._Allocate) do
        local team = self.TeamGrids[v.Index]
        if team then
            team.Count = v.Electric
            team:UpdateCount()
        end
    end
    self:UpdateElectric()
    self:UpdateTeamList()
end

-- PS：时间复杂度=能配置的电量，如果能配置的电量太多，考虑每次都+2而不是+1
function XUiStrongholdDeploy:AutoAllocation()
    table.sort(self._Allocate, function(a, b)
        return a.Power < b.Power
    end)

    local min = self._Allocate[1]   -- 战力最小的组
    local minCount = 0              -- 同战力的有多少组
    for _, v in ipairs(self._Allocate) do
        minCount = minCount + 1
        if v.Power ~= min.Power then
            break
        end
    end

    local secondMin = self._Allocate[minCount + 1]  -- 战力次小的组
    local residue = math.floor((self.TaskLimitElectric - self.UseElectric) / self.PluginUseElectric)
    local needElectric
    if secondMin then
        local needPower = secondMin.Power - min.Power
        needElectric = math.ceil(needPower / self.PluginAddPower)
    else
        needElectric = residue
    end
    local allNeedElectric = needElectric * minCount
    if residue < allNeedElectric then
        allNeedElectric = residue
    end
    local isLimit = true -- 是否全部队伍都已到装备上限
    local isError = true -- 以防万一死循环
    for i = 1, minCount do
        local data = self._Allocate[i]
        local canAllcate = math.ceil(allNeedElectric / (minCount - i + 1))-- 能分配的插件数量
        local canWearLimit = self.MaxPluginCount - data.Electric-- 插件装备上限
        local real = math.min(canAllcate, canWearLimit)
        data.Power = data.Power + real * self.PluginAddPower
        data.Electric = data.Electric + real
        if canWearLimit > 0 then
            isLimit = false
        end
        if real > 0 then
            isError = false
        end
        allNeedElectric = allNeedElectric - real
        self.UseElectric = self.UseElectric + real * self.PluginUseElectric
    end

    if self.TaskLimitElectric > self.UseElectric and not isLimit and not isError then
        self:AutoAllocation()
    end
end

--预设模式
function XUiStrongholdDeploy:IsPrefab()
    return not XTool.IsNumberValid(self.GroupId)
end

function XUiStrongholdDeploy:OnClickBtnTool1()
    XLuaUiManager.Open("UiStrongholdPowerusageTips", self.GroupId, self.TeamList)
end

-- 在不允许支援的关卡，将支援角色踢出队伍
function XUiStrongholdDeploy:KickOutAssitMemberIfBanAssit()
    local chapterId = XStrongholdConfigs.GetChapterIdByGroupId(self.GroupId)
    -- 可能为空，在梯队预设界面，应该是不通过具体章节界面打开
    if not chapterId then
        return
    end
    local isBanAssit = XStrongholdConfigs.IsChapterLendCharacterBanned(chapterId)
    if not isBanAssit then
        return
    end
    if not self.TeamList then
        return
    end
    for stageIndex, team in pairs(self.TeamList) do
        local members = team:GetAllMembers()
        for i = 1, #members do
            local member = members[i]
            if member:IsAssitant() then
                member:KickOutTeam()
            end
        end
    end
end

--region 电能配置

function XUiStrongholdDeploy:OnCheckElectric(costElectric)
    costElectric = costElectric or 0
    local useElectric = self.UseElectric
    local totalElectric = XDataCenter.StrongholdManager.GetTotalCanUseElectricEnergy(self.GroupId)
    return useElectric + costElectric <= totalElectric
end

function XUiStrongholdDeploy:GetMaxPluginCount(costElectric)
    costElectric = costElectric or 0
    local useElectric = self.UseElectric
    local totalElectric = XDataCenter.StrongholdManager.GetTotalCanUseElectricEnergy(self.GroupId)
    return math.floor((totalElectric - useElectric) / costElectric)
end

function XUiStrongholdDeploy:OnCountChange(addElectric)
    self.UseElectric = self.UseElectric + addElectric
    self:UpdateElectric()
    self:UpdateTeamList()
end

--endregion
