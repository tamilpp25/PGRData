---@class XUiTheatre4SkillTips : XUiNode
---@field TxtName UnityEngine.UI.Text
---@field TxtDesc UnityEngine.UI.Text
---@field ImgIcon UnityEngine.UI.RawImage
---@field TxtCount UnityEngine.UI.Text
---@field ItemIcon UnityEngine.UI.RawImage
---@field BtnSure XUiComponent.XUiButton
---@field RawImageNormal UnityEngine.UI.RawImage
---@field RawImageSpecial UnityEngine.UI.RawImage
---@field _Control XTheatre4Control
---@field Parent XUiTheatre4Skill
local XUiTheatre4SkillTips = XClass(XUiNode, "XUiTheatre4SkillTips")

-- region 生命周期

function XUiTheatre4SkillTips:OnStart()
    ---@type XTheatre4TechEntity
    self._Entity = nil
    self:_RegisterButtonClicks()
    self.PanelLock.gameObject:SetActiveEx(false)
end

-- endregion

---@param entity XTheatre4TechEntity
function XUiTheatre4SkillTips:Refresh(entity, isSpecial)
    ---@type XTheatre4TechConfig
    local config = entity:GetConfig()
    local itemIcon = XDataCenter.ItemManager.GetItemIcon(XDataCenter.ItemManager.ItemId.Theatre4TechTreeCoin)

    self._Entity = entity
    self.TxtCount.text = config:GetCost()
    self.TxtDesc.text = config:GetDesc()
    self.TxtName.text = config:GetName()
    self.ImgIcon:SetRawImage(config:GetIcon())
    self.ItemIcon:SetRawImage(itemIcon)
    local isUnlock, desc = entity:IsUnlock()
    if entity:IsActived() or not isUnlock then
        if desc then
            -- 未解锁时，显示解锁条件
            self.PanelLock.gameObject:SetActiveEx(true)
            self.TxtCondition.text = desc
            self.BtnSure.gameObject:SetActiveEx(false)
        else
            self.PanelLock.gameObject:SetActiveEx(false)
            self.BtnSure.gameObject:SetActiveEx(true)
            self.BtnSure:SetButtonState(CS.UiButtonState.Disable)
            self.TxtCount.gameObject:SetActiveEx(false)

            if entity:IsActived() then
                self.BtnSure:SetNameByGroup(0, self._Control:GetClientConfig("SkillActiveText", 3))
            elseif not entity:IsUnlock() then
                self.BtnSure:SetNameByGroup(0, self._Control:GetClientConfig("SkillActiveText", 2))
            end 
        end
    else
        self.PanelLock.gameObject:SetActiveEx(false)
        self.BtnSure.gameObject:SetActiveEx(true)
        self.BtnSure:SetButtonState(CS.UiButtonState.Normal)
        self.BtnSure:SetNameByGroup(0, self._Control:GetClientConfig("SkillActiveText", 1))
        self.TxtCount.gameObject:SetActiveEx(true)
    end
    self.RawImageNormal.gameObject:SetActiveEx(not isSpecial)
    self.RawImageSpecial.gameObject:SetActiveEx(isSpecial or false)
end

-- region 按钮事件

function XUiTheatre4SkillTips:OnBtnSureClick()
    if self._Control:CheckAdventureDataEmpty() then
        if self._Entity and not self._Entity:IsEmpty() then
            if not self._Entity:IsActived() and self._Entity:IsUnlock() then
                ---@type XTheatre4TechConfig
                local config = self._Entity:GetConfig()
                local count = XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.Theatre4TechTreeCoin)

                if config and config:GetCost() <= count then
                    self._Control:TechUnlockRequest(config:GetId())
                else
                    XUiManager.TipMsg(self._Control:GetClientConfig("TechItemCountUnEnough", 1))
                end
            end
        end
    else
        XUiManager.TipMsg(self._Control:GetClientConfig("InGameOpenSkillTip", 1))
    end
end

-- endregion

-- region 私有方法

function XUiTheatre4SkillTips:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self._Control:RegisterClickEvent(self, self.BtnSure, self.OnBtnSureClick)
end

-- endregion

return XUiTheatre4SkillTips
