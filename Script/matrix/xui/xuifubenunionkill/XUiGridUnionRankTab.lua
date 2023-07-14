local XUiGridUnionRankTab = XClass(nil, "XUiGridUnionRankTab")

function XUiGridUnionRankTab:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi

    XTool.InitUiObject(self)
end

function XUiGridUnionRankTab:Refresh(rankLevelTemplate)
    local levelDesc = CS.XTextManager.GetText("UnionRankLevel", rankLevelTemplate.MinLevel, rankLevelTemplate.MaxLevel)
    self.GridRankLevel:SetNameByGroup(0, levelDesc)
    self.GridRankLevel:SetNameByGroup(1, rankLevelTemplate.Name)
    self.RImgRankIcon:SetRawImage(rankLevelTemplate.Icon)
end

function XUiGridUnionRankTab:GetUiButton()
    return self.GridRankLevel
end

return XUiGridUnionRankTab