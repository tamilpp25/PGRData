local tableInsert = table.insert

local XUiFubenActivityPuzzleAreaRewardBtn = XClass(nil, "XUiFubenActivityPuzzleAreaRewardBtn")

function XUiFubenActivityPuzzleAreaRewardBtn:Ctor(rootUi, ui, cb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    self.CallBack = cb
    self:Init()
end

function XUiFubenActivityPuzzleAreaRewardBtn:Init()
    CsXUiHelper.RegisterClickEvent(self.BtnArea, self.CallBack)
end

function XUiFubenActivityPuzzleAreaRewardBtn:Refresh(itemIcon, count)
    self.Image1:SetRawImage(itemIcon)
    self.Image2:SetRawImage(itemIcon)
    self.TxtCount1.text = string.format("%s%s", "x", count)
    self.TxtCount2.text = string.format("%s%s", "x", count)
end

function XUiFubenActivityPuzzleAreaRewardBtn:SetNormal()
    self.LightAward.gameObject:SetActiveEx(false)
    self.GetAward.gameObject:SetActiveEx(false)
end

function XUiFubenActivityPuzzleAreaRewardBtn:SetCanTake()
    self.LightAward.gameObject:SetActiveEx(true)
    self.GetAward.gameObject:SetActiveEx(false)
end

function XUiFubenActivityPuzzleAreaRewardBtn:SetTaked()
    self.LightAward.gameObject:SetActiveEx(false)
    self.GetAward.gameObject:SetActiveEx(true)
end

return XUiFubenActivityPuzzleAreaRewardBtn