local XPanelTheatre3Energy = require("XUi/XUiTheatre3/Adventure/Main/XPanelTheatre3Energy")
local XGridTheatre3NodeSelect = require("XUi/XUiTheatre3/Adventure/Main/XGridTheatre3NodeSelect")
local XPanelTheatre3MainRoleInfo = require("XUi/XUiTheatre3/Adventure/Main/XPanelTheatre3MainRoleInfo")

---@class XUiTheatre3PlayMain : XLuaUi
---@field BtnQuantumLv XUiComponent.XUiButton
---@field _Control XTheatre3Control
local XUiTheatre3PlayMain = XLuaUiManager.Register(XLuaUi, "UiTheatre3PlayMain")

function XUiTheatre3PlayMain:OnAwake()
    self:AddBtnListener()
end

function XUiTheatre3PlayMain:OnStart(isSwitch)
    self._IsSwitch = isSwitch
    self:InitUi()
end

function XUiTheatre3PlayMain:OnEnable()
    self._Control:AdventurePlayCurChapterBgm()
    self:RefreshUi()
    self:AddEventListener()
end

function XUiTheatre3PlayMain:OnDisable()
    self:RemoveEventListener()
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
    self:InitQuantumPanel()
    self:InitBtnObj()
    self:InitEffect()
end

function XUiTheatre3PlayMain:RefreshUi()
    self:RefreshChapterInfo()
    self:RefreshNodeSelect()
    self:RefreshEnergyPanel()
    self:RefreshRoleInfo()
    self:RefreshBtn()
    self:RefreshQuantumPanel()
    self:RefreshSwitch()
end

--region Ui - PanelAsset
function XUiTheatre3PlayMain:InitPanelAsset()
    self._PanelAsset = XUiHelper.NewPanelActivityAssetSafe(
            {XEnumConst.THEATRE3.Theatre3InnerCoin,}, 
            self.PanelSpecialTool, self, 
            nil, 
            function()
                self._Control:OpenAdventureTips(XEnumConst.THEATRE3.Theatre3InnerCoin)
            end)
end
--endregion

--region Ui - ChapterInfo
function XUiTheatre3PlayMain:RefreshChapterInfo()
    local chapterId = self._Control:GetAdventureCurChapterId()
    local chapterCfg = self._Control:GetChapterById(chapterId)
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
    self._PanelEnergy:Refresh(self._Control:IsAdventureALine())
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

function XUiTheatre3PlayMain:RefreshNodeSelect()
    local step = self._Control:GetAdventureLastStep()
    local nodeData = step:GetCurNodeData(self._Control:GetAdventureCurChapterId())
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

--region Ui - QuantumPanel
function XUiTheatre3PlayMain:InitQuantumPanel()
    self.BtnQuantumLv.gameObject:SetActiveEx(false)
    self.BtnCloseQuantumDetail.gameObject:SetActiveEx(false)
    self.EffectBlue = XUiHelper.TryGetComponent(self.BtnQuantumLv.transform, "EffectBlue")
    self.EffectRed = XUiHelper.TryGetComponent(self.BtnQuantumLv.transform, "EffectRed")
    if self.EffectBlue then
        self.EffectBlue.gameObject:SetActiveEx(self._Control:IsAdventureALine())
        self.EffectRed.gameObject:SetActiveEx(not self._Control:IsAdventureALine())
    end
    ---@type XUiTheatre3PanelQuantum
    self._PanelQuantum = require("XUi/XUiTheatre3/Adventure/Quantum/XUiTheatre3PanelQuantum").New(self.BubbleQuantumDetail, self)
    self._PanelQuantum:Close()
    ---@type XUiTheatre3PanelQuantumData
    self._QuantumData = {}
end

function XUiTheatre3PlayMain:_UpdateQuantumData()
    self._QuantumData.AValue = self._Control:GetAdventureQuantumValue(true)
    self._QuantumData.BValue = self._Control:GetAdventureQuantumValue(false)
    self._QuantumData.QuantumLevelCfg = self._Control:GetCfgQuantumLevelByValue(self._QuantumData.AValue + self._QuantumData.BValue)
    self._QuantumData.QuantumEffectDescList = self._Control:GetCfgQuantumEffectListByValue(self._QuantumData.AValue, self._QuantumData.BValue)
    self._QuantumData.QuantumAShowPuzzleList = self._Control:GetCfgQuantumShowPuzzleListByValue(self._QuantumData.AValue, XEnumConst.THEATRE3.QuantumType.QuantumA)
    self._QuantumData.QuantumBShowPuzzleList = self._Control:GetCfgQuantumShowPuzzleListByValue(self._QuantumData.BValue, XEnumConst.THEATRE3.QuantumType.QuantumB)
end

function XUiTheatre3PlayMain:RefreshQuantumPanel()
    if not self._Control:CheckAdventureQuantumIsShow() then
        self.BtnQuantumLv.gameObject:SetActiveEx(false)
        return
    end
    self.BtnQuantumLv.gameObject:SetActiveEx(true)
    self:_UpdateQuantumData()
    self.BtnQuantumLv:SetNameByGroup(0, self._QuantumData.AValue)
    self.BtnQuantumLv:SetNameByGroup(1, self._QuantumData.BValue)
    if self._QuantumData.QuantumLevelCfg then
        self.BtnQuantumLv:SetNameByGroup(2, self._QuantumData.QuantumLevelCfg.Title)
        --全屏特效
        if self.Effect and not string.IsNilOrEmpty(self._QuantumData.QuantumLevelCfg.ScreenEffectUrl) then
            local screenEffectUrl = self._Control:GetClientConfig(self._QuantumData.QuantumLevelCfg.ScreenEffectUrl, self._Control:IsAdventureALine() and 1 or 2)
            self.Effect:LoadUiEffect(screenEffectUrl)
        end
    end
    local aValue = self._QuantumData.AValue
    local aLvValue = 0
    for _, levelId in ipairs(self._QuantumData.QuantumAShowPuzzleList) do
        if levelId <= self.BtnQuantumLv.ImageList.Count then
            local value = self._Control:GetCfgQuantumLevelValue(levelId)
            self.BtnQuantumLv.ImageList[levelId-1].fillAmount = math.min(aValue / (value - aLvValue) , 1)
            aValue = math.max(self._QuantumData.BValue - value, 0)
            aLvValue = value
        end
    end
    local bValue = self._QuantumData.BValue
    local bLvValue = 0
    for _, levelId in ipairs(self._QuantumData.QuantumBShowPuzzleList) do
        if levelId <= self.BtnQuantumLv.ImageList.Count then
            local value = self._Control:GetCfgQuantumLevelValue(levelId)
            self.BtnQuantumLv.ImageList[levelId-1].fillAmount = math.min(bValue / (value - bLvValue) , 1)
            bValue = math.max(self._QuantumData.BValue - value, 0)
            bLvValue = value
        end
    end
    self._PanelQuantum:UpdateData(self._QuantumData)
end

function XUiTheatre3PlayMain:UpdateQuantum(isChangeA, isChangeB, isLevelUp)
    self:RefreshQuantumPanel()
    self._Control:SetCacheQuantumValueData(isChangeA, isChangeB, isLevelUp)
    self._Control:CheckAdventureQuantumValueChange()
end

function XUiTheatre3PlayMain:ChangeChapter()
    self._Control:OpenAdventurePlayMain(true, true)
end
--endregion

--region Ui - Btn
function XUiTheatre3PlayMain:InitBtnObj()
    local XGridTheatre3SwitchLineNode = require("XUi/XUiTheatre3/Adventure/Main/XGridTheatre3SwitchLineNode")
    local switchChapterPanel = {}
    XTool.InitUiObjectByUi(switchChapterPanel, self.BtnSwitchChapter.transform)
    self:_SetBtnSwitchChapterActive(true)
    ---@type XGridTheatre3SwitchLineNode[]
    self.SwitchChapterPanelList = {
        XGridTheatre3SwitchLineNode.New(switchChapterPanel.PanelStage1, self),
        XGridTheatre3SwitchLineNode.New(switchChapterPanel.PanelStage2, self),
        XGridTheatre3SwitchLineNode.New(switchChapterPanel.PanelStage3, self),
    }
end

function XUiTheatre3PlayMain:RefreshBtn()
    self.BtnProp:SetNameByGroup(1, self._Control:GetAdventureCurItemCount())
    self:_SetBtnSwitchChapterActive(self._Control:CheckAdventureSwitchChapterIdIsShow())
end

function XUiTheatre3PlayMain:_SetBtnSwitchChapterActive(active)
    if not XTool.IsTableEmpty(self.SwitchChapterPanelList) then
        if active then
            local step = self._Control:GetAdventureLastStep()
            local nodeData = step:GetCurOtherNodeData(self._Control:GetAdventureCurChapterId())
            if not nodeData then
                return
            end
            local nodeSlotList = nodeData:GetNodeSlots()
            for i, nodeSlot in ipairs(nodeSlotList) do
                if self.SwitchChapterPanelList[i] then
                    self.SwitchChapterPanelList[i]:Refresh(nodeData, nodeSlot)
                    self.SwitchChapterPanelList[i]:Open()
                end
            end
            for i = #nodeSlotList + 1, #self.SwitchChapterPanelList do
                if self.SwitchChapterPanelList[i] then
                    self.SwitchChapterPanelList[i]:Close()
                end
            end
        else
            for _, grid in ipairs(self.SwitchChapterPanelList) do
                grid:Close()
            end
        end
    end
    self.BtnSwitchChapter.gameObject:SetActiveEx(active)
    self.BtnSwitchChapter:ShowReddot(false)
end
--endregion

--region Ui - Effect
function XUiTheatre3PlayMain:InitEffect()
    ---@type UnityEngine.Transform
    self._SwitchEffect = XUiHelper.TryGetComponent(self.Transform, 
            self._Control:IsAdventureALine() and "FullScreenBackground/EffectRed" or "FullScreenBackground/EffectBlue")
end

function XUiTheatre3PlayMain:RefreshSwitch()
    if self._IsSwitch and self._SwitchEffect then
        self._SwitchEffect.gameObject:SetActiveEx(true)
        self._IsSwitch = false
    else
        self._SwitchEffect.gameObject:SetActiveEx(false)
    end
end
--endregion

--region Ui - BtnListener
function XUiTheatre3PlayMain:AddBtnListener()
    self._Control:RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    self._Control:RegisterClickEvent(self, self.BtnRoleRoom, self.OnBtnRoleRoomClick)
    self._Control:RegisterClickEvent(self, self.PanelEnergy, self.OnBtnRoleRoomClick)
    self._Control:RegisterClickEvent(self, self.BtnProp, self.OnBtnItemClick)
    self._Control:RegisterClickEvent(self, self.BtnSwitchChapter, self.OnBtnSwitchChapterClick)
    self._Control:RegisterClickEvent(self, self.BtnQuantumLv, self.OnBtnQuantumLvClick)
    self._Control:RegisterClickEvent(self, self.BtnCloseQuantumDetail, self.OnBtnCloseQuantumDetailClick)
end

function XUiTheatre3PlayMain:OnBtnBackClick()
    self:Close()
end

function XUiTheatre3PlayMain:OnBtnRoleRoomClick()
    self._Control:OpenAdventureRoleRoom(false)
end

function XUiTheatre3PlayMain:OnBtnItemClick()
    self._Control:OpenAdventureProp()
end

function XUiTheatre3PlayMain:OnBtnSwitchChapterClick()
    self._Control:RequestSwitchParallelChapter(self._Control:GetAdventureOtherChapterId())
end

function XUiTheatre3PlayMain:OnBtnQuantumLvClick()
    self.BtnCloseQuantumDetail.gameObject:SetActiveEx(true)
    self._PanelQuantum:Open()
end

function XUiTheatre3PlayMain:OnBtnCloseQuantumDetailClick()
    self.BtnCloseQuantumDetail.gameObject:SetActiveEx(false)
    self._PanelQuantum:Close()
end
--endregion

--region Event
function XUiTheatre3PlayMain:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_THEATRE3_CHAPTER_CHANGE, self.ChangeChapter, self)
    XEventManager.AddEventListener(XEventId.EVENT_THEATRE3_QUANTUM_VALUE_UPDATE, self.UpdateQuantum, self)
end

function XUiTheatre3PlayMain:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_THEATRE3_CHAPTER_CHANGE, self.ChangeChapter, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_THEATRE3_QUANTUM_VALUE_UPDATE, self.UpdateQuantum, self)
end
--endregion

return XUiTheatre3PlayMain