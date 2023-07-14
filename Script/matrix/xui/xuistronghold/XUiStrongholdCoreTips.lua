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
    local useElectric = self.UseElectric
    local totalElectric = XDataCenter.StrongholdManager.GetTotalCanUseElectricEnergy(self.GroupId)
    self.TxtTool1.text = useElectric .. "/" .. totalElectric
    self.TxtTool1.color = CONDITION_COLOR[useElectric > totalElectric]
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
end

function XUiStrongholdCoreTips:OnClickBtnClose()
    self:Close()
end

function XUiStrongholdCoreTips:OnClickBtnConfirm()
    if self:SaveChange() then
        XUiManager.TipText("StrongholdPluginSetSaveSuc")
    else
        XUiManager.TipText("StrongholdPluginSaveFail")
    end

    self:Close()
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

function XUiStrongholdCoreTips:SaveChange()
    local team = self:GetTeam()
    local plugins = team:GetAllPlugins()
    for index, plugin in ipairs(plugins) do
        local grid = self.PluginGrids[index]
        local newCount = grid and grid:GetCount()
        plugin:SetCount(newCount)
    end

    XEventManager.DispatchEvent(XEventId.EVENT_STRONGHOLD_PLUGIN_CHANGE_ACK)
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_STRONGHOLD_PLUGIN_CHANGE_ACK)

    return true
end

function XUiStrongholdCoreTips:OnClickBtnTool1()
    local itemId = XDataCenter.StrongholdManager.GetBatteryItemId()
    XLuaUiManager.Open("UiTip", itemId)
end