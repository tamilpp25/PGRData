local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XGridPlanetCard = require("XUi/XUiPlanet/Build/XGridPlanetCard")

---@class XPanelPlanetCard
local XPanelPlanetCard = XClass(nil, "XPanelPlanetCard")

function XPanelPlanetCard:Ctor(rootUi, ui, isTalent)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    self.BuildIdList = {}
    self.IsTalent = isTalent
    self.CurSelectCardIndex = 0

    self:InitDynamicTable()
    self:UpdateDynamicTable()
end

--region 列表刷新
function XPanelPlanetCard:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.SViewCardList)
    self.DynamicTable:SetProxy(XGridPlanetCard, self)
    self.DynamicTable:SetDelegate(self)
    self.GridCard.gameObject:SetActiveEx(false)
end

function XPanelPlanetCard:UpdateDynamicTable()
    if self.IsTalent then
        self.BuildIdList = XDataCenter.PlanetManager.GetTalentBuildCardList()
    else
        self.BuildIdList = {}
        local dataBuildingList = XDataCenter.PlanetManager.GetViewModel():GetSelectBuilding()
        for _, id in ipairs(dataBuildingList) do
            table.insert(self.BuildIdList, id)
        end
    end
    self.DynamicTable:SetDataSource(self.BuildIdList)
    self.DynamicTable:ReloadDataSync()
end

function XPanelPlanetCard:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local buildId = self.BuildIdList[index]
        grid:Refresh(buildId, self.IsTalent)
        grid:SetOnSelectCb(function()
            self:SelectCard(index)
        end)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        local buildId = self.BuildIdList[index]
        grid:InitRedPoint(buildId, self.IsTalent)
        grid.GameObject.name = "GridCard" .. self.BuildIdList[index]
    end
end

function XPanelPlanetCard:SelectCard(index)
    if self.IsTalent then
        -- 天赋球切换卡片时默认选中首个可用地板材质
        if self.CurSelectCardIndex ~= index then
            XDataCenter.PlanetManager.SetTalentCurBuildDefaultFloorId(self.BuildIdList[index])
        end
    end
    self.CurSelectCardIndex = index
    self:RefreshGird()
end

function XPanelPlanetCard:CancelSelectCard()
    self.CurSelectCardIndex = 0
    self:RefreshGird()
end

function XPanelPlanetCard:GetSelectBuildId()
    if self.CurSelectCardIndex == 0 then
        return false
    end
    return self.BuildIdList[self.CurSelectCardIndex]
end

function XPanelPlanetCard:RefreshGird()
    for index, grid in pairs(self.DynamicTable:GetGrids()) do
        grid:Refresh(self.BuildIdList[index], self.IsTalent)
    end
end
--endregion

--region 拖拽管理
function XPanelPlanetCard:SetIsInDrag(isInDrag)
    self._IsInDrag = isInDrag
end

function XPanelPlanetCard:GetIsInDrag()
    return self._IsInDrag
end

function XPanelPlanetCard:SetCopyCard(cardObj)
    self.CopyGameObject = cardObj
end

function XPanelPlanetCard:GetCopyCard()
    return self.CopyGameObject
end

function XPanelPlanetCard:SetCopyCardUiObject(cardUiObj)
    self.CopyCardUiObject = cardUiObj
end

function XPanelPlanetCard:GetCopyCardUiObject()
    return self.CopyCardUiObject
end

function XPanelPlanetCard:DestroyCopyCard()
    if not XTool.UObjIsNil(self.CopyGameObject) then
        XUiHelper.Destroy(self.CopyGameObject)
        self.CopyGameObject = nil
        self.CopyCardUiObject = {}
    end
end
--endregion

return XPanelPlanetCard