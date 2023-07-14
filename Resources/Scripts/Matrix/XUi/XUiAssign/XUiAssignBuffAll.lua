local XUiAssignBuffAll = XClass(nil, "XUiAssignBuffAll")

function XUiAssignBuffAll:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self:InitComponent()
end

function XUiAssignBuffAll:InitComponent()
    self.SelectTxtBuff.gameObject:SetActiveEx(false)
    self.BuffTextList = {}
end

function XUiAssignBuffAll:Show()
    self.GameObject:SetActiveEx(true)
    return self:Refresh()
end

function XUiAssignBuffAll:Close()
    self.GameObject:SetActiveEx(false)
end

function XUiAssignBuffAll:GetBuffText(index)
    local txt = self.BuffTextList[index]
    if not txt then
        txt = CS.UnityEngine.Object.Instantiate(self.SelectTxtBuff)
        txt.transform:SetParent(self.PanelOccupyBuff, false)
        self.BuffTextList[index] = txt
    end
    return txt
end

function XUiAssignBuffAll:ResetBuffTextList(len)
    if #self.BuffTextList > len then
        for i = len + 1, #self.BuffTextList do
            self.BuffTextList[i].gameObject:SetActiveEx(false)
        end
    end
end

function XUiAssignBuffAll:Refresh()
    local buffList = XDataCenter.FubenAssignManager.GetAllBuffList()
    self:ResetBuffTextList(#buffList)
    for i, buffDesc in ipairs(buffList) do
        local txt = self:GetBuffText(i)
        txt.gameObject:SetActiveEx(true)
        txt.text = buffDesc
    end
    return (#buffList > 0)
end

return XUiAssignBuffAll