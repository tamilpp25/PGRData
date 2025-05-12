---@class XUiSkyGardenDormPresuppose : XBigWorldUi
---@field _Control XSkyGardenDormControl
---@field _GridItems table<number, XUiGridSGPresuppose>
local XUiSkyGardenDormPresuppose = XMVCA.XBigWorldUI:Register(nil, "UiSkyGardenDormPresuppose")

local XUiGridSGPresuppose = require("XUi/XUiSkyGarden/XDorm/Grid/XUiGridSGPresuppose")

function XUiSkyGardenDormPresuppose:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiSkyGardenDormPresuppose:OnStart(areaType)
    self._AreaType = areaType
    self._CurPresupposeId = self._Control:GetLayoutIdByAreaType(areaType)
    self._SelectPresupposeId = self._CurPresupposeId
    self:InitView()
end

function XUiSkyGardenDormPresuppose:InitUi()
    self._GridItems = {}
    self.BtnConfirm.gameObject:SetActiveEx(false)
    self.CoatingItem.gameObject:SetActiveEx(false)
end

function XUiSkyGardenDormPresuppose:InitCb()
    self.BtnTanchuangClose.CallBack = function() 
        self:Close()
    end
    
    --self.BtnConfirm.CallBack = function() 
    --    self:OnBtnConfirmClick()
    --end
end

function XUiSkyGardenDormPresuppose:InitView()
    self._DataList = self._Control:GetDormLayoutIdList(self._AreaType)
    
    self:RefreshPresuppose()
end

function XUiSkyGardenDormPresuppose:RefreshPresuppose()
    for i, presupposeId in pairs(self._DataList) do
        local grid = self._GridItems[i]
        if not grid then
            local ui = --[[i == 1 and self.CoatingItem or]] XUiHelper.Instantiate(self.CoatingItem, self.CoatingList.transform)
            grid = XUiGridSGPresuppose.New(ui, self)
            self._GridItems[i] = grid
        end
        grid:Refresh(presupposeId, self._AreaType, presupposeId == self._SelectPresupposeId)
    end

    for i = #self._DataList + 1, #self._GridItems do
        local grid = self._GridItems[i]
        grid:Close()
    end
end

function XUiSkyGardenDormPresuppose:OnSelectPresuppose(presupposeId)
    self._SelectPresupposeId = presupposeId
    --self.BtnConfirm.gameObject:SetActiveEx(self._CurPresupposeId ~= presupposeId)
    self:RefreshPresuppose()
    if presupposeId ~= self._CurPresupposeId then
        self:OnBtnConfirmClick()
    end
end

function XUiSkyGardenDormPresuppose:DoSelectCurrent()
    for _, grid in pairs(self._GridItems) do
        if grid:GetId() == self._CurPresupposeId then
            grid:OnBtnClick()
        end
    end
end

function XUiSkyGardenDormPresuppose:OnBtnConfirmClick()
    ---@type XSgContainerFurnitureData 当前区域的摆放的家具
    local containerData = self._Control:CloneContainerFurnitureData(self._AreaType)
    ---@type XSgContainerFurnitureData 服务器记录的区域摆放的家具
    local layoutContainerData = self._Control:GetContainerFurnitureData(self._AreaType)
    local equal = containerData:Equal(layoutContainerData)
    
    local content = XUiHelper.ReplaceTextNewLine(self._Control:GetSwitchNewLayoutText(equal))
    local data = XMVCA.XBigWorldCommon:GetPopupConfirmData()
    
    data:InitInfo(nil, content):InitToggleActive(false)
    local sureCb, cancelCb
    if equal then
        --确定：切换到新的预设
        sureCb = function()
            self._Control:RequestSaveAndApplyLayout(self._AreaType, 0, self._SelectPresupposeId, nil, function()
                XUiManager.TipMsg(self._Control:GetLayoutChangeText(2))
                self:Close()
            end)
        end
        --取消：选中当前
        cancelCb = function()
            self:DoSelectCurrent()
        end
    else
        --确定：保存并切换到新的预设
        sureCb = function()
            self._Control:RequestSaveAndApplyLayout(self._AreaType, self._CurPresupposeId, self._SelectPresupposeId, { containerData }, function(value)
                XUiManager.TipMsg(self._Control:GetLayoutChangeText(1))
                self:Close()
            end)
        end
        --取消：不保存切换到新的预设
        --取消：选中当前
        cancelCb = function()
            self:DoSelectCurrent()
        end
        --data:InitCancelClick(nil, function()
        --    self._Control:RequestSaveAndApplyLayout(self._AreaType, 0, self._SelectPresupposeId, nil, function(value)
        --        XUiManager.TipMsg(self._Control:GetLayoutChangeText(2))
        --        self:Close()
        --    end)
        --end)
    end
    data:InitSureClick(nil, sureCb):InitCancelClick(nil, cancelCb):InitCloseClick(nil, cancelCb)
    XMVCA.XBigWorldUI:OpenConfirmPopup(data)
    
end