local XUiGoldenMinerDisplayTitleGrid = require("XUi/XUiGoldenMiner/Grid/XUiGoldenMinerDisplayTitleGrid")
local XUiGoldenMinerDisplayGrid = require("XUi/XUiGoldenMiner/Grid/XUiGoldenMinerDisplayGrid")

---黄金矿工地图预览
---@class UiGoldenMinerBUFFDetails : XLuaUi
---@field _Control XGoldenMinerControl
local UiGoldenMinerBUFFDetails = XLuaUiManager.Register(XLuaUi, "UiGoldenMinerBUFFDetails")

function UiGoldenMinerBUFFDetails:OnAwake()
    self:AddBtnClickListener()
end

function UiGoldenMinerBUFFDetails:OnStart(mapId)
    self._MapId = mapId
    self:UpdateMapPreview()
    self:UpdateDisplay()
end

---region Ui - MapPreview
function UiGoldenMinerBUFFDetails:UpdateMapPreview()
    local previewUrl = self._Control:GetCfgMapPreviewPic(self._MapId)
    if not string.IsNilOrEmpty(previewUrl) then
        self.RImgNextLevel:SetRawImage(previewUrl)
    end
end
---endregion

---region Ui - Display
function UiGoldenMinerBUFFDetails:UpdateDisplay()
    self:_UpdateDisplayShip()
    self:_UpdateDisplayItem()
    self:_UpdateDisplayBuff()
    self.PanelResources.gameObject:SetActiveEx(false)
    self.NewsListBg.gameObject:SetActiveEx(false)
end

function UiGoldenMinerBUFFDetails:_UpdateDisplayShip()
    local buffList, characterDisplayData = self._Control:GetDisplayShipList()
    self:_CreateTitleObj(XEnumConst.GOLDEN_MINER.BUFF_DISPLAY_TYPE.SHIP)
    self:_CreateDescObj(characterDisplayData.Icon, characterDisplayData.Desc)
    if not XTool.IsTableEmpty(buffList) then
        for _, buffId in ipairs(buffList) do
            self:_CreateDescObj(self._Control:GetCfgBuffIcon(buffId), self._Control:GetCfgBuffDesc(buffId))
        end
    end
end

function UiGoldenMinerBUFFDetails:_UpdateDisplayItem()
    local buffList = self._Control:GetDisplayItemList()
    if XTool.IsTableEmpty(buffList) then
        return
    end
    self:_CreateTitleObj(XEnumConst.GOLDEN_MINER.BUFF_DISPLAY_TYPE.ITEM)
    for _, buff in ipairs(buffList) do
        self:_CreateDescObj(buff.Icon, buff.Desc)
    end
end

function UiGoldenMinerBUFFDetails:_UpdateDisplayBuff()
    local buffList = self._Control:GetDisplayBuffList()
    if XTool.IsTableEmpty(buffList) then
        return
    end
    self:_CreateTitleObj(XEnumConst.GOLDEN_MINER.BUFF_DISPLAY_TYPE.BUFF)
    for _, buffId in ipairs(buffList) do
        self:_CreateDescObj(self._Control:GetCfgBuffIcon(buffId), self._Control:GetCfgBuffDesc(buffId))
    end
end

function UiGoldenMinerBUFFDetails:_CreateTitleObj(type)
    XUiGoldenMinerDisplayTitleGrid.New(XUiHelper.Instantiate(self.PanelResources.gameObject, self.PanelResources.transform.parent),
            self,
            self._Control:GetClientTxtDisplayMainTitle(type),
            self._Control:GetClientTxtDisplaySecondTitle(type))
end

function UiGoldenMinerBUFFDetails:_CreateDescObj(icon, desc)
    if string.IsNilOrEmpty(icon) then
        return
    end
    local grid = XUiGoldenMinerDisplayGrid.New(XUiHelper.Instantiate(self.NewsListBg.gameObject, self.NewsListBg.transform.parent), self)
    grid:Refresh(icon, desc)
end
---endregion

---region Ui - BtnListener
function UiGoldenMinerBUFFDetails:AddBtnClickListener()
    self:RegisterClickEvent(self.BtnClose, self.Close)
    self:RegisterClickEvent(self.BtnTanchuangClose, self.Close)
end
---endregion