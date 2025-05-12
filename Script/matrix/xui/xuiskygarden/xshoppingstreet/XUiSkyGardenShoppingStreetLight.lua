---@class XUiSkyGardenShoppingStreetLight : XLuaUi
---@field PanelTop UnityEngine.RectTransform
---@field BtnBack XUiComponent.XUiButton
---@field BtnSave XUiComponent.XUiButton
---@field ListTask UnityEngine.RectTransform
---@field GridTask UnityEngine.RectTransform
local XUiSkyGardenShoppingStreetLight = XMVCA.XBigWorldUI:Register(nil, "UiSkyGardenShoppingStreetLight")
local XUiSkyGardenShoppingStreetAsset = require("XUi/XUiSkyGarden/XShoppingStreet/Component/XUiSkyGardenShoppingStreetAsset")
local XUiSkyGardenShoppingStreetBillboardGrid = require("XUi/XUiSkyGarden/XShoppingStreet/Grid/XUiSkyGardenShoppingStreetBillboardGrid")

--region 生命周期
function XUiSkyGardenShoppingStreetLight:OnAwake()
    ---@type XUiSkyGardenShoppingStreetAsset
    self.PanelTopUi = XUiSkyGardenShoppingStreetAsset.New(self.PanelTop, self)
    self:_RegisterButtonClicks()
end

function XUiSkyGardenShoppingStreetLight:OnStart(...)
    self._Control:X3CSetVirtualCameraByCameraIndex(3)
    local hasLimitTask = self._Control:HasStageLimitTask()
    if not hasLimitTask then
        local selectIndex = self._Control:GetStageBillboardsSelectedId()
        if selectIndex > 0 then
            self._BillboradIdsList = { selectIndex }
        end
        self.BtnSave.gameObject:SetActive(false)
        if not self._BillboradIdsList then
            self:Close()
            return
        end
    else
        self._BillboradIdsList = self._Control:GetStageBillboards()
    end

    local leftTurnNum = self._Control:GetBillboardLeftTurn()
    self.TxtNum.text = XMVCA.XBigWorldService:GetText("SG_SS_BillboardTurnLeft", leftTurnNum)
    self._BillboradIdsUI = {}
    XTool.UpdateDynamicItem(self._BillboradIdsUI, self._BillboradIdsList, self.GridTask, XUiSkyGardenShoppingStreetBillboardGrid, self)

    if self._BillboradIdsList and #self._BillboradIdsList > 0 then
        self:OnSelectClick(1)
    end
end

function XUiSkyGardenShoppingStreetLight:OnEnable()
    self._Control:X3CSetStageStatus(XMVCA.XSkyGardenShoppingStreet.X3CStageStatus.Normal)
end

function XUiSkyGardenShoppingStreetLight:OnDisable()
    self._Control:X3CSetStageStatus(XMVCA.XSkyGardenShoppingStreet.X3CStageStatus.Edit)
end
--endregion

function XUiSkyGardenShoppingStreetLight:OnSelectClick(selectIndex)
    local cell = self._BillboradIdsUI[self.SelectIndex]
    if cell then
        cell:SetSelected(false)
    end

    self.SelectIndex = selectIndex
    self._BillboradIdsUI[self.SelectIndex]:SetSelected(true)

    local lightId = 0
    local billboardId = self._BillboradIdsList[self.SelectIndex]
    if billboardId > 0 then
        local billboardCfg = XMVCA.XSkyGardenShoppingStreet:GetBillboardConfigById(billboardId)
        lightId = billboardCfg.EffectId
    end
    XMVCA.XSkyGardenShoppingStreet:X3CLightChange(lightId)
end

--region 按钮事件
function XUiSkyGardenShoppingStreetLight:OnBtnBackClick()
    local lightId = 0
    local billboardId = self._Control:GetStageBillboardsSelectedId()
    if billboardId > 0 then
        local billboardCfg = XMVCA.XSkyGardenShoppingStreet:GetBillboardConfigById(billboardId)
        lightId = billboardCfg.EffectId
    end
    XMVCA.XSkyGardenShoppingStreet:X3CLightChange(lightId)
    self:Close()
end

function XUiSkyGardenShoppingStreetLight:OnBtnSaveClick()
    self._Control:SelectBillboardsById(self._BillboradIdsList[self.SelectIndex], function ()
        self:Close()
    end)
end

--endregion

--region 私有方法
function XUiSkyGardenShoppingStreetLight:_RegisterButtonClicks()
    --在此处注册按钮事件
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnSave.CallBack = function() self:OnBtnSaveClick() end
end
--endregion

return XUiSkyGardenShoppingStreetLight
