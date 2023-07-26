local XUiGridNieRTaskBtn = XClass(nil, "XUiGridNieRTaskBtn")
function XUiGridNieRTaskBtn:Ctor(ui, rootUi)
    self.RootUi = rootUi
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
   
end

function XUiGridNieRTaskBtn:Refresh(data)
    local groupId = data.TaskGroupId
    local titleStr = data.TitleStr
    self.NormalTxt.text = titleStr
    self.PressTxt.text = titleStr
    self.SelectTxt.text = titleStr
    local red = XDataCenter.NieRManager.CheckNieRTaskRed(groupId)
    self.Red.gameObject:SetActiveEx(red)
end

function XUiGridNieRTaskBtn:IsSelect(isSel)
    self.Normal.gameObject:SetActiveEx(not isSel)
    self.Select.gameObject:SetActiveEx(isSel)
end

return XUiGridNieRTaskBtn