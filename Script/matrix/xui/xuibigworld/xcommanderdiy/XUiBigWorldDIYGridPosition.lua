---@class XUiBigWorldDIYGridPosition : XUiNode
---@field BtnClick XUiComponent.XUiButton
---@field ImgBg UnityEngine.UI.Image
---@field ImgPosition UnityEngine.UI.Image
---@field TxtName UnityEngine.UI.Text
---@field PanelNow UnityEngine.RectTransform
---@field Red UnityEngine.RectTransform
---@field PanelNone UnityEngine.RectTransform
---@field ImgSelect UnityEngine.UI.Image
---@field _Control XBigWorldCommanderDIYControl
---@field Parent XUiBigWorldDIY
local XUiBigWorldDIYGridPosition = XClass(XUiNode, "XUiBigWorldDIYGridPosition")

-- region 生命周期
function XUiBigWorldDIYGridPosition:OnStart()
    ---@type XBWCommanderDIYPartEntity
    self._Entity = false
    self._Index = 0

    self:_RegisterButtonClicks()
end

function XUiBigWorldDIYGridPosition:OnEnable()
    self:_RegisterSchedules()
    self:_RegisterListeners()
    self:_RegisterRedPointEvents()
end

function XUiBigWorldDIYGridPosition:OnDisable()
    self:_RemoveSchedules()
    self:_RemoveListeners()
end

function XUiBigWorldDIYGridPosition:OnDestroy()

end
-- endregion

---@param entity XBWCommanderDIYPartEntity
function XUiBigWorldDIYGridPosition:Refresh(entity, index)
    if not entity then
        return
    end

    if entity:IsTemporary() then
        self._Entity = entity
        self._Index = index

        self.TxtName.text = entity:GetName()
        self:SetSelect(self._Control:CheckEmptyPartEntityIsUse(entity), true)
        self:_RefreshEmpty(true)
        self:_RefreshPanelNow()
    elseif not entity:IsNil() then
        self._Entity = entity
        self._Index = index

        self.ImgPosition:SetSprite(entity:GetIcon())
        self.TxtName.text = entity:GetName()
        self:SetSelect(self._Control:CheckPartEntityIsUse(entity), true)
        self:_RefreshEmpty(false)
        self:_RefreshPanelNow()
    end
end

function XUiBigWorldDIYGridPosition:SetSelect(isSelect, isRefresh)
    self.ImgSelect.gameObject:SetActiveEx(isSelect)
    if isSelect then
        self.Parent:ShowColor(self._Entity)

        if isRefresh then
            self.Parent:ChangeSelectPart(self._Index)
        end
    end
end

-- region 按钮事件

function XUiBigWorldDIYGridPosition:OnBtnClickClick()
    if self._Entity:IsTemporary() then
        self._Control:ClearUsePartEntity(self._Entity)
    else
        self._Control:SetUsePartEntity(self._Entity)
    end
    self.Parent:ChangeSelect(self._Index)
    self:SetSelect(true)
end

-- endregion

-- region 私有方法
function XUiBigWorldDIYGridPosition:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnClickClick, true)
end

function XUiBigWorldDIYGridPosition:_RefreshPanelNow()
    if self._Entity:IsTemporary() then
        self.PanelNow.gameObject:SetActiveEx(self._Control:CheckEmptyPartEntityIsNow(self._Entity))
    else
        self.PanelNow.gameObject:SetActiveEx(self._Control:CheckPartEntityIsNow(self._Entity))
    end
end

function XUiBigWorldDIYGridPosition:_RefreshEmpty(isEmpty)
    self.ImgPosition.gameObject:SetActiveEx(not isEmpty)
    self.PanelNone.gameObject:SetActiveEx(isEmpty)
end

function XUiBigWorldDIYGridPosition:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiBigWorldDIYGridPosition:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiBigWorldDIYGridPosition:_RegisterListeners()
    -- 在此处注册事件监听
end

function XUiBigWorldDIYGridPosition:_RemoveListeners()
    -- 在此处移除事件监听
end

function XUiBigWorldDIYGridPosition:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end
-- endregion

return XUiBigWorldDIYGridPosition
