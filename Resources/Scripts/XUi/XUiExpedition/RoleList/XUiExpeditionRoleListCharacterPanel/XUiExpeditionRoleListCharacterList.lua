--虚像地平线成员列表页面：角色列表
local XUiExpeditionRoleListCharacterList = XClass(nil, "XUiExpeditionRoleListCharacterList")
local XUiExpeditionRoleListCharacterGrid = require("XUi/XUiExpedition/RoleList/XUiExpeditionRoleListCharacterPanel/XUiExpeditionRoleListCharacterGrid")

function XUiExpeditionRoleListCharacterList:Ctor(ui, rootUi, gridTemplate)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.RootUi = rootUi
    self.GridTemplate = gridTemplate
    self.GridTemplate.gameObject:SetActiveEx(false)
    self:UpdateData()
end

function XUiExpeditionRoleListCharacterList:UpdateData(index)
    self.MemberList = XDataCenter.ExpeditionManager.GetTeam():GetDisplayTeamList()
    self.CurrentSelect = index or 1
    if not self.GridCharacter then self.GridCharacter = {} end
    for i = 1, #self.MemberList do
        if not self.GridCharacter[i] then
            local prefab = CS.UnityEngine.Object.Instantiate(self.GridTemplate.gameObject)
            prefab.transform:SetParent(self.Transform, false)
            self.GridCharacter[i] = XUiExpeditionRoleListCharacterGrid.New(prefab, self.RootUi, i, function(index) self:SetSelect(index) end)
        end
    end
    for i = 1, #self.GridCharacter do
        if self.MemberList[i] then
            self.GridCharacter[i]:Show()
            self.GridCharacter[i]:RefreshDatas(self.MemberList[i])
        else
            self.GridCharacter[i]:Hide()
        end
    end
    if self.GridCharacter[self.CurrentSelect] then
        self.GridCharacter[self.CurrentSelect]:SetSelect(true)
    end
end

function XUiExpeditionRoleListCharacterList:SetSelect(index)
    if self.CurrentSelect == index then return end
    if self.CurrentSelect and self.GridCharacter[self.CurrentSelect] then
        self.GridCharacter[self.CurrentSelect]:SetSelect(false)
    end
    self.CurrentSelect = index
end

return XUiExpeditionRoleListCharacterList