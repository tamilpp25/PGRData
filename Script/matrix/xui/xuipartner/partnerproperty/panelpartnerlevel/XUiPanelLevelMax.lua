local XUiPanelLevelMax = XClass(nil, "XUiPanelLevelMax")
local XUiGridPartnerAttrib = require("XUi/XUiPartner/PartnerCommon/XUiGridPartnerAttrib")

function XUiPanelLevelMax:Ctor(ui, base, root)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    self.Root = root
    self.AttrGridList = {}
    XTool.InitUiObject(self)
    self.GridLevelChange.gameObject:SetActiveEx(false)
end

function XUiPanelLevelMax:UpdatePanel(data)---刷新掉这个
    self.Data = data
    self:UpdatePartnerInfo()
    self.GameObject:SetActiveEx(true)
end

function XUiPanelLevelMax:HidePanel()
    self.GameObject:SetActiveEx(false)
end

function XUiPanelLevelMax:UpdatePartnerInfo()
    local btImg = self.Data:GetBreakthroughIcon()
    
    self.Txtname.text = self.Data:GetName()
    self.TxtLevel.text = self.Data:GetLevel()
    self.TxtLevelMax.text = string.format("/%d MAX",self.Data:GetBreakthroughLevelLimit())
    self.ImgBreak:SetSprite(btImg)
    
    local curAttrMap = self.Data:GetPartnerAttrMap()
    for attrIndex, attrInfo in pairs(curAttrMap) do
        local grid = self.AttrGridList[attrIndex]
        if not grid then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridLevelChange)
            grid = XUiGridPartnerAttrib.New(ui, attrInfo.Name, true)
            grid.Transform:SetParent(self.PanelAttrParent, false)
            
            self.AttrGridList[attrIndex] = grid
        end
        grid.GameObject:SetActiveEx(true)
        grid:UpdateData(attrInfo.Value)
    end

    for i = #curAttrMap + 1, #self.AttrGridList do
        self.AttrGridList[i].GameObject:SetActiveEx(false)
    end
end

return XUiPanelLevelMax