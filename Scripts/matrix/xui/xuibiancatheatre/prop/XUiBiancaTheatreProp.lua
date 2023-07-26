local TheatreItemGrid = require("XUi/XUiBiancaTheatre/Common/XUiBiancaTheatreItemGrid")
local DetailPanel = require("XUi/XUiBiancaTheatre/Common/XUiItemDetailPanel")

--肉鸽玩法二期道具图鉴
local XUiBiancaTheatreProp = XLuaUiManager.Register(XLuaUi, "UiBiancaTheatreProp")

function XUiBiancaTheatreProp:OnAwake()
    self:InitItemList()
    self:InitButtonCallBack()
    self.PanelDetail = DetailPanel.New(self.PanelDetail, self)
    self:Refresh()
end

function XUiBiancaTheatreProp:OnStart()
    for _, item in pairs(self.ItemGrids or {}) do
        item:OnBtnClick()
        break
    end
end

function XUiBiancaTheatreProp:InitItemList()
    self.ItemGrids = {} --道具格子列表
    local itemTypeIdList = XBiancaTheatreConfigs.GetItemTypeIdList()
    local panelTitle, txtTitle
    local panelGroup, itemGrid, theatreItemGrid
    for _, typeId in ipairs(itemTypeIdList) do
        --道具组标题名
        panelTitle = XUiHelper.Instantiate(self.PanelTitle, self.Content)
        txtTitle = XUiHelper.TryGetComponent(panelTitle.transform, "TxtTitle", "Text")
        txtTitle.text = XBiancaTheatreConfigs.GetItemTypeName(typeId)
        --道具列表
        panelGroup = XUiHelper.Instantiate(self.PanelGroup, self.Content)
        itemGrid = XUiHelper.TryGetComponent(panelGroup.transform, "ItemGrid")
        for _, theatreItemId in ipairs(XBiancaTheatreConfigs.GetItemIdListByTypeId(typeId)) do
            local theatreItemIdTemp = theatreItemId
            theatreItemGrid = TheatreItemGrid.New(XUiHelper.Instantiate(itemGrid, panelGroup))
            theatreItemGrid.OnBtnClick = function()
                self:OnClickGrid(theatreItemIdTemp)
            end
            theatreItemGrid:Refresh(theatreItemIdTemp)
            self.ItemGrids[theatreItemIdTemp] = theatreItemGrid
        end
        itemGrid.gameObject:SetActiveEx(false)
    end
    self.PanelTitle.gameObject:SetActiveEx(false)
    self.PanelGroup.gameObject:SetActiveEx(false)
end

function XUiBiancaTheatreProp:InitButtonCallBack()
    self:RegisterClickEvent(self.BtnBack, self.Close)
    --self:RegisterClickEvent(self.GameObject, handler(self, self.HideTips))
    -- self.GameObject:AddComponent(typeof(CS.UnityEngine.UI.XEmpty4Raycast))
    -- ScrollRect的点击和拖拽会触发关闭详细面板
    --self:RegisterClickEvent(self.SViewlList, self.HideTips)
    --local dragProxy = self.SViewlList.gameObject:AddComponent(typeof(CS.XUguiDragProxy))
    --dragProxy:RegisterHandler(handler(self, self.OnDragProxy))
end

function XUiBiancaTheatreProp:Refresh()
    local txtPercent = XUiHelper.ReplaceTextNewLine(XBiancaTheatreConfigs.GetClientConfig("PropUnlockPercent"))
    local unlockCount = XDataCenter.BiancaTheatreManager.GetUnlockItemCount()
    local allItemCount = #XBiancaTheatreConfigs.GetTheatreItemIdList()
    self.TxtPercent.text = string.format(txtPercent, unlockCount, allItemCount)
end

function XUiBiancaTheatreProp:OnDragProxy(dragType)
    if dragType == 0 then
        --开始滑动
        self:HideTips()
    end
end

function XUiBiancaTheatreProp:OnClickGrid(theatreItemId)
    self:PlayAnimation("QieHuan")
    XDataCenter.BiancaTheatreManager.SetFieldGuideGridRedPointClear(theatreItemId)
    if self.CurItemGrid then
        self.CurItemGrid:SetIsSelect(false)
        self.CurItemGrid = nil
    end
    
    local itemGrid = self.ItemGrids[theatreItemId]
    if not itemGrid then
        return
    end

    itemGrid:SetIsSelect(true)
    self.CurItemGrid = itemGrid
    self.PanelDetail:Show(theatreItemId)

    --红点刷新
    itemGrid:RefreshReddot(theatreItemId)
end

function XUiBiancaTheatreProp:HideTips()
    self.PanelDetail:Hide()
end 