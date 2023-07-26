local XUiSSBReadyPanelOwn = require("XUi/XUiSuperSmashBros/Ready/Panels/XUiSSBReadyPanelOwn")
local XUiSSBReadyPanelEnemy = require("XUi/XUiSuperSmashBros/Ready/Panels/XUiSSBReadyPanelEnemy")
local XSmashBRecord = require("XEntity/XSuperSmashBros/XSmashBRecord")

---@class XUiSuperSmashBrosVictoryListGrid
local XUiSuperSmashBrosVictoryListGrid = XClass(nil, "XUiSuperSmashBrosVictoryListGrid")

function XUiSuperSmashBrosVictoryListGrid:Ctor(ui, mode, result, index, callback)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self._Mode = mode
    if result then
        ---@type XSmashBRecord
        self._Record = XSmashBRecord.New(mode, result, index)
    else
        self._Record = false
    end
    self._Callback = callback
    self._Index = index
    self:InitPanelEnemy()
    self:InitPanelOwn()
    self:RegisterClick()
end

function XUiSuperSmashBrosVictoryListGrid:GetRecord()
    return self._Record or self._Mode
end

function XUiSuperSmashBrosVictoryListGrid:Refresh()
    self.Own:Refresh(nil, self._Record, self._Index)
    self.Enemy:Refresh()
    self.TxtSpeed.text = XUiHelper.GetText("SuperSmashProgress2", self:GetRecord():GetLineProgress())
end

function XUiSuperSmashBrosVictoryListGrid:InitPanelOwn()
    ---@type XUiSSBReadyPanelOwn
    self.Own = XUiSSBReadyPanelOwn.New(self.PanelOwn, self:GetRecord(), true)
end

function XUiSuperSmashBrosVictoryListGrid:InitPanelEnemy()
    ---@type XUiSSBReadyPanelEnemy
    self.Enemy = XUiSSBReadyPanelEnemy.New(self.PanelEnemy, self:GetRecord(), true)
end

function XUiSuperSmashBrosVictoryListGrid:RegisterClick()
    if not self._Callback then
        return
    end
    XUiHelper.RegisterClickEvent(self, XUiHelper.TryGetComponent(self.Transform, "", "XUiButton"), self._Callback)
end

function XUiSuperSmashBrosVictoryListGrid:UpdateSelected(isSelected, isCancelSelected)
    self.ImgSelected.gameObject:SetActiveEx(isSelected)
    self.ImgBg.gameObject:SetActiveEx(isCancelSelected)
end

return XUiSuperSmashBrosVictoryListGrid