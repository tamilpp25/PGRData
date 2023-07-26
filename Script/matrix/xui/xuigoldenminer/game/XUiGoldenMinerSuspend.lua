local XUiDisplayTitleGrid = require("XUi/XUiGoldenMiner/Grid/XUiDisplayTitleGrid")
local XUiDisplayGrid = require("XUi/XUiGoldenMiner/Grid/XUiDisplayGrid")

---@class XUiGoldenMinerSuspend : XLuaUi
local XUiGoldenMinerSuspend = XLuaUiManager.Register(XLuaUi, "UiGoldenMinerSuspend")

function XUiGoldenMinerSuspend:OnAwake()
    self:AddBtnClickListener()
end

---@param displayData XGoldenMinerDisplayData
function XUiGoldenMinerSuspend:OnStart(displayData, closeCallback, sureCallback)
    self._DisplayData = displayData
    self._CloseCallback = closeCallback
    self._SureCallback = sureCallback

    self:UpdateShip()
    self:UpdateItem()
    self:UpdateBuff()
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
    local buffList, characterDisplayData = self._DisplayData:GetDisplayShipList()
    self:_CreateTitleObj(XGoldenMinerConfigs.BuffDisplayType.Ship)
    self:_CreateDescObj(characterDisplayData.icon, characterDisplayData.desc)
    if not XTool.IsTableEmpty(buffList) then
        for _, buffId in ipairs(buffList) do
            self:_CreateDescObj(XGoldenMinerConfigs.GetBuffIcon(buffId), XGoldenMinerConfigs.GetBuffDesc(buffId))
        end
    end
end
--endregion

--region Ui - UpdateDisplayItem
function XUiGoldenMinerSuspend:UpdateItem()
    local buffList = self._DisplayData:GetDisplayItemList()
    if XTool.IsTableEmpty(buffList) then
        return
    end
    self:_CreateTitleObj(XGoldenMinerConfigs.BuffDisplayType.Item)
    for _, buff in ipairs(buffList) do
        --self:_CreateDescObj(XGoldenMinerConfigs.GetBuffIcon(buffId), XGoldenMinerConfigs.GetBuffDesc(buffId))
        self:_CreateDescObj(buff.icon, buff.desc)
    end
end
--endregion

--region Ui - UpdateDisplayBuff
function XUiGoldenMinerSuspend:UpdateBuff()
    local buffList = self._DisplayData:GetDisplayBuffList()
    if XTool.IsTableEmpty(buffList) then
        return
    end
    self:_CreateTitleObj(XGoldenMinerConfigs.BuffDisplayType.Buff)
    for _, buffId in ipairs(buffList) do
        self:_CreateDescObj(XGoldenMinerConfigs.GetBuffIcon(buffId), XGoldenMinerConfigs.GetBuffDesc(buffId))
    end
end
--endregion

--region Ui - CreateUiObj
function XUiGoldenMinerSuspend:_CreateTitleObj(type)
    XUiDisplayTitleGrid.New(XUiHelper.Instantiate(self.PanelResources.gameObject, self.PanelResources.transform.parent),
            XGoldenMinerConfigs.GetTxtDisplayMainTitle(type),
            XGoldenMinerConfigs.GetTxtDisplaySecondTitle(type))
end

function XUiGoldenMinerSuspend:_CreateDescObj(icon, desc)
    local grid = XUiDisplayGrid.New(XUiHelper.Instantiate(self.NewsListBg.gameObject, self.NewsListBg.transform.parent))
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