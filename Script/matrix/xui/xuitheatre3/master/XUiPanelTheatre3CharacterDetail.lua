local XUiGridTheatre3CharacterLevel = require("XUi/XUiTheatre3/Master/XUiGridTheatre3CharacterLevel")
local XUiGridTheatre3CharacterEnding = require("XUi/XUiTheatre3/Master/XUiGridTheatre3CharacterEnding")

---@class XUiPanelTheatre3CharacterDetail : XUiNode
---@field _Control XTheatre3Control
local XUiPanelTheatre3CharacterDetail = XClass(XUiNode, "XUiPanelTheatre3CharacterDetail")

function XUiPanelTheatre3CharacterDetail:OnStart()
    self:InitLevelDynamic()
    self.PanelLvBuff.gameObject:SetActiveEx(false)
    self.BtnClose.gameObject:SetActiveEx(false)
    self.BubbleEnd.gameObject:SetActiveEx(false)
    ---@type XUiGridTheatre3CharacterEnding[]
    self.GridCharacterEndingList = {}
    self.EndingUiObjDir = XTool.InitUiObjectByUi({}, self.BtnEnd)
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick)
    XUiHelper.RegisterClickEvent(self, self.BtnEnd, self.OnBtnEndClick)
end

function XUiPanelTheatre3CharacterDetail:Refresh(characterId)
    self.CharacterId = characterId
    ---@type XCharacterAgency
    local characterAgency = XMVCA:GetAgency(ModuleId.XCharacter)
    -- 名字
    self.TxtName.text = characterAgency:GetCharacterName(characterId)
    self.TxtNameOther.text = characterAgency:GetCharacterTradeName(characterId)
    -- 等级
    local level = self._Control:GetCharacterLv(characterId)
    self.TxtLvNum.text = level
    -- 结局加成
    self:RefreshEnding()
    -- 当前经验和进度
    local isMaxLevel = self._Control:CheckCharacterMaxLevel(characterId, level)
    if isMaxLevel then
        self.TxtExp.text = self._Control:GetClientConfig("CharacterLevelMaxDesc", 1)
        self.ImgProgress.fillAmount = 1
    else
        local curExp = self._Control:GetCharacterExp(characterId)
        local upNeedExp = self._Control:GetCharacterLevelUpNeedExp(characterId, level + 1)
        self.TxtExp.text = string.format("%s/%s", curExp, upNeedExp)
        local progress = XTool.IsNumberValid(upNeedExp) and curExp / upNeedExp or 1
        self.ImgProgress.fillAmount = progress
    end
    -- 等级信息
    self:UpdateCharacterLevel()
end

function XUiPanelTheatre3CharacterDetail:RefreshEnding()
    local characterEndingIdList = self._Control:GetCharacterEndingIdList(self.CharacterId)
    for index, id in pairs(characterEndingIdList) do
        local endIconName = "Part" .. index
        if self.EndingUiObjDir[endIconName] then
            self.EndingUiObjDir[endIconName].gameObject:SetActiveEx(self._Control:CheckCharacterEnding(id))
        end
    end
    for i = #characterEndingIdList + 1, 5 do
        local endIconName = "Part" .. i
        if self.EndingUiObjDir[endIconName] then
            self.EndingUiObjDir[endIconName].gameObject:SetActiveEx(false)
        end
    end
end

function XUiPanelTheatre3CharacterDetail:OnBtnEndClick()
    self.BubbleEnd.gameObject:SetActiveEx(true)
    self.BtnClose.gameObject:SetActiveEx(true)
    -- 刷新结局列表
    local characterEndingIdList = self._Control:GetCharacterEndingIdList(self.CharacterId)
    for i = 1, 5 do
        local grid = self.GridCharacterEndingList[i]
        if not grid then
            grid = XUiGridTheatre3CharacterEnding.New(self["GridEnd" .. i], self)
            self.GridCharacterEndingList[i] = grid
        end
        if characterEndingIdList[i] then
            grid:Refresh(characterEndingIdList[i])
        else
            grid:RefreshLock()
        end
    end
end

function XUiPanelTheatre3CharacterDetail:OnBtnCloseClick()
    self.BubbleEnd.gameObject:SetActiveEx(false)
    self.BtnClose.gameObject:SetActiveEx(false)
end

--region Ui - Level
function XUiPanelTheatre3CharacterDetail:InitLevelDynamic()
    self.DynamicTable = XDynamicTableNormal.New(self.SViewLvBuffList)
    self.DynamicTable:SetProxy(XUiGridTheatre3CharacterLevel, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiPanelTheatre3CharacterDetail:UpdateCharacterLevel()
    self.CharacterLevelData = self._Control:GetCharacterLevelIdListByCharacterId(self.CharacterId)
    self.DynamicTable:SetDataSource(self.CharacterLevelData)
    self.DynamicTable:ReloadDataASync(1)
end

---@param grid XUiGridTheatre3CharacterLevel
function XUiPanelTheatre3CharacterDetail:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.CharacterLevelData[index], self.CharacterId)
    end
end
--endregion

return XUiPanelTheatre3CharacterDetail