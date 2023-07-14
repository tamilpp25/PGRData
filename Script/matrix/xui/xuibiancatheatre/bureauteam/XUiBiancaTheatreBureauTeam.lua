local XUiBiancaTheatreItemGrid = require("XUi/XUiBiancaTheatre/Common/XUiBiancaTheatreItemGrid")
local XUiItemDetailPanel = require("XUi/XUiBiancaTheatre/Common/XUiItemDetailPanel")


--肉鸽玩法二期 本局小队和已获取道具列表界面
local XUiBiancaTheatreBureauTeam = XLuaUiManager.Register(XLuaUi, "UiBiancaTheatreBureauTeam")

function XUiBiancaTheatreBureauTeam:OnAwake()
    self.ItemDetailPanel = XUiItemDetailPanel.New(self.PanelDetail, self)
    self.AdventureManager = XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager()
    self:InitButtonCallBack()
    self:InitDeyamicTable()
end

function XUiBiancaTheatreBureauTeam:OnEnable()
    self:Refresh()
end

function XUiBiancaTheatreBureauTeam:InitButtonCallBack()
    self:BindExitBtns()
    --self:RegisterClickEvent(self.GameObject, handler(self, self.HideDetail))
    --self.GameObject:AddComponent(typeof(CS.UnityEngine.UI.XEmpty4Raycast))
    self:RegisterClickEvent(self.BtnCloseDetail, self.HideDetail)
end


-- Ui刷新相关
--------------------------------------------------------------------------------

function XUiBiancaTheatreBureauTeam:Refresh()
    self:UpdateItems()
    self:UpdateTeam()
    self:UpdateTeamEffectTxt()
    self:UpdateVisionEffect()
    XDataCenter.BiancaTheatreManager.UpdateChapterBg(self.Bg)
end

--刷新分队
function XUiBiancaTheatreBureauTeam:UpdateTeam()
    local teamId = self.AdventureManager:GetCurTeamId()
    if not XTool.IsNumberValid(teamId) then
        return
    end
    local teamType = XBiancaTheatreConfigs.GetTeamType(teamId)
    --分队类型名和颜色
    local teamTypeColor = XBiancaTheatreConfigs.GetTeamTypeColor(teamType)
    if teamTypeColor then
        self.TextTeamTypeName.text = XBiancaTheatreConfigs.GetTeamTypeName(teamType)
        self.ImageTeamType.color = XUiHelper.Hexcolor2Color(teamTypeColor)
        self.ImageTeamType.gameObject:SetActiveEx(true)
    else
        self.ImageTeamType.gameObject:SetActiveEx(false)
    end
    --分队名
    self.TxtTeamName.text = XBiancaTheatreConfigs.GetTeamName(teamId)
    --分队描述
    self.TxtTeamDesc.text = XBiancaTheatreConfigs.GetTeamDesc(teamId)
    --分队图标
    self.ImgIcon:SetRawImage(XBiancaTheatreConfigs.GetTeamIcon(teamId))
end

-- 调查团效果额外描述文本
function XUiBiancaTheatreBureauTeam:UpdateTeamEffectTxt()
    local teamId = self.AdventureManager:GetCurTeamId()
    -- 远征队调查团才显示额外描述
    if not XTool.IsNumberValid(teamId) or teamId ~= XBiancaTheatreConfigs.NeedExtraDescTeamId.ExpeditionTeam then
        self.TxtTeamDesc2.gameObject:SetActiveEx(false)
        return
    end
    self.TxtTeamDesc2.gameObject:SetActiveEx(true)
    self.TxtTeamDesc2.text = string.format(XBiancaTheatreConfigs.GetClientConfig("TxtBureauTeam5Effect"), 5 * XDataCenter.BiancaTheatreManager.GetGamePassNodeCount().."%")
end

function XUiBiancaTheatreBureauTeam:UpdateItems()
    self.DynamicTable:SetDataSource(self.TheatreItemList)
    self.DynamicTable:ReloadDataSync()

    local isEmpty = XTool.IsTableEmpty(self.TheatreItemList)
    self.PanelEmpty.gameObject:SetActiveEx(isEmpty)
    self.LocalProps.gameObject:SetActiveEx(not isEmpty)
end

function XUiBiancaTheatreBureauTeam:UpdateVisionEffect()
    if not self.Effect then
        self.Effect = XUiHelper.TryGetComponent(self.Transform, "FullScreenBackground/Effect")
    end
    if self.Effect then
        local isVisionOpen = XDataCenter.BiancaTheatreManager.CheckVisionIsOpen()
        self.Effect.gameObject:SetActiveEx(isVisionOpen)
    end
end

--------------------------------------------------------------------------------

-- 动态列表相关
--------------------------------------------------------------------------------

function XUiBiancaTheatreBureauTeam:InitDeyamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.SViewlList)
    self.DynamicTable:SetProxy(XUiBiancaTheatreItemGrid, true, self, true)
    self.DynamicTable:SetDelegate(self)
    self.TheatreItemList = self.AdventureManager:GetItemList()  --XTheatreItem的列表
    self.ItemGrid.gameObject:SetActiveEx(false)
end

function XUiBiancaTheatreBureauTeam:OnDynamicTableEvent(event, index, grid)
    local theatreItem = self.TheatreItemList[index]
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(theatreItem:GetItemId())
        grid:SetIsSelect(self.CurrTheatreItemUid == theatreItem:GetId())
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then 
        self:CancelGridSelect()
        grid:SetIsSelect(true)
        self.CurrTheatreItemUid = theatreItem:GetId()
        self.CurrTheatreItemId = grid:GetTheatreItemId()
        self:ShowDetail()
    end
end

--------------------------------------------------------------------------------

-- 秘藏品预览相关
--------------------------------------------------------------------------------

--取消所有格子的选中状态
function XUiBiancaTheatreBureauTeam:CancelGridSelect()
    local dynamicTable = self.DynamicTable
    for _, value in pairs(dynamicTable and dynamicTable:GetGrids() or {}) do
        value:SetIsSelect(false)
    end
end

function XUiBiancaTheatreBureauTeam:ShowDetail()
    self.ItemDetailPanel:Show(self.CurrTheatreItemId)
end

function XUiBiancaTheatreBureauTeam:HideDetail()
    self.ItemDetailPanel:Hide()
    self:CancelGridSelect()
end

--------------------------------------------------------------------------------