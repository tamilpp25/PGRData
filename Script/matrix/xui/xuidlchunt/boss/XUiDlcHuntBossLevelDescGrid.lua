---@class XUiDlcHuntBossLevelDescGrid
local XUiDlcHuntBossLevelDescGrid = XClass(nil, "XUiDlcHuntBossLevelDescGrid")

function XUiDlcHuntBossLevelDescGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiDlcHuntBossLevelDescGrid:Update(desc)
    self.TxtActive.text = desc
end

return XUiDlcHuntBossLevelDescGrid
