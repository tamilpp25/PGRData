-- 兵法蓝图养成界面更换成员窗口控件
local XUiRpgTowerRoleListChangeMember = XClass(nil, "XUiRpgTowerRoleListChangeMember")
local XUiRpgTowerChangeMemberList = require("XUi/XUiRpgTower/CharacterPage/ChangeMemberPage/XUiRpgTowerChangeMemberList")
function XUiRpgTowerRoleListChangeMember:Ctor(ui, page)
    XTool.InitUiObjectByUi(self, ui)
    self.Page = page
    XUiHelper.RegisterClickEvent(self, self.BtnCancel, function() self:OnClickCancel() end)
    self.ChangeMemberList = XUiRpgTowerChangeMemberList.New(self.PanelScrollView, self, self.Page.RootUi)
    self.AnimDisable:stopped('+', function(director) self:HidePanelCallBack() end)
end
--================
--显示面板
--================
function XUiRpgTowerRoleListChangeMember:ShowPanel()
    self.AnimDisable.gameObject:SetActiveEx(false)
    self.GameObject:SetActiveEx(true)
    self.ChangeMemberList:UpdateData()
end
--================
--刷新面板
--================
function XUiRpgTowerRoleListChangeMember:UpdateData()

end
--================
--隐藏面板
--================
function XUiRpgTowerRoleListChangeMember:HidePanel()
    self.AnimDisable.gameObject:SetActiveEx(true)
end
--================
--隐藏面板动画结束回调
--================
function XUiRpgTowerRoleListChangeMember:HidePanelCallBack(director)
    self.GameObject:SetActiveEx(false)
end
--================
--点击关闭按钮
--================
function XUiRpgTowerRoleListChangeMember:OnClickCancel()
    self.Page.RootUi:OpenPreChildPage()
end

return XUiRpgTowerRoleListChangeMember