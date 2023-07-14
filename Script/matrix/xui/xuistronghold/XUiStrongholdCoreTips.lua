local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate
local XUiGridStrongholdPluginSet = require("XUi/XUiStronghold/XUiGridStrongholdPluginSet")

local handler = handler

local CONDITION_COLOR = {
    [true] = CS.UnityEngine.Color.red,
    [false] = CS.UnityEngine.Color.black,
}

local XUiStrongholdCoreTips = XLuaUiManager.Register(XLuaUi, "UiStrongholdCoreTips")

function XUiStrongholdCoreTips:OnAwake()
    self:AutoAddListener()

    self.GridCore.gameObject:SetActiveEx(false)
    self.TxtTool1.supportRichText = true
end

function XUiStrongholdCoreTips:OnStart(teamList, teamId, groupId)
    self.TeamList = teamList
    self.TeamId = teamId
    self.GroupId = groupId
    self.PluginGrids = {}

    self:InitView()
end

function XUiStrongholdCoreTips:OnEnable()

    self.UseElectric = XDataCenter.StrongholdManager.GetTotalUseElectricEnergy(self.TeamList)
    self:UpdateElectric()
    self:UpdateView()
end

function XUiStrongholdCoreTips:OnDisable()

end

function XUiStrongholdCoreTips:InitView()
    local icon = XStrongholdConfigs.GetElectricIcon()
    self.RImgTool1:SetRawImage(icon)

    local teamId = self.TeamId
    local groupId = self.GroupId
    if groupId then
        self.TxtName.text = XDataCenter.StrongholdManager.GetGroupStageName(groupId, teamId)
    else
        self.TxtName.text = CsXTextManagerGetText("StrongholdTeamTitle", teamId)
    end
end

function XUiStrongholdCoreTips:UpdateElectric()
    local teamList = self.TeamList
    local useElectric = self.UseElectric
    local groupId = self.GroupId
    local totalElectric = XDataCenter.StrongholdManager.GetTotalCanUseElectricEnergy(groupId)
    local color = XDataCenter.StrongholdManager.GetSuggestElectricColor(groupId, teamList, useElectric)
    self.TxtTool1.text = string.format("%s/%s", useElectric, totalElectric)
    self.TxtTool1.color = color
end

function XUiStrongholdCoreTips:UpdateView()
    local team = self:GetTeam()
    local plugins = team:GetAllPlugins()
    for index, plugin in ipairs(plugins) do
        local grid = self.PluginGrids[index]
        if not grid then
            local ui = index == 1 and self.GridCore or CSUnityEngineObjectInstantiate(self.GridCore, self.PanelContent)
            local checkCountCb = handler(self, self.OnCheckElectric)
            local countChangeCb = handler(self, self.OnCountChange)
            local getMaxCountCb = handler(self, self.GetMaxPluginCount)
            grid = XUiGridStrongholdPluginSet.New(ui, checkCountCb, countChangeCb, getMaxCountCb)
            self.PluginGrids[index] = grid
        end

        grid:Refresh(plugin)
        grid.GameObject:SetActiveEx(true)
    end
    for index = #plugins + 1, #self.PluginGrids do
        self.PluginGrids[index].GameObject:SetActiveEx(false)
    end
end

function XUiStrongholdCoreTips:AutoAddListener()
    self.BtnClose.CallBack = function() self:OnClickBtnClose() end
    self.BtnTanchuangClose.CallBack = function() self:OnClickBtnClose() end
    self.BtnTongBlue.CallBack = function() self:OnClickBtnConfirm() end
    if self.BtnTool1 then
        self.BtnTool1.CallBack = function() self:OnClickBtnTool1() end
    end
    self.BtnElectricTips.CallBack = function() self:OnClickBtnTool1() end
end

function XUiStrongholdCoreTips:OnClickBtnClose()
    self:Close()
end

function XUiStrongholdCoreTips:OnClickBtnConfirm()
    self:SaveChange()
end

function XUiStrongholdCoreTips:GetTeam()
    return self.TeamList[self.TeamId]
end

function XUiStrongholdCoreTips:OnCheckElectric(costElectric)
    costElectric = costElectric or 0
    local useElectric = self.UseElectric
    local totalElectric = XDataCenter.StrongholdManager.GetTotalCanUseElectricEnergy(self.GroupId)
    return useElectric + costElectric <= totalElectric
end

function XUiStrongholdCoreTips:GetMaxPluginCount(costElectric)
    costElectric = costElectric or 0
    local useElectric = self.UseElectric
    local totalElectric = XDataCenter.StrongholdManager.GetTotalCanUseElectricEnergy(self.GroupId)
    return math.floor((totalElectric - useElectric) / costElectric)
end

function XUiStrongholdCoreTips:OnCountChange(addElectric)
    self.UseElectric = self.UseElectric + addElectric
    self:UpdateElectric()
end

-- [检查插件更改安全性。在其他区域已经被压制，而此次改动会导致完美战术失效时，此改动需要重置此次作战。]
function XUiStrongholdCoreTips:SaveChange()
    if not self.GroupId then --[没进入关卡]
        return self:DoChangeSave()
    end
    if not XDataCenter.StrongholdManager.CheckGroupHasFinishedStage(self.GroupId) then --[没有已经完成关卡的队伍]
        return self:DoChangeSave()
    end
    local fightTeamList = XTool.Clone(XDataCenter.StrongholdManager.GetFighterTeamListTemp(self.TeamList, self.GroupId))
    if not XDataCenter.StrongholdManager.CheckGroupSupportAcitve(self.GroupId, fightTeamList) then --[没有激活完美战术]
        return self:DoChangeSave()
    end
    local team = fightTeamList[self.TeamId]
    local plugins = team:GetAllPlugins()
    for index, plugin in ipairs(plugins) do
        local grid = self.PluginGrids[index]
        local newCount = grid and grid:GetCount()
        plugin:SetCount(newCount)
    end
    if XDataCenter.StrongholdManager.CheckGroupSupportAcitve(self.GroupId, fightTeamList) then --[完美战术没被取消]
        return self:DoChangeSave()
    end
    --[完美战术状态从激活变更没激活 必须撤退才能保存插件更改]
    local sureCallback = function() --[撤退]
        local groupId = self.GroupId
        local cb = function()
            self:DoChangeSave()
        end
        XDataCenter.StrongholdManager.ResetStrongholdGroupRequest(groupId, cb)
    end
    local closeCallback = function() --[取消]
        self:DoChangeCancel()
    end
    local data = {Content2 = CSXTextManagerGetText("StrongholdPerfectStrategyNotActivate")}
    XUiManager.DialogTip("", "", XUiManager.DialogType.Normal, closeCallback, sureCallback,data)
end

function XUiStrongholdCoreTips:DoChangeSave()
    local team = self:GetTeam()
    local plugins = team:GetAllPlugins()
    for index, plugin in ipairs(plugins) do
        local grid = self.PluginGrids[index]
        local newCount = grid and grid:GetCount()
        plugin:SetCount(newCount)
    end
    XEventManager.DispatchEvent(XEventId.EVENT_STRONGHOLD_PLUGIN_CHANGE_ACK)
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_STRONGHOLD_PLUGIN_CHANGE_ACK)
    self:Close()
end

function XUiStrongholdCoreTips:DoChangeCancel()
    self:Close()
end

function XUiStrongholdCoreTips:OnClickBtnTool1()
    XLuaUiManager.Open("UiStrongholdPowerusageTips", self.GroupId, self.TeamList)
end