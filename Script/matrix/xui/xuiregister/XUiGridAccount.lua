local XUiGridAccount = XClass(nil, "XUiGridAccount")

function XUiGridAccount:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUiGridAccount:Init(uiRoot)
    self.UiRoot = uiRoot
end

function XUiGridAccount:Refresh(data)
    if not data then return end
    self.Data = data
    self.BtnAccount:SetNameByGroup(0, data.Name)
    --local timeStr = XTime.TimestampToLocalDateTimeString(data.Time, "yyyy/MM/dd HH:mm")
    local timeStr = XUiHelper.CalcLatelyLoginTime(data.Time, os.time())
    self.BtnAccount:SetNameByGroup(1, timeStr)
end

return XUiGridAccount