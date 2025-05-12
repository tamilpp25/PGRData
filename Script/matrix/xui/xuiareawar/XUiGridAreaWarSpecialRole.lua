local XUiGridAreaWarSpecialRole = XClass(nil, "XUiGridAreaWarSpecialRole")

function XUiGridAreaWarSpecialRole:Ctor(ui, clickCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)

    --if self.BtnClick then
    --    self.BtnClick.CallBack = function()
    --        clickCb(self.RoleId)
    --    end
    --end
    if self.BtnClick then
        self.BtnClick.gameObject:SetActiveEx(false)
    end

    self:SetSelect(false)
end

function XUiGridAreaWarSpecialRole:Refresh(roleId)
    self.RoleId = roleId

    --小头像
    if self.RImgHead then
        self.RImgHead:SetRawImage(XAreaWarConfigs.GetSpecialRoleIcon(roleId))
    end

    --名称
    if self.TxtName then
        self.TxtName.text = XAreaWarConfigs.GetSpecialRoleName(roleId)
    end

    --立绘
    if self.RImgLihui then
        self.RImgLihui:SetRawImage(XAreaWarConfigs.GetSpecialRoleLihui(roleId))
    end

    --技能图标
    if self.RImgSkill then
        local buffId = XAreaWarConfigs.GetSpecialRoleBuffId(roleId)
        self.RImgSkill:SetRawImage(XAreaWarConfigs.GetBuffIcon(buffId))

        if self.TxtDetail then
            self.TxtDetail.text = XAreaWarConfigs.GetBuffDesc(buffId)
        end
    end

    --未解锁
    local isUnlock = XDataCenter.AreaWarManager.IsSpecialRoleUnlock(roleId)
    if self.PanelLock then
        self.PanelLock.gameObject:SetActiveEx(not isUnlock)
    end
    if self.PanelLock2 then
        self.PanelLock2.gameObject:SetActiveEx(not isUnlock)
    end
end

function XUiGridAreaWarSpecialRole:SetSelect(value)
    if self.PanelSelect then
        self.PanelSelect.gameObject:SetActiveEx(value and true or false)
    end
end

return XUiGridAreaWarSpecialRole
