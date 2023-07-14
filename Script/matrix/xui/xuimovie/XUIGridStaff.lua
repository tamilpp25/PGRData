local stringUtf8Len = string.Utf8Len
local DefaultColor = CS.UnityEngine.Color.white

local XUIGridStaff = XClass(nil, "XUIGridStaff")

function XUIGridStaff:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

function XUIGridStaff:Refresh(staffPath, staffId)
    local name = XMovieConfigs.GetStaffName(staffPath, staffId)
    self.Text.text = name
end

return XUIGridStaff