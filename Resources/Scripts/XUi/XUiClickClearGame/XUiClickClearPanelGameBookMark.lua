local textManager = CS.XTextManager

local XUiClickClearPanelGameBookMark = XClass(nil, "XUiClickClearPanelGameBookMark")

function XUiClickClearPanelGameBookMark:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    self:Init()
end

function XUiClickClearPanelGameBookMark:Init()
    self.PressPoints = {
        self.Pressed1,
        self.Pressed2,
        self.Pressed3,
        self.Pressed4,
        self.Pressed5,
        self.Pressed6,
        self.Pressed7,
        self.Pressed8,
        self.Pressed9,
    }
end

function XUiClickClearPanelGameBookMark:Show()
    local gameInfo = XDataCenter.XClickClearGameManager.GetGameInfo()
    local pageCount = gameInfo.HeadInfoPageCount
    for i,v in ipairs(self.PressPoints) do
        if i < pageCount then
            v.gameObject:SetActiveEx(true)
        else
            v.gameObject:SetActiveEx(false)
        end
    end
    self.GameObject:SetActiveEx(true)
    self:RefreshBookMark()
end

function XUiClickClearPanelGameBookMark:RefreshBookMark()
    local gameInfo = XDataCenter.XClickClearGameManager.GetGameInfo()
    local pageIndex = gameInfo.CurrentHeadRealPageIndex
    self.CurPoint.transform:SetSiblingIndex(pageIndex-1)
end

function XUiClickClearPanelGameBookMark:Hide()
    self.GameObject:SetActiveEx(false)
end

return XUiClickClearPanelGameBookMark