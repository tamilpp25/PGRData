-- 兵法蓝图养成界面更换成员面板
local XUiRpgTowerRoleListChangeMemberPage = XClass(nil, "XUiRpgTowerRoleListChangeMemberPage")
local XUiRpgTowerRoleListChangeMember = require("XUi/XUiRpgTower/CharacterPage/ChangeMemberPage/XUiRpgTowerRoleListChangeMember")
function XUiRpgTowerRoleListChangeMemberPage:Ctor(rootUi)
    self.RootUi = rootUi
    self:CreateChangeMemberWindow()
end
--================
--创建子面板控件（默认显示控件）
--================
function XUiRpgTowerRoleListChangeMemberPage:CreateChangeMemberWindow()
    local ui = self.RootUi:LoadChildPrefab("ChangeMember", XUiConfigs.GetComponentUrl("RpgTowerRoleListChildWindowChangeMember"))
    self.ChangeMember = XUiRpgTowerRoleListChangeMember.New(ui, self)
end
--================
--打开页面
--================
function XUiRpgTowerRoleListChangeMemberPage:ShowPage()
    self.RootUi:UpdateCamera(XDataCenter.RpgTowerManager.UiCharacter_Camera.CHANGEMEMBER)
    self.ChangeMember:ShowPanel()
    self.RootUi:SetModelDragFieldActive(false)
end
--================
--刷新页面
--================
function XUiRpgTowerRoleListChangeMemberPage:RefreshPage()
    self.ChangeMember:UpdateData()
end
--================
--隐藏页面
--================
function XUiRpgTowerRoleListChangeMemberPage:HidePage()
    self.ChangeMember:HidePanel()
end

return XUiRpgTowerRoleListChangeMemberPage