--推箱子主界面标题
local XUiPanelTitle = XClass(nil, "XUiPanelTitle")

function XUiPanelTitle:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiPanelTitle:Refresh(strTime)
    if self.TxtDay then
        self.TxtDay.text = strTime
    end
end

return XUiPanelTitle