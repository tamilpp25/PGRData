--===========================================================================
--v1.28 分阶拆分-XUiPanelQualityPreview-属性成长动态列表：XUiPanelQualityAttributeGrid
--===========================================================================
local XUiPanelQualityAttributeGrid = XClass(nil, "XUiPanelQualityAttributeGrid")

local AttributeGrade = {
    Before = 1,     --升级前
    After = 2,      --升级后
}
local AttributeShow = {
    Life = 1,
    AttackNormal = 2,
    DefenseNormal = 3,
    Crit = 4,
    Quality = 5
}

function XUiPanelQualityAttributeGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
end

function XUiPanelQualityAttributeGrid:Init(parent, rootUi)
    self.Parent = parent
    self.RootUi = rootUi or parent
    XTool.InitUiObject(self)
end

function XUiPanelQualityAttributeGrid:Refresh(attributeData, isSelect, isMax)
    if isSelect and not isMax then 
        self.Nor.gameObject:SetActiveEx(false)
        self.BgSelect.gameObject:SetActiveEx(true)
        for _, i in pairs(AttributeShow) do
            if i == AttributeShow.Quality then
                self["BgSelectBefore"..i].text = XCharacterConfigs.GetCharQualityDesc(attributeData[AttributeGrade.Before][i])
                self["BgSelectAfter"..i].text = XCharacterConfigs.GetCharQualityDesc(attributeData[AttributeGrade.After][i])
            else
                self["BgSelectBefore"..i].text = attributeData[AttributeGrade.Before][i]
                self["BgSelectAfter"..i].text = attributeData[AttributeGrade.After][i]
            end
        end
    else
        self.Nor.gameObject:SetActiveEx(true)
        self.BgSelect.gameObject:SetActiveEx(false)
        for _, i in pairs(AttributeShow) do
            if i == AttributeShow.Quality then
                self["NorBefore"..i].text = XCharacterConfigs.GetCharQualityDesc(attributeData[AttributeGrade.Before][i])
                self["NorAfter"..i].text = XCharacterConfigs.GetCharQualityDesc(attributeData[AttributeGrade.After][i])
            else
                self["NorBefore"..i].text = attributeData[AttributeGrade.Before][i]
                self["NorAfter"..i].text = attributeData[AttributeGrade.After][i]
            end
        end
    end
end

return XUiPanelQualityAttributeGrid