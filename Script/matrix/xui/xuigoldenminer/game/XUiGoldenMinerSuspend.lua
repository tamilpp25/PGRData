local XUiGoldenMinerDisplayTitleGrid = require("XUi/XUiGoldenMiner/Grid/XUiGoldenMinerDisplayTitleGrid")
local XUiGoldenMinerDisplayGrid = require("XUi/XUiGoldenMiner/Grid/XUiGoldenMinerDisplayGrid")

---@class XUiGoldenMinerSuspend : XLuaUi
---@field _Control XGoldenMinerControl
local XUiGoldenMinerSuspend = XLuaUiManager.Register(XLuaUi, "UiGoldenMinerSuspend")

function XUiGoldenMinerSuspend:OnAwake()
    self:AddBtnClickListener()
end

function XUiGoldenMinerSuspend:OnStart(closeCallback, sureCallback, isOnHex)
    self._CloseCallback = closeCallback
    self._SureCallback = sureCallback

    self:UpdateShip()
    self:UpdateItem()
    self:UpdateBuff()
    if isOnHex then
        self.BtnEnter.gameObject:SetActiveEx(false)
        self.BtnExit.gameObject:SetActiveEx(false)
        if self.TxtReport then
            self.TxtReport.text = XUiHelper.GetText("GoldenMinerShipDetailTitle")
        end
    end
    self.PanelResources.gameObject:SetActiveEx(false)
    self.NewsListBg.gameObject:SetActiveEx(false)
end

function XUiGoldenMinerSuspend:OnEnable()
    XDataCenter.InputManagerPc.SetCurOperationType(CS.XOperationType.System)
end

function XUiGoldenMinerSuspend:OnDisable()
    XDataCenter.InputManagerPc.ResumeCurOperationType()
end

--region Ui - UpdateDisplayShip
function XUiGoldenMinerSuspend:UpdateShip()
    local buffList, characterDisplayData = self._Control:GetDisplayShipList()
    self:_CreateTitleObj(XEnumConst.GOLDEN_MINER.BUFF_DISPLAY_TYPE.SHIP)
    self:_CreateDescObj(characterDisplayData.Icon, characterDisplayData.Desc)
    if not XTool.IsTableEmpty(buffList) then
        for _, buffId in ipairs(buffList) do
            self:_CreateDescObj(self._Control:GetCfgBuffIcon(buffId), self._Control:GetCfgBuffDesc(buffId))
        end
    end
end
--endregion

--region Ui - UpdateDisplayItem
function XUiGoldenMinerSuspend:UpdateItem()
    local buffList = self._Control:GetDisplayItemList()
    if XTool.IsTableEmpty(buffList) then
        return
    end
    self:_CreateTitleObj(XEnumConst.GOLDEN_MINER.BUFF_DISPLAY_TYPE.ITEM)
    for _, buff in ipairs(buffList) do
        self:_CreateDescObj(buff.Icon, buff.Desc)
    end
end
--endregion

--region Ui - UpdateDisplayBuff
function XUiGoldenMinerSuspend:UpdateBuff()
    local buffList = self._Control:GetDisplayBuffList()
    if XTool.IsTableEmpty(buffList) then
        return
    end
    self:_CreateTitleObj(XEnumConst.GOLDEN_MINER.BUFF_DISPLAY_TYPE.BUFF)
    for _, buffId in ipairs(buffList) do
        self:_CreateDescObj(self._Control:GetCfgBuffIcon(buffId), self._Control:GetCfgBuffDesc(buffId))
    end
end
--endregion

--region Ui - CreateUiObj
function XUiGoldenMinerSuspend:_CreateTitleObj(type)
    XUiGoldenMinerDisplayTitleGrid.New(XUiHelper.Instantiate(self.PanelResources.gameObject, self.PanelResources.transform.parent),
            self,
            self._Control:GetClientTxtDisplayMainTitle(type),
            self._Control:GetClientTxtDisplaySecondTitle(type))
end

function XUiGoldenMinerSuspend:_CreateDescObj(icon, desc)
    if string.IsNilOrEmpty(icon) then
        return
    end
    local grid = XUiGoldenMinerDisplayGrid.New(XUiHelper.Instantiate(self.NewsListBg.gameObject, self.NewsListBg.transform.parent), self)
    grid:Refresh(icon, desc)
end
--endregion

--region Ui - BtnListener
function XUiGoldenMinerSuspend:AddBtnClickListener()
    self:RegisterClickEvent(self.BtnExit, self.OnBtnExitClick)
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnEnter, self.OnBtnCloseClick)
end

function XUiGoldenMinerSuspend:OnBtnCloseClick()
    self:Close()
    if self._CloseCallback then
        self._CloseCallback()
    end

    self._CloseCallback = nil
    self._SureCallback = nil
end

function XUiGoldenMinerSuspend:OnBtnExitClick()
    self:Close()
    if self._SureCallback then
        self._SureCallback()
    end

    self._CloseCallback = nil
    self._SureCallback = nil
end
--endregion