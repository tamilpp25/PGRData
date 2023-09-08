local XPanelTheatre3Energy = require("XUi/XUiTheatre3/Adventure/Main/XPanelTheatre3Energy")
local XGridTheatre3NodeSelect = require("XUi/XUiTheatre3/Adventure/Main/XGridTheatre3NodeSelect")
local XPanelTheatre3MainRoleInfo = require("XUi/XUiTheatre3/Adventure/Main/XPanelTheatre3MainRoleInfo")

---@class XUiTheatre3PlayMain : XLuaUi
---@field _Control XTheatre3Control
local XUiTheatre3PlayMain = XLuaUiManager.Register(XLuaUi, "UiTheatre3PlayMain")

function XUiTheatre3PlayMain:OnAwake()
    self:AddBtnListener()
end

function XUiTheatre3PlayMain:OnStart()
    self:InitUi()
end

function XUiTheatre3PlayMain:OnEnable()
    self:RefreshUi()
end

function XUiTheatre3PlayMain:OnDisable()

end

function XUiTheatre3PlayMain:OnDestroy()
    -- 因为XUiHelper.NewPanelActivityAsset有泄露，先这样
    XDataCenter.ItemManager.RemoveCountUpdateListener(self._PanelAsset)
end

function XUiTheatre3PlayMain:InitUi()
    self:InitPanelAsset()
    self:InitNodeSelect()
    self:InitRoleInfo()
    self:InitEnergyPanel()
end

function XUiTheatre3PlayMain:RefreshUi()
    local chapterDb = self._Control:GetAdventureCurChapterDb()
    self:RefreshChapterInfo(chapterDb)
    self:RefreshNodeSelect(chapterDb)
    self:RefreshEnergyPanel()
    self:RefreshRoleInfo()
    self:RefreshBtn()
end

--region Ui - PanelAsset
function XUiTheatre3PlayMain:InitPanelAsset()
    self._PanelAsset = XUiHelper.NewPanelActivityAssetSafe(
            {XEnumConst.THEATRE3.Theatre3InnerCoin,}, 
            self.PanelSpecialTool, self, 
            nil, 
            function()
                XLuaUiManager.Open("UiTheatre3Tips", XEnumConst.THEATRE3.Theatre3InnerCoin)
            end)
end
--endregion

--region Ui - ChapterInfo
---@param chapterDb XTheatre3Chapter
function XUiTheatre3PlayMain:RefreshChapterInfo(chapterDb)
    local chapterCfg = self._Control:GetChapterById(chapterDb:GetCurChapterId())
    self.TxtTitle.text = chapterCfg.ChapterName
    if self.TxtCurrent then
        self.TxtCurrent.gameObject:SetActiveEx(false)
    end
    if self.Bg and not string.IsNilOrEmpty(chapterCfg.PlayMainBg) then
        self.Bg:SetRawImage(chapterCfg.PlayMainBg)
    end
end
--endregion

--region Ui - RoleInfo
function XUiTheatre3PlayMain:InitRoleInfo()
    ---@type XPanelTheatre3MainRoleInfo[]
    self._GridRoleInfoList = {
        XPanelTheatre3MainRoleInfo.New(self.PanelCharacter1, self),
        XPanelTheatre3MainRoleInfo.New(self.PanelCharacter2, self),
        XPanelTheatre3MainRoleInfo.New(self.PanelCharacter3, self),
    }
end

function XUiTheatre3PlayMain:RefreshRoleInfo()
    local slotDataList = self._Control:GetAdventureSlotDataList()
    for i, data in ipairs(slotDataList) do
        local pos = data:GetPos()
        local equipSuitIdList = self._Control:GetSlotSuits(pos)
        if data:CheckIsHaveCharacter() or not XTool.IsTableEmpty(equipSuitIdList) then
            self._GridRoleInfoList[pos]:Refresh(pos, 1)
            self._GridRoleInfoList[pos]:Open()
        else
            self._GridRoleInfoList[pos]:Close()
        end
    end
end
--endregion

--region Ui - EnergyPanel
function XUiTheatre3PlayMain:InitEnergyPanel()
    ---@type XPanelTheatre3Energy
    self._PanelEnergy = XPanelTheatre3Energy.New(self.PanelEnergy, self)
end

function XUiTheatre3PlayMain:RefreshEnergyPanel()
    self._PanelEnergy:Refresh()
end
--endregion

--region Ui - NodeSelect
function XUiTheatre3PlayMain:InitNodeSelect()
    ---@type XGridTheatre3NodeSelect[]
    self._GridNodeSelectList = {
        XGridTheatre3NodeSelect.New(self.GridStage1, self),
        XGridTheatre3NodeSelect.New(self.GridStage2 or XUiHelper.Instantiate(self.GridStage1.gameObject, self.GridStage1.transform.parent), self),
        XGridTheatre3NodeSelect.New(self.GridStage3 or XUiHelper.Instantiate(self.GridStage1.gameObject, self.GridStage1.transform.parent), self),
    }
end

---@param chapterDb XTheatre3Chapter
function XUiTheatre3PlayMain:RefreshNodeSelect(chapterDb)
    local step = chapterDb:GetLastStep()
    local nodeData = step:GetNodeData()
    if not nodeData then
        return
    end
    local nodeSlotList = nodeData:GetNodeSlots()
    for i, nodeSlot in ipairs(nodeSlotList) do
        if self._GridNodeSelectList[i] then
            self._GridNodeSelectList[i]:Refresh(nodeData, nodeSlot)
            self._GridNodeSelectList[i]:Open()
        end
    end
    for i = #nodeSlotList + 1, #self._GridNodeSelectList do
        if self._GridNodeSelectList[i] then
            self._GridNodeSelectList[i]:Close()
        end
    end
end
--endregion

--region Ui - Btn
function XUiTheatre3PlayMain:RefreshBtn()
    --self.BtnProp:SetNameByGroup(0, XUiHelper.GetText("Theatre3AdventurePropBtnName", #self._Control:GetAdventureCurItemList()))
    self.BtnProp:SetNameByGroup(1, #self._Control:GetAdventureCurItemList())
end
--endregion

--region Ui - BtnListener
function XUiTheatre3PlayMain:AddBtnListener()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnRoleRoom, self.OnBtnRoleRoomClick)
    XUiHelper.RegisterClickEvent(self, self.PanelEnergy, self.OnBtnRoleRoomClick)
    XUiHelper.RegisterClickEvent(self, self.BtnProp, self.OnBtnItemClick)
end

function XUiTheatre3PlayMain:OnBtnBackClick()
    self:Close()
end

function XUiTheatre3PlayMain:OnBtnRoleRoomClick()
    self._Control:OpenAdventureRoleRoom()
end

function XUiTheatre3PlayMain:OnBtnItemClick()
    self._Control:OpenAdventureProp()
end
--endregion

return XUiTheatre3PlayMain