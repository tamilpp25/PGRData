local XUiCombatTask = XClass(nil, "XUiCombatTask")

function XUiCombatTask:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.TxtBuff.gameObject:SetActiveEx(false)
    self:Init()
end

function XUiCombatTask:Init()
    local nowTaskContent = CS.XUiFightCombatTask.GetCurrentTaskInfo()
    if nowTaskContent then
        self.TxtTaskNow.text = nowTaskContent
        self.TxtTaskNow.gameObject:SetActiveEx(true)
    else
        self.TxtTaskNow.text = ""
        self.TxtTaskNow.gameObject:SetActiveEx(false)
    end

   local nextTaskContent = CS.XUiFightCombatTask.GetNextTaskInfo()
    if nextTaskContent then
        self.TxtTaskNext.text = nextTaskContent
        self.TxtTaskNext.gameObject:SetActiveEx(true)
    else
        self.TxtTaskNext.text = ""
        self.TxtTaskNext.gameObject:SetActiveEx(false)
    end

    self:GenerateBuff()
end

function XUiCombatTask:GenerateBuff()
    local data = CS.XUiFightCombatTask.GetResultInfos()
    local buffTable = XTool.CsObjectFields2LuaTable(data)
    if buffTable and next(buffTable) then
        for i, v in ipairs(buffTable) do
            local go = CS.UnityEngine.Object.Instantiate(self.TxtBuff, self.BuffContent)
            local buffText = go:GetComponent("Text")

            buffText.text = string.format("%s%s%s", i, ".", v)
            go.gameObject:SetActiveEx(true)
        end
    end
end

function XUiCombatTask:ShowPanel()
    self.IsShow = true
    self.GameObject:SetActiveEx(true)
end

function XUiCombatTask:HidePanel()
    self.IsShow = false
    self.GameObject:SetActiveEx(false)
end

function XUiCombatTask:CheckDataIsChange()
    return false
end

function XUiCombatTask:SaveChange()
end

function XUiCombatTask:CancelChange()
end

function XUiCombatTask:ResetToDefault()
end

return XUiCombatTask