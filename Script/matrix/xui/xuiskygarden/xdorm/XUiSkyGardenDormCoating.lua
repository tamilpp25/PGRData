local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@class XUiSkyGardenDormCoating : XBigWorldUi
---@field _Control XSkyGardenDormControl
local XUiSkyGardenDormCoating = XMVCA.XBigWorldUI:Register(nil, "UiSkyGardenDormCoating")

function XUiSkyGardenDormCoating:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiSkyGardenDormCoating:OnStart()
    self:InitView()
end

function XUiSkyGardenDormCoating:OnDestroy()
    if self._SelectFashionId ~= self._CurFashionId then
        local skinId = self._Control:GetFashionSkinId(self._CurFashionId)
        self:SendChange3C(skinId)
    end
    
    XMVCA.XBigWorldGamePlay:SetCurNpcAndAssistActive(true, false)
    XMVCA.XBigWorldGamePlay:DeactivateVCamera("UiSkyGardenDormCameraChangeSkin", false)
end

function XUiSkyGardenDormCoating:InitUi()
    self._DynamicTable = XDynamicTableNormal.New(self.CoatingList)
    self._DynamicTable:SetDelegate(self)
    self._DynamicTable:SetProxy(require("XUi/XUiSkyGarden/XDorm/Grid/XUiGridSGFashion"), self)
    self.CoatingItem.gameObject:SetActiveEx(false)
    self.BtnNow.gameObject:SetActiveEx(false)
    
    self._IsHide = false
    
    self._CurFashionId = self._Control:GetCurFashionId()
end

function XUiSkyGardenDormCoating:InitCb()
    self._DoRefreshHideCb = handler(self, self.DoRefreshHide)
    
    self.BtnHideClose.CallBack = function() 
        self:OnBtnHideClick()
    end
    
    self.BtnHideOpen.CallBack = function() 
        self:OnBtnHideClick()
    end
    
    self.BtnBack.CallBack = function() 
        self:Close()
    end
    
    self.BtnTips.CallBack = function() 
        self:OnBtnTipsClick()
    end
    
    self.BtnSave.CallBack = function() 
        self:OnBtnSaveClick()
    end
end

function XUiSkyGardenDormCoating:InitView()
    self:SetupDynamicTable()
end

function XUiSkyGardenDormCoating:SetupDynamicTable()
    local dataList = self._Control:GetAllFashionIds()
    self._DataList = self:SortDataList(dataList)
    self._SelectFashionId = self._DataList[1]
    self._DynamicTable:SetDataSource(self._DataList)
    self._DynamicTable:ReloadDataSync()
end

---@param grid XUiGridSGFashion
function XUiSkyGardenDormCoating:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self._DataList[index], self._SelectFashionId)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        local selectGrid = self._DynamicTable:GetGridByIndex(1)
        if selectGrid then
            selectGrid:OnBtnClick()
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        grid:OnBtnClick()
    end
end

function XUiSkyGardenDormCoating:OnSelectFashion(fashionId, gird)
    if self._LastGrid then
        self._LastGrid:CancelSelect()
    end
    local isCur = self._Control:IsCurrentFashionId(fashionId)
    local isUnlock = self._Control:IsFashionUnlock(fashionId)
    self.BtnTips.gameObject:SetActiveEx(not isCur and not isUnlock)
    self.BtnSave:SetNameByGroup(0, self._Control:GetBtnFashionSaveText(isCur))
    self.BtnSave.gameObject:SetActiveEx(isUnlock and not isCur)
    self._LastGrid = gird
    
    local skinId = self._Control:GetFashionSkinId(fashionId)
    self:SendChange3C(skinId)
    self._SelectFashionId = fashionId
end

function XUiSkyGardenDormCoating:OnBtnHideClick()
    self._IsHide = not self._IsHide
    if self._IsHide then
        self:PlayAnimationWithMask("UiDisable", self._DoRefreshHideCb)
    else
        self:DoRefreshHide()
        self:PlayAnimationWithMask("UiEnable")
    end
end

function XUiSkyGardenDormCoating:DoRefreshHide()
    self.BtnHideOpen.gameObject:SetActiveEx(not self._IsHide)
    self.BtnHideClose.gameObject:SetActiveEx(self._IsHide)
    self.PanelCoatingMenu.gameObject:SetActiveEx(not self._IsHide)
    self.PanelBtn.gameObject:SetActiveEx(not self._IsHide)
    self.BtnBack.transform.parent.gameObject:SetActiveEx(not self._IsHide)
end

function XUiSkyGardenDormCoating:OnBtnTipsClick()
    if not self._SelectFashionId then
        return
    end
    XUiManager.TipMsg(self._Control:GetFashionLockDesc(self._SelectFashionId))
end

function XUiSkyGardenDormCoating:OnBtnSaveClick()
    if self._Control:IsCurrentFashionId(self._SelectFashionId) then
        return
    end
    
    self._Control:RequestSetFashion(self._SelectFashionId, function()
        XUiManager.TipMsg(self._Control:GetLayoutChangeText(1))
        self._CurFashionId = self._SelectFashionId
        self:SetupDynamicTable()
    end)
end

function XUiSkyGardenDormCoating:SortDataList(dataList)
    if XTool.IsTableEmpty(dataList) then
        return {}
    end
    local control = self._Control
    table.sort(dataList, function(a, b) 
        local isCurA = control:IsCurrentFashionId(a)
        local isCurB = control:IsCurrentFashionId(b)
        if isCurA ~= isCurB then
            return isCurA
        end
        
        local isUnlockA = control:IsFashionUnlock(a)
        local isUnlockB = control:IsFashionUnlock(b)
        if isUnlockA ~= isUnlockB then
            return isUnlockA
        end
        
        local pA = control:GetFashionPriority(a)
        local pB = control:GetFashionPriority(b)

        if pA ~= pB then
            return pA > pB
        end
        
        return a < b
    end)
    
    return dataList
end

function XUiSkyGardenDormCoating:SendChange3C(skinId)
    if not skinId or skinId <= 0 then
        return
    end
    local curSkinId = self._Control:GetFashionSkinId(self._SelectFashionId)
    if curSkinId == skinId then
        return
    end
    self:PlayAnimationWithMask("DarkEnable", function()
        XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_DORMITORY_CHANGE_SKIN, { Id = skinId })
        self:PlayAnimationWithMask("DarkDisable")
    end)
    
end