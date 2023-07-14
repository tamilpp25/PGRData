local XUiPanelLevelBreak = XClass(nil, "XUiPanelLevelBreak")
local XUiGridCostItem = require("XUi/XUiEquipBreakThrough/XUiGridCostItem")
local XUiGridPartnerAttrib = require("XUi/XUiPartner/PartnerCommon/XUiGridPartnerAttrib")
local moneyIndex = 1
local CONDITION_COLOR = {
    [true] = CS.UnityEngine.Color.black,
    [false] = CS.UnityEngine.Color.gray,
}
function XUiPanelLevelBreak:Ctor(ui, base, root)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    self.Root = root
    self.AttrGridList = {}
    XTool.InitUiObject(self)
    
    self.GridLevelChange.gameObject:SetActiveEx(false)
    self.GridCostItem.gameObject:SetActiveEx(false)
    
    self:SetButtonCallBack()
end

function XUiPanelLevelBreak:UpdatePanel(data)---刷新掉这个
    self.Data = data
    self:UpdatePartnerPreView()
    self:UpdateBreakthroughConsume()
    self.GameObject:SetActiveEx(true)
end

function XUiPanelLevelBreak:HidePanel()
    self.GameObject:SetActiveEx(false)
end

function XUiPanelLevelBreak:UpdatePartnerPreView()
    local nextBreakthrough = self.Data:GetBreakthrough() + 1
    self.TxtCurLevel.text = self.Data:GetBreakthroughLevelLimit()
    self.TxtNextLevel.text = self.Data:GetBreakthroughLevelLimit(nextBreakthrough)

    local preAttrMap = self.Data:GetBreakthroughPromotedAttrMap(nextBreakthrough)
    local curAttrMap = self.Data:GetBreakthroughPromotedAttrMap()
    for attrIndex, attrInfo in pairs(curAttrMap) do
        local preAttrInfo = preAttrMap[attrIndex]

        local grid = self.AttrGridList[attrIndex]
        if not grid then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridLevelChange)
            grid = XUiGridPartnerAttrib.New(ui, CS.XTextManager.GetText("EquipBreakThroughPopUpAttrPrefix", attrInfo.Name), false)
            grid.Transform:SetParent(self.PanelAttrParent, false)
            self.AttrGridList[attrIndex] = grid
        end
        grid.GameObject:SetActiveEx(true)
        grid:UpdateData(attrInfo.Value, preAttrInfo.Value, true)
    end

    for i = #curAttrMap + 1, #self.AttrGridList do
        self.AttrGridList[i].GameObject:SetActiveEx(false)
    end
end

function XUiPanelLevelBreak:UpdateBreakthroughConsume()
    local costMoney = self.Data:GetBreakthroughMoney().Count
    self.TxtCost.text = costMoney
    self.TxtCost.color = CONDITION_COLOR[XDataCenter.ItemManager.GetCoinsNum() >= costMoney]

    self.GridCostItems = self.GridCostItems or {}
    local consumeItems = self.Data:GetBreakthroughItem()
    
    for index, item in ipairs(consumeItems) do
        local grid = self.GridCostItems[index]
        if not grid then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridCostItem)
            grid = XUiGridCostItem.New(self.Root, ui)
            grid.Transform:SetParent(self.PanelCostItem, false)
            self.GridCostItems[index] = grid
        end
        grid.GameObject:SetActiveEx(true)
        grid:Refresh(item.Id, item.Count)
    end

    for i = #consumeItems + 1, #self.GridCostItems do
        self.GridCostItems[i].GameObject:SetActiveEx(false)
    end
end

function XUiPanelLevelBreak:SetButtonCallBack()
    self.BtnBreak.CallBack = function()
        self:OnBtnBreakClick()
    end
end

function XUiPanelLevelBreak:OnBtnBreakClick()
    local nextBreakthrough = self.Data:GetBreakthrough() + 1
    local nextLevelLimit = self.Data:GetBreakthroughLevelLimit(nextBreakthrough)
    local preAttrMap = self.Data:GetBreakthroughPromotedAttrMap(nextBreakthrough)
    local curAttrMap = self.Data:GetBreakthroughPromotedAttrMap()
    XDataCenter.PartnerManager.PartnerBreakThroughRequest(self.Data:GetId(), function ()
            local exBreakthrough = self.Data:GetBreakthrough() - 1
            local viewCurLevelLimit = self.Data:GetBreakthroughLevelLimit()
            local viewCurAttrMap = self.Data:GetBreakthroughPromotedAttrMap()
            local viewExAttrMap = self.Data:GetBreakthroughPromotedAttrMap(exBreakthrough)
            XLuaUiManager.Open("UiEquipBreakThroughPopUp", viewCurLevelLimit, viewExAttrMap, viewCurAttrMap, function()
                    self.Base:UpdatePanel(self.Data)
                end)
    end)
end

return XUiPanelLevelBreak