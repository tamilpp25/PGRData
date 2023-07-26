local XUiPanelTeacher = XClass(nil, "XUiPanelTeacher")
local XUiGridPlayer = require("XUi/XUiMentorSystem/MentorFile/XUiGridPlayer")
local Vector3 = CS.UnityEngine.Vector3
function XUiPanelTeacher:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.TeacherGrid = {}
end

function XUiPanelTeacher:UpdatePanel(data)
    self.Data = data
    self.TeacherGrid = self.TeacherGrid or {}
    if not next(self.TeacherGrid) then
        local obj = CS.UnityEngine.Object.Instantiate(self.GridPlayer)
        obj.gameObject:SetActiveEx(true)
        obj.transform:SetParent(self.PanelPlayer, false)
        obj.transform.localPosition = Vector3(0, 0, 0)
        self.TeacherGrid = XUiGridPlayer.New(obj,true)
    end
    if data then
        self.TeacherGrid:UpdateGrid(data)
    end
end

function XUiPanelTeacher:GetParentNode()
    return self.PanelNext
end

return XUiPanelTeacher