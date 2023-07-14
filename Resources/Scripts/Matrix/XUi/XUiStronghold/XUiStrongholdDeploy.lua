local XUiGridStrongholdTeam = require("XUi/XUiStronghold/XUiGridStrongholdTeam")

local CsXTextManagerGetText = CsXTextManagerGetText
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate

local CONDITION_COLOR = {
    [true] = CS.UnityEngine.Color.red,
    [false] = CS.UnityEngine.Color.black,
}

local XUiStrongholdDeploy = XLuaUiManager.Register(XLuaUi, "UiStrongholdDeploy")

function XUiStrongholdDeploy:OnAwake()
    self:AutoAddListener()

    self.GridDeployTeam.gameObject:SetActiveEx(false)
end

function XUiStrongholdDeploy:OnStart(groupId)
    self.GroupId = groupId
    self.TeamGrids = {}

    if self:IsPrefab() then
        self.TeamList = XDataCenter.StrongholdManager.GetTeamListClipTemp(groupId)
    else
        self.TeamList = XDataCenter.StrongholdManager.GetTeamListTemp()
        XDataCenter.StrongholdManager.KickOutInvalidMembersInTeamList(self.TeamList, groupId)
    end

    self:InitView()
end

function XUiStrongholdDeploy:OnEnable()
    if self.IsEnd then return end

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
        XEventId.EVENT_STRONGHOLD_RUNE_CHANGE,
    }
end

function XUiStrongholdDeploy:OnNotify(evt, ...)
    if self.IsEnd then return end

    if evt == XEventId.EVENT_STRONGHOLD_FINISH_GROUP_CHANGE then
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

    local icon = XStrongholdConfigs.GetElectricIcon()
    self.RImgTool1:SetRawImage(icon)
end

function XUiStrongholdDeploy:UpdateElectric()
    local useElectric = XDataCenter.StrongholdManager.GetTotalUseElectricEnergy(self.TeamList)
    local totalElectric = XDataCenter.StrongholdManager.GetTotalElectricEnergy()
    self.TxtTool1.text = useElectric .. "/" .. totalElectric
    self.TxtTool1.color = CONDITION_COLOR[useElectric > totalElectric]
end

function XUiStrongholdDeploy:UpdateTeamList()
    local groupId = self.GroupId
    local teamList = self.TeamList

    local isPrefab = self:IsPrefab()
    self.BtnSupport.gameObject:SetActiveEx(not isPrefab)
    self.BtnFight.gameObject:SetActiveEx(not isPrefab)
    self.BtnAutoTeam.gameObject:SetActiveEx(isPrefab)
    self.BtnRetreat.gameObject:SetActiveEx(not isPrefab and XDataCenter.StrongholdManager.CheckGroupHasFinishedStage(self.GroupId))

    if not isPrefab then
        --支援方案预设模式下不显示
        local isSupportActive = XDataCenter.StrongholdManager.CheckGroupSupportAcitve(groupId, teamList)
        self.TxtOn.gameObject:SetActiveEx(isSupportActive)
        self.TxtOff.gameObject:SetActiveEx(not isSupportActive)
    end

    local requireTeamIds = XDataCenter.StrongholdManager.GetGroupRequireTeamIds(groupId)
    for index, teamId in ipairs(requireTeamIds) do
        local team = teamList[teamId]

        local grid = self.TeamGrids[index]
        if not grid then
            local go = CSUnityEngineObjectInstantiate(self.GridDeployTeam, self.PanelTeamContent)
            grid = XUiGridStrongholdTeam.New(go, function()
                self.IsFighting = true
            end)
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
    self.BtnBack.CallBack = function() self:OnClickBtnBack() end
    self.BtnMainUi.CallBack = function() self:OnClickBtnMainUi() end
    self.BtnFormation.CallBack = function() self:OnClickBtnFormation() end
    self.BtnSupport.CallBack = function() self:OnClickBtnSupport() end
    self.BtnFight.CallBack = function() self:OnClickBtnFight() end
    self.BtnRetreat.CallBack = function() self:OnClickBtnRetreat() end
    self.BtnAutoTeam.CallBack = function() self:OnClickBtnAutoTeam() end
    if self.BtnTool1 then
        self.BtnTool1.CallBack = function() self:OnClickBtnTool1() end
    end
end

function XUiStrongholdDeploy:OnClickBtnBack()
    local groupId = self.GroupId
    if groupId then
        --返回、作战开始、主界面都会保存队伍，区别在于有关卡进度的时候：作战开始/主界面会保存当前对其他梯队的修改，返回会触发撤退的二次确认弹窗
        if not XDataCenter.StrongholdManager.CheckGroupHasFinishedStage(self.GroupId) then
            self:Close()
        else
            self:OnClickBtnRetreat()
        end
    else
        self:Close()
    end
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
    local title = CSXTextManagerGetText("StrongholdTeamRestartConfirmTitle")
    local content = CSXTextManagerGetText("StrongholdTeamRestartConfirmContent")
    XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, callFunc)
end

function XUiStrongholdDeploy:OnClickBtnAutoTeam()
    XDataCenter.StrongholdManager.AutoTeam(self.TeamList)
    self:UpdateTeamList()
end

--预设模式
function XUiStrongholdDeploy:IsPrefab()
    return not XTool.IsNumberValid(self.GroupId)
end

function XUiStrongholdDeploy:OnClickBtnTool1()
    local itemId = XDataCenter.StrongholdManager.GetBatteryItemId()
    XLuaUiManager.Open("UiTip", itemId)
end