local XUiDlcHuntBagGridChip = require("XUi/XUiDlcHunt/Bag/XUiDlcHuntBagGridChip")
local XUiDlcHuntBagGridOthers = require("XUi/XUiDlcHunt/Bag/XUiDlcHuntBagGridOthers")
local GRID_TYPE = {
    CHIP = 1,
    OTHERS = 2,
}

---@class XUiDlcHuntBagGrid
local XUiDlcHuntBagGrid = XClass(nil, "XUiDlcHuntBagGrid")

function XUiDlcHuntBagGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    ---@type XUiDlcHuntBagGridChip
    self._GridChip = XUiDlcHuntBagGridChip.New(self.GridChip)
    ---@type XUiDlcHuntBagGridOthers
    self._GridOthers = XUiDlcHuntBagGridOthers.New(self.GridFragment)

    self._Type = GRID_TYPE.CHIP
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnClick)
end

function XUiDlcHuntBagGrid:Update(data)
    if data.__cname == "XDlcHuntChip" then
        self._Type = GRID_TYPE.CHIP
        self.GridChip.gameObject:SetActiveEx(true)
        self.GridFragment.gameObject:SetActiveEx(false)
        self._GridChip:Update(data)
    end
    if data.__cname == "XItem" then
        self._Type = GRID_TYPE.OTHERS
        self.GridChip.gameObject:SetActiveEx(false)
        self.GridFragment.gameObject:SetActiveEx(true)
        self._GridOthers:Update(data)
    end
end

function XUiDlcHuntBagGrid:UpdateSelected()
    if self._Type == GRID_TYPE.CHIP then
        self._GridChip:UpdateSelected()
    end
    if self._Type == GRID_TYPE.OTHERS then
        self._GridOthers:UpdateSelected()
    end
end

function XUiDlcHuntBagGrid:SetViewModel(...)
    if self._Type == GRID_TYPE.CHIP then
        self._GridChip:SetViewModel(...)
    end
    if self._Type == GRID_TYPE.OTHERS then
        self._GridOthers:SetViewModel(...)
    end
end

function XUiDlcHuntBagGrid:OnClick()
    if self._Type == GRID_TYPE.CHIP then
        self._GridChip:OnClick()
    end
    if self._Type == GRID_TYPE.OTHERS then
        self._GridOthers:OnClick()
    end
end

return XUiDlcHuntBagGrid