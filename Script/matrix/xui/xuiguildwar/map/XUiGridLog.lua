local XUiGridLog = XClass(nil, "XUiGridLog")
local CSTextManagerGetText = CS.XTextManager.GetText

function XUiGridLog:Ctor(ui, base)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    XTool.InitUiObject(self)
end

function XUiGridLog:UpdateGrid(log)
   if log then
        self.TxtTime.text = log.Time
        self.TxtName.text = log.Name
        self.TxtType.text = log.Text
   end
end

return XUiGridLog