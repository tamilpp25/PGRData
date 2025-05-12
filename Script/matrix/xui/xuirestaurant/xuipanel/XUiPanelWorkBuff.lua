local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridWorkBuff = XClass(XUiNode, "XUiGridWorkBuff")

function XUiGridWorkBuff:Refresh(areType, id, isRole)
    ---@type XRestaurantControl
    local control = self._Control
    local icon
    local isUnlock = false
    if isRole then
        local staff = control:GetCharacter(id)
        icon = staff:GetIcon()
        isUnlock = true
    else
        local product = control:GetProduct(areType, id)
        isUnlock = product:IsUnlock()
        icon = product:GetProductIcon()
    end
    self.RImgIcon.gameObject:SetActiveEx(isUnlock)
    self.RImgLock.gameObject:SetActiveEx(not isUnlock)
    if isUnlock then
        self.RImgIcon:SetRawImage(icon)
    end
end


---@class XUiPanelWorkBuff : XUiNode 工作界面Buff
---@field _Control XRestaurantControl
local XUiPanelWorkBuff = XClass(XUiNode, "XUiPanelWorkBuff")

function XUiPanelWorkBuff:OnStart(areaType, isRole)
    self.AreaType = areaType
    self.IsRole = isRole
    
    self.BtnClick.CallBack = function() 
        self:OnBtnClick()
    end
    
    self:InitUi()
end

function XUiPanelWorkBuff:InitUi()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelList)
    self.DynamicTable:SetProxy(XUiGridWorkBuff, self.Parent)
    self.DynamicTable:SetDelegate(self)
    
    self.GridObject.gameObject:SetActiveEx(false)
end

function XUiPanelWorkBuff:OnEnable()
    local business = self._Control:GetBusiness()
    business:BindViewModelPropertyToObj(self.GameObject:GetHashCode(), business.Property.BuffRedPointMarkCount, function()
        self:Refresh()
    end)
end

function XUiPanelWorkBuff:OnDisable()
    self._Control:GetBusiness():ClearBind(self.GameObject:GetHashCode())
end

function XUiPanelWorkBuff:Refresh()
    self.BtnClick:ShowReddot(self._Control:CheckBuffRedPoint(self.AreaType))
    local buff = self._Control:GetAreaBuff(self.AreaType)
    if not buff then
        self.PanelList.gameObject:SetActiveEx(false)
        self.PanelNone.gameObject:SetActiveEx(true)
        return
    end

    self.PanelList.gameObject:SetActiveEx(true)
    self.PanelNone.gameObject:SetActiveEx(false)
    if self.IsRole then
        self.DataList = buff:GetEffectCharacterIds(self.AreaType)
    else
        self.DataList = buff:GetEffectProductIds(self.AreaType)
    end

    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataSync()
end

function XUiPanelWorkBuff:OnDynamicTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.AreaType, self.DataList[index], self.IsRole)
    end
end

function XUiPanelWorkBuff:OnBtnClick()
    if not self._Control:CheckAreaBuffUnlock(self.AreaType) then
        XUiManager.TipMsg(self._Control:GetBuffAreaUnlockTip(self.AreaType))
        return
    end
    local buff = self._Control:GetAreaBuff(self.AreaType)
    local buffId = buff and buff:GetBuffId() or nil
    self._Control:OpenBuff(false, buffId)
end

return XUiPanelWorkBuff