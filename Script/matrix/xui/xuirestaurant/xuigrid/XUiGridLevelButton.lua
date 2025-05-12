---@class XUiGridLevelButton : XUiNode
---@field _Control XRestaurantControl
local XUiGridLevelButton = XClass(XUiNode, "XUiGridLevelButton")

function XUiGridLevelButton:OnStart(onClick)
    self.OnClick = onClick

    self.BtnLevel.CallBack = function()
        self:OnBtnLevelClick()
    end
end

function XUiGridLevelButton:Refresh(level, curLevel, isUnlock, disable, levelStr, selectLevel)
    self.Level = level
    self.CurLevel = curLevel
    self.IsUnlock = isUnlock
    self.Disable = disable
    if not XTool.UObjIsNil(self.PanelDisable) then
        self.PanelDisable.gameObject:SetActiveEx(disable)
    end
    self.BtnLevel:SetNameByGroup(0, levelStr)
    self:SetSelect(selectLevel == level)
    self.BtnLevel:ShowReddot(self._Control:CheckRestaurantUpgradeRedPoint(level))
    self:Open()
    
    self.GameObject.name = string.format("BtnLevel%d", level)
end

function XUiGridLevelButton:SetSelect(select)
    self.IsSelect = select

    --新 Ui
    if self.SelectDisable then
        self.SelectDisable.gameObject:SetActiveEx(select and self.Disable)
        self.ImgNormal.gameObject:SetActiveEx(not select and not self.Disable)
        self.ImgSelect.gameObject:SetActiveEx(select and not self.Disable)
        self.NormalDisable.gameObject:SetActiveEx(not select and self.Disable)
    else
        self.ImgNormal.gameObject:SetActiveEx(not select)
        self.ImgSelect.gameObject:SetActiveEx(select)
    end
end

function XUiGridLevelButton:OnBtnLevelClick()
    if self.IsSelect then
        return
    end
    self:SetSelect(true)
    if self.OnClick then self.OnClick(self) end
end

return XUiGridLevelButton