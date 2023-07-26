local XUiGridRiftPluginDrop = require("XUi/XUiRift/Grid/XUiGridRiftPluginDrop")

--大秘境关卡战斗结算界面
local XUiRiftSettlePlugin = XLuaUiManager.Register(XLuaUi, "UiRiftSettlePlugin")

function XUiRiftSettlePlugin:OnAwake()
    self:InitButton()
    self:InitDynamicTable()
end

function XUiRiftSettlePlugin:InitButton()
    self:RegisterClickEvent(self.BtnQuit, self.OnBtnQuitClick)
    self:RegisterClickEvent(self.BtnQuitLuck, self.OnBtnQuitClick)
    self:RegisterClickEvent(self.BtnNext, self.OnBtnNextClick)
    self:RegisterClickEvent(self.BtnSettle, self.OnBtnSettleClick)
end

function XUiRiftSettlePlugin:OnStart(settleData, nextStageGroup, nextStageIndex)
    self.SettleData = settleData
    self.RiftSettleResult = settleData.RiftSettleResult
    self.NextStageGroup = nextStageGroup
    self.NextStageIndex = nextStageIndex
end

function XUiRiftSettlePlugin:OnEnable()
    -- 判断要不要进行下一关，显示对应按钮
    local xStageGroup = XDataCenter.RiftManager.GetLastFightXStage():GetParent()
    if xStageGroup:GetType() == XRiftConfig.StageGroupType.Luck then
        self.BtnQuit.gameObject:SetActiveEx(false)
        self.BtnQuitLuck.gameObject:SetActiveEx(true)
        self.BtnNext.gameObject:SetActiveEx(false)
        self.BtnSettle.gameObject:SetActiveEx(false)
    elseif not self.NextStageGroup then
        self.BtnQuit.gameObject:SetActiveEx(false)
        self.BtnNext.gameObject:SetActiveEx(false)
        self.BtnSettle.gameObject:SetActiveEx(true)
    end
    -- 刷新插件列表
    self:RefreshDynamicTable()
end

-- 进行下一关战斗
function XUiRiftSettlePlugin:OnBtnNextClick()
    CS.XFight.ExitForClient(true)
    -- 直接再进入战斗，关闭界面会在退出战斗前通过remove移除
    XDataCenter.RiftManager.SetCurrSelectRiftStage(self.NextStageGroup)
    local team = nil
    if self.NextStageGroup:GetType() == XRiftConfig.StageGroupType.Multi then
        team = XDataCenter.RiftManager.GetMultiTeamData()[self.NextStageIndex]
    else
        team = XDataCenter.RiftManager.GetSingleTeamData()
    end
    XDataCenter.RiftManager.EnterFight(team)
end

function XUiRiftSettlePlugin:OnBtnSettleClick()
    -- 层结算，不通过直接打开ui来跳转，通过发送trigger，在进入层选择界面是自动检测打开
    local layerId = XDataCenter.RiftManager.GetLastFightXStage():GetParent():GetParent():GetId()
    XLuaUiManager.PopThenOpen("UiRiftSettleWin", layerId, self.SettleData.RiftSettleResult)
end

function XUiRiftSettlePlugin:OnBtnQuitClick()
    self:Close()
end

function XUiRiftSettlePlugin:InitDynamicTable()
    self.GridRiftPluginTips.gameObject:SetActiveEx(false)
    self.DynamicTable = XDynamicTableNormal.New(self.PanelPluginList)
    self.DynamicTable:SetProxy(XUiGridRiftPluginDrop)
    self.DynamicTable:SetDelegate(self)
end

local DropPluginSortFunc = function(dropDataA, dropDataB)
    local isDecomposeA = dropDataA.DecomposeCount > 0
    local isDecomposeB = dropDataB.DecomposeCount > 0
    if isDecomposeA ~= isDecomposeB then
        return not isDecomposeA
    end

    local pluginA = XDataCenter.RiftManager.GetPlugin(dropDataA.PluginId)
    local pluginB = XDataCenter.RiftManager.GetPlugin(dropDataB.PluginId)
    if pluginA:GetStar() ~= pluginB:GetStar() then
        return pluginA:GetStar() > pluginB:GetStar()
    end

    return pluginA:GetId() > pluginB:GetId()
end

function XUiRiftSettlePlugin:RefreshDynamicTable()
    self.DataList = self.RiftSettleResult.PluginDropRecords
    table.sort(self.DataList, DropPluginSortFunc)

    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataSync(1)
end

function XUiRiftSettlePlugin:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local dropData = self.DataList[index]
        grid:Refresh(dropData)
    end
end

function XUiRiftSettlePlugin:OnDestroy()
    CS.XFight.ExitForClient(true)
end

return XUiRiftSettlePlugin