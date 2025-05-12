local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridScoreTowerCharacter = require("XUi/XUiScoreTower/Common/XUiGridScoreTowerCharacter")
---@class XUiScoreTowerPopupQuicklySelect : XLuaUi
---@field private _Control XScoreTowerControl
local XUiScoreTowerPopupQuicklySelect = XLuaUiManager.Register(XLuaUi, "UiScoreTowerPopupQuicklySelect")

function XUiScoreTowerPopupQuicklySelect:OnAwake()
    self:RegisterUiEvents()
    self.GridCharacter.gameObject:SetActiveEx(false)
end

---@param chapterId number 章节ID
---@param towerId number 塔ID
---@param towerTeam XScoreTowerTowerTeam 塔队伍
---@param callback function 回调
function XUiScoreTowerPopupQuicklySelect:OnStart(chapterId, towerId, towerTeam, callback)
    self.ChapterId = chapterId
    self.TowerId = towerId
    self.TowerTeam = towerTeam
    self.Callback = callback
    self:InitDynamicTable()
end

function XUiScoreTowerPopupQuicklySelect:OnEnable()
    self:SetupDynamicTable()
end

function XUiScoreTowerPopupQuicklySelect:OnDestroy()
    self.TowerTeam = nil
end

function XUiScoreTowerPopupQuicklySelect:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.ListCharacter)
    self.DynamicTable:SetProxy(XUiGridScoreTowerCharacter, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiScoreTowerPopupQuicklySelect:SetupDynamicTable()
    ---@type { Id:number }[]
    self.CharacterList = self._Control:GetTowerShowCharacterInfoList(self.ChapterId, self.TowerId, self.TowerTeam)
    self.DynamicTable:SetDataSource(self.CharacterList)
    self.DynamicTable:ReloadDataASync()
end

---@param grid XUiGridScoreTowerCharacter
function XUiScoreTowerPopupQuicklySelect:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local character = self.CharacterList[index]
        grid:Refresh(character.Id, index)
        grid:SetIsRecommend(self._Control:IsTowerSuggestTag(self.TowerId, character.Id))
        local isTeam, pos = self.TowerTeam:GetEntityIdIsInTeam(character.Id)
        grid:SetIsInTeam(isTeam, pos)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:OnCharacterGridClick(self.CharacterList[index], grid)
    end
end

-- 点击角色格子
---@param character { Id:number } 角色信息
---@param grid XUiGridScoreTowerCharacter 角色格子
function XUiScoreTowerPopupQuicklySelect:OnCharacterGridClick(character, grid)
    local isTeam, pos = self.TowerTeam:GetEntityIdIsInTeam(character.Id)
    if isTeam then
        self.TowerTeam:RemoveTowerEntityId(character.Id, pos)
        grid:SetIsInTeam(false)
    else
        -- 判断当前塔队伍是否已满
        if self.TowerTeam:GetIsFullMember() then
            XUiManager.TipMsg(self._Control:GetClientConfig("TowerTeamRelatedTips", 1))
            return
        end
        -- 检查是否存在相同角色
        local isSame, samePos = self.TowerTeam:CheckHasSameCharacterId(character.Id)
        if isSame then
            local desc = self._Control:GetClientConfig("TowerTeamRelatedTips", 2)
            XUiManager.TipMsg(XUiHelper.FormatText(desc, samePos))
            return
        end
        pos = self.TowerTeam:AddTowerEntityId(character.Id)
        if pos <= 0 then
            XLog.Error(string.format("error: add Tower entity id failed, entityId: %s", character.Id))
        end
        grid:SetIsInTeam(true, pos)
    end
    -- 同步刷新塔界面
    if self.Callback then
        self.Callback()
    end
    -- 播放音效
    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.Fight_PageSwitch_Up)
end

function XUiScoreTowerPopupQuicklySelect:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnStart, self.OnBtnCloseClick)
end

function XUiScoreTowerPopupQuicklySelect:OnBtnCloseClick()
    self:Close()
end

return XUiScoreTowerPopupQuicklySelect
