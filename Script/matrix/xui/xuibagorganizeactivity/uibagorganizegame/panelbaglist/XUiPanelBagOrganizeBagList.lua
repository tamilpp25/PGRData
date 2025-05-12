--- 玩法界面背包选择列表
---@class XUiPanelBagOrganizeBagList: XUiNode
---@field private _Control XBagOrganizeActivityControl
---@field BagRoot XUiButtonGroup
local XUiPanelBagOrganizeBagList = XClass(XUiNode, 'XUiPanelBagOrganizeBagList')

local XUiGridBagOrganizeBag = require('XUi/XUiBagOrganizeActivity/UiBagOrganizeGame/PanelBagList/XUiGridBagOrganizeBag')

function XUiPanelBagOrganizeBagList:OnStart()
    self._GameControl = self._Control.GameControl
    self.TxtTitle.text = self._Control:GetClientConfigText('BagListTitle', 1)
end

function XUiPanelBagOrganizeBagList:OnEnable()
    self._GameControl:AddEventListener(XMVCA.XBagOrganizeActivity.EventIds.EVENT_RANDOMEVENT_EFFECT_VALID, self.RefreshAllBagGridCostShow, self)
end

function XUiPanelBagOrganizeBagList:OnDisable()
    self._GameControl:RemoveEventListener(XMVCA.XBagOrganizeActivity.EventIds.EVENT_RANDOMEVENT_EFFECT_VALID, self.RefreshAllBagGridCostShow, self)
end

function XUiPanelBagOrganizeBagList:InitBags()
    if self._GameControl:IsMultyBagEnabled() then
        if not XTool.IsTableEmpty(self._BagDict) then
            for i, v in pairs(self._BagDict) do
                v:Close()
            end
        end

        if self._BagDict == nil then
            self._BagDict = {}
            self._BagIndex2Grid = {}
        end
        
        local btnList = {}
        
        local mapIds = self._Control:GetStageMapIdsById(self._Control:GetCurStageId())
        
        XUiHelper.RefreshCustomizedList(self.GridBag.transform.parent, self.GridBag, mapIds and #mapIds or 0, function(index, go)
            local grid = self._BagDict[go]

            if not grid then
                grid = XUiGridBagOrganizeBag.New(go, self)
                self._BagDict[go] = grid
            end

            self._BagIndex2Grid[index] = grid
            
            table.insert(btnList, grid.GridBtn)

            local bagDiscount = self._GameControl.TimelimitControl:GetBagDiscountEventEffect(mapIds[index])
            
            grid:Open()
            grid:Refresh(mapIds[index], bagDiscount)
        end)
        
        self.BagRoot:InitBtns(btnList, handler(self, self.OnBagSelect))

        -- 多背包玩法新关卡加载时默认选中第一个背包
        self._CurSelectIndex = nil
        self.BagRoot:SelectIndex(1, true)
    else
        self:Close()    
    end
end

function XUiPanelBagOrganizeBagList:OnBagSelect(index)
    if self._CurSelectIndex == index then
        return
    end
    
    if self._BagIndex2Grid[index] then
        self._CurSelectIndex = index
        self._BagIndex2Grid[index]:OnBagSelected()
    end
end

function XUiPanelBagOrganizeBagList:RefreshAllBagGridUnSelect()
    if not XTool.IsTableEmpty(self._BagDict) then
        for i, v in pairs(self._BagDict) do
            if v:IsNodeShow() then
                v:RefreshSelectState(false)
            end
        end
    end
end

function XUiPanelBagOrganizeBagList:RefreshAllBagGridCostShow()
    if not XTool.IsTableEmpty(self._BagDict) then
        for i, v in pairs(self._BagDict) do
            if v:IsNodeShow() then
                local bagDiscount = self._GameControl.TimelimitControl:GetBagDiscountEventEffect(v.MapId)
                v:RefreshCost(bagDiscount)
            end
        end
    end
end

return XUiPanelBagOrganizeBagList