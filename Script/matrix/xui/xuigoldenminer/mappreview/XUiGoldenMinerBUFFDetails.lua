local XUiDisplayTitleGrid = require("XUi/XUiGoldenMiner/Grid/XUiDisplayTitleGrid")
local XUiDisplayGrid = require("XUi/XUiGoldenMiner/Grid/XUiDisplayGrid")

---黄金矿工地图预览
---@class UiGoldenMinerBUFFDetails : XLuaUi
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
    local previewUrl = XGoldenMinerConfigs.GetMapPreviewPic(self._MapId)
    if not string.IsNilOrEmpty(previewUrl) then
        self.RImgNextLevel:SetRawImage(previewUrl)
    end
end
---endregion

---region Ui - Display
function UiGoldenMinerBUFFDetails:UpdateDisplay()
    local db = XDataCenter.GoldenMinerManager.GetGoldenMinerDataDb()
    local data = db:GetDisplayData()
    self:_UpdateDisplayShip(data)
    self:_UpdateDisplayItem(data)
    self:_UpdateDisplayBuff(data)
    self.PanelResources.gameObject:SetActiveEx(false)
    self.NewsListBg.gameObject:SetActiveEx(false)
end

---@param data XGoldenMinerDisplayData
function UiGoldenMinerBUFFDetails:_UpdateDisplayShip(data)
    local buffList, characterDisplayData = data:GetDisplayShipList()
    self:_CreateTitleObj(XGoldenMinerConfigs.BuffDisplayType.Ship)
    self:_CreateDescObj(characterDisplayData.icon, characterDisplayData.desc)
    if not XTool.IsTableEmpty(buffList) then
        for _, buffId in ipairs(buffList) do
            self:_CreateDescObj(XGoldenMinerConfigs.GetBuffIcon(buffId), XGoldenMinerConfigs.GetBuffDesc(buffId))
        end
    end
end

---@param data XGoldenMinerDisplayData
function UiGoldenMinerBUFFDetails:_UpdateDisplayItem(data)
    local buffList = data:GetDisplayItemList()
    if XTool.IsTableEmpty(buffList) then
        return
    end
    self:_CreateTitleObj(XGoldenMinerConfigs.BuffDisplayType.Item)
    for _, buff in ipairs(buffList) do
        --self:_CreateDescObj(XGoldenMinerConfigs.GetBuffIcon(buffId), XGoldenMinerConfigs.GetBuffDesc(buffId))
        self:_CreateDescObj(buff.icon, buff.desc)
    end
end

---@param data XGoldenMinerDisplayData
function UiGoldenMinerBUFFDetails:_UpdateDisplayBuff(data)
    local buffList = data:GetDisplayBuffList()
    if XTool.IsTableEmpty(buffList) then
        return
    end
    self:_CreateTitleObj(XGoldenMinerConfigs.BuffDisplayType.Buff)
    for _, buffId in ipairs(buffList) do
        self:_CreateDescObj(XGoldenMinerConfigs.GetBuffIcon(buffId), XGoldenMinerConfigs.GetBuffDesc(buffId))
    end
end

function UiGoldenMinerBUFFDetails:_CreateTitleObj(type)
    XUiDisplayTitleGrid.New(XUiHelper.Instantiate(self.PanelResources.gameObject, self.PanelResources.transform.parent),
            XGoldenMinerConfigs.GetTxtDisplayMainTitle(type),
            XGoldenMinerConfigs.GetTxtDisplaySecondTitle(type))
end

function UiGoldenMinerBUFFDetails:_CreateDescObj(icon, desc)
    local grid = XUiDisplayGrid.New(XUiHelper.Instantiate(self.NewsListBg.gameObject, self.NewsListBg.transform.parent))
    grid:Refresh(icon, desc)
end
---endregion

---region Ui - BtnListener
function UiGoldenMinerBUFFDetails:AddBtnClickListener()
    self:RegisterClickEvent(self.BtnClose, self.Close)
    self:RegisterClickEvent(self.BtnTanchuangClose, self.Close)
end
---endregion