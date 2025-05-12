---@class XUiSkyGardenDormPhotoWall : XBigWorldUi
---@field _Control XSkyGardenDormControl
---@field _PanelWall XUiPanelSGWall
---@field _PanelNumber XUiPanelSGNumber
local XUiSkyGardenDormPhotoWall = XMVCA.XBigWorldUI:Register(nil, "UiSkyGardenDormPhotoWall")

local SgDormAreaType = XMVCA.XSkyGardenDorm.XSgDormAreaType
local DlcEventId = XMVCA.XBigWorldService.DlcEventId

function XUiSkyGardenDormPhotoWall:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiSkyGardenDormPhotoWall:OnStart(areaType)
    self._AreaType = areaType
    self:InitView()

    XEventManager.AddEventListener(DlcEventId.EVENT_DORM_LAYOUT_REFRESH, self.OnRefreshLayout, self)
    XEventManager.AddEventListener(DlcEventId.EVENT_DORM_APPLY_NEW_LAYOUT, self.OnApplyNewLayout, self)
end

function XUiSkyGardenDormPhotoWall:OnDestroy()
    XEventManager.RemoveEventListener(DlcEventId.EVENT_DORM_LAYOUT_REFRESH, self.OnRefreshLayout, self)
    XEventManager.RemoveEventListener(DlcEventId.EVENT_DORM_APPLY_NEW_LAYOUT, self.OnApplyNewLayout, self)
    
    local name = self._AreaType == SgDormAreaType.Wall and "UiSkyGardenDormCameraPhotoWall" or "UiSkyGardenDormCameraFrame"
    XMVCA.XBigWorldGamePlay:DeactivateVCamera(name, false)
    
    self._Control:ClearContainerDataList(self._AreaType)

    local manager = XMVCA.XSkyGardenDorm:GetManager()
    if manager then
        manager:DisposeDynamicContainer()
        manager:DisposeStaticContainer()
    end

    XMVCA.XBigWorldGamePlay:SetCameraProjection(false)
    XMVCA.XBigWorldGamePlay:SetCurNpcAndAssistActive(true, false)
end

function XUiSkyGardenDormPhotoWall:OnEnable()
    self:UpdateView()
end

function XUiSkyGardenDormPhotoWall:InitUi()
    self._IsHide = false
end

function XUiSkyGardenDormPhotoWall:InitCb()
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    
    self.BtnDelete.CallBack = function() 
        self:OnBtnDeleteClick()
    end
    
    self.BtnReset.CallBack = function() 
        self:OnBtnResetClick()
    end
    
    self.BtnSave.CallBack = function() 
        self:OnBtnSaveClick()
    end
    
    self.BtnHideClose.CallBack = function() 
        self:OnBtnHideClick()
    end
    
    self.BtnHideOpen.CallBack = function() 
        self:OnBtnHideClick()
    end
    
    self.BtnPresuppose.CallBack = function() 
        self:OnBtnPresupposeClick()
    end
end

function XUiSkyGardenDormPhotoWall:InitView()
    local isPhotoWall = self._AreaType == SgDormAreaType.Wall
    local ui = isPhotoWall and self.PanelHomePhoto or self.PanelHomeFrame
    self.PanelHomePhoto.gameObject:SetActiveEx(isPhotoWall)
    self.PanelHomeFrame.gameObject:SetActiveEx(not isPhotoWall)
    self._PanelNumber = require("XUi/XUiSkyGarden/XDorm/Panel/XUiPanelSGNumber").New(self.PanelGridNumber, self, self._AreaType)
    local panelWall
    if isPhotoWall then
        panelWall = require("XUi/XUiSkyGarden/XDorm/Panel/XUiPanelSGPhotoWall").New(ui, self, self._AreaType)
    else
        panelWall = require("XUi/XUiSkyGarden/XDorm/Panel/XUiPanelSGGiftWall").New(ui, self, self._AreaType)
    end
    self._PanelWall = panelWall
    
    self:OnRefreshLayout()
    self._PanelWall:InitFurniture()
end

function XUiSkyGardenDormPhotoWall:UpdateView()
    self._PanelNumber:Refresh()
    self._PanelWall:Refresh()
end

function XUiSkyGardenDormPhotoWall:OnBtnBackClick()
    local currentData = self:GetContainerData(self._AreaType)
    local serverData = self._Control:GetContainerFurnitureData(self._AreaType)
    if currentData:Equal(serverData) then
        return self:Close()
    end
    local txt = self._Control:GetFurnitureChangedText()
    
    local data = XMVCA.XBigWorldCommon:GetPopupConfirmData()
    data:InitInfo(nil, txt)
    local layoutId = self._Control:GetLayoutIdByAreaType(self._AreaType)
    data:InitToggleActive(false):InitSureClick(nil, function() 
        self._Control:RequestSaveAndApplyLayout(self._AreaType, layoutId, 0, { currentData }, function() 
            self:Close()
        end)
    end)
    data:InitCancelClick(nil, function() 
        self._Control:RevertDecoration(self._AreaType, currentData, serverData)
        self:Close()
    end)
    
    XMVCA.XBigWorldUI:OpenConfirmPopup(data)
end

function XUiSkyGardenDormPhotoWall:OnBtnDeleteClick()
    local data = XMVCA.XBigWorldCommon:GetPopupConfirmData()
    local content = self._Control:GetOperateText(1)
    data:InitInfo(nil, content):InitToggleActive(false):InitSureClick(nil, function()
        self._PanelWall:ClearDecoration()
        self:UpdateView()
    end)
    XMVCA.XBigWorldUI:OpenConfirmPopup(data)
end
 
function XUiSkyGardenDormPhotoWall:OnBtnResetClick()
    local data = XMVCA.XBigWorldCommon:GetPopupConfirmData()
    local content = self._Control:GetOperateText(2)
    data:InitInfo(nil, content):InitToggleActive(false):InitSureClick(nil, function()
        self._PanelWall:RevertDecoration()
        self:UpdateView()
    end)
    XMVCA.XBigWorldUI:OpenConfirmPopup(data)
end

function XUiSkyGardenDormPhotoWall:OnBtnSaveClick()
    if not self._PanelWall:TryCheckOpIsSafe(true) then
        return
    end
    local layoutId = self._Control:GetLayoutIdByAreaType(self._AreaType)
    local data = self:GetContainerData()
    self._Control:RequestSaveAndApplyLayout(self._AreaType, layoutId, 0, { data }, function()
        XUiManager.TipMsg(self._Control:GetLayoutChangeText(1))
    end)
end

function XUiSkyGardenDormPhotoWall:OnBtnHideClick()
    if not self._PanelWall:TryCheckOpIsSafe(true) then
        return
    end
    self._IsHide = not self._IsHide
    self.BtnHideClose.gameObject:SetActiveEx(self._IsHide)
    self.BtnHideOpen.gameObject:SetActiveEx(not self._IsHide)
    self._PanelWall:SetVisible(not self._IsHide)
    if self._IsHide then
        self:PlayAnimationWithMask("UiDisable", function() 
            self:SetMultiObjActiveEx(false)
            self._PanelNumber:Close()
        end)
    else
        self:SetMultiObjActiveEx(true)
        self._PanelNumber:Open()
        self:PlayAnimationWithMask("UiEnable")
    end
end

function XUiSkyGardenDormPhotoWall:EnterEditMode()
    self.BtnPresuppose.gameObject:SetActiveEx(false)
    self.BtnBack.transform.parent.gameObject:SetActiveEx(false)
    self.BtnSave.gameObject:SetActiveEx(false)
    self.BtnHideClose.gameObject:SetActiveEx(false)
    self.BtnHideOpen.gameObject:SetActiveEx(false)
end

function XUiSkyGardenDormPhotoWall:ExitEditMode()
    self.BtnPresuppose.gameObject:SetActiveEx(true)
    self.BtnBack.transform.parent.gameObject:SetActiveEx(true)
    self.BtnSave.gameObject:SetActiveEx(true)
    self.BtnHideClose.gameObject:SetActiveEx(self._IsHide)
    self.BtnHideOpen.gameObject:SetActiveEx(not self._IsHide)
end

function XUiSkyGardenDormPhotoWall:SetMultiObjActiveEx(value)
    if value then
        self.BtnDelete.gameObject:SetActiveEx(true)
        self.BtnReset.gameObject:SetActiveEx(true)
        self.BtnSave.gameObject:SetActiveEx(true)
        self.BtnPresuppose.gameObject:SetActiveEx(true)
        self.BtnBack.transform.parent.gameObject:SetActiveEx(true)
    else
        self.BtnDelete.gameObject:SetActiveEx(false)
        self.BtnReset.gameObject:SetActiveEx(false)
        self.BtnSave.gameObject:SetActiveEx(false)
        self.BtnPresuppose.gameObject:SetActiveEx(false)
        self.BtnBack.transform.parent.gameObject:SetActiveEx(false)
    end
end

function XUiSkyGardenDormPhotoWall:OnBtnPresupposeClick()
    XMVCA.XBigWorldUI:Open("UiSkyGardenDormPresuppose", self._AreaType)
end

---@return XSgContainerFurnitureData
function XUiSkyGardenDormPhotoWall:GetContainerData()
    return self._Control:CloneContainerFurnitureData(self._AreaType)
end

function XUiSkyGardenDormPhotoWall:OnRefreshLayout()
    local layoutId = self._Control:GetLayoutIdByAreaType(self._AreaType)
    self.BtnPresuppose:SetNameByGroup(0, self._Control:GetDormLayoutName(layoutId))
end

function XUiSkyGardenDormPhotoWall:OnApplyNewLayout()
    self:PlayAnimationWithMask("DarkEnable", function()
        self._PanelWall:ApplyNewLayout()
        self:UpdateView()
        self:PlayAnimationWithMask("DarkDisable")
    end)
    
end

function XUiSkyGardenDormPhotoWall:CheckIsFull(majorType)
    return self._PanelNumber:IsFull(majorType)
end