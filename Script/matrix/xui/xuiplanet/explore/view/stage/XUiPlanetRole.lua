local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiPlanetExploreGridCharacter = require("XUi/XUiPlanet/Explore/View/Stage/XUiPlanetExploreGridCharacter")
local XUiPlanetGridBuff = require("XUi/XUiPlanet/Explore/View/Stage/XUiPlanetGridBuff")

---@class XUiPlanetRole:XLuaUi
local XUiPlanetRole = XLuaUiManager.Register(XLuaUi, "UiPlanetRole")

function XUiPlanetRole:Ctor()
    ---@type XPlanetCharacter
    self._CharacterSelected = false
    self.IsTalent = false
end

function XUiPlanetRole:OnAwake()
    self:InitDynamicTable()
    ---@type XUiPlanetGridBuff
    self._GridBuff = XUiPlanetGridBuff.New(self.ImgBuff)
    self:RegisterClickEvent(self.BtnConfirm, self.OnClickJoin)
    self:RegisterClickEvent(self.BtnUnlocked, self.OnClickJoin)
    self:RegisterClickEvent(self.BtnCancel, self.OnClickKickOut)
    self:RegisterClickEvent(self.BtnCaptain, self.OnClickCaptain)
    self:RegisterClickEvent(self.BtnDetermine, self.OnClickClose)
    self:RegisterClickEvent(self.BtnWndClose, self.OnClickClose)
    self:RegisterClickEvent(self.BtnClose, self.OnClickClose)
    self.PanelTxt = self.PanelTxt or XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/PanelDetails/ImgBg/PanelTxt", "ScrollRect")
end

function XUiPlanetRole:OnStart(characterSelected, IsTalent, closeCb)
    self:SetSelected(characterSelected)
    self.IsTalent = IsTalent
    self._CloseCb = closeCb
end

function XUiPlanetRole:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_PLANET_UPDATE_TEAM, self.OnTeamUpdate, self)
    XEventManager.AddEventListener(XEventId.EVENT_PLANET_UPDATE_REFROM_TEAM, self.OnTeamUpdate, self)
    self:UpdateCharacter()
    self:UpdateMemberAmount()
end

function XUiPlanetRole:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_PLANET_UPDATE_TEAM, self.OnTeamUpdate, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_PLANET_UPDATE_REFROM_TEAM, self.OnTeamUpdate, self)
end

function XUiPlanetRole:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelEmploymentList)
    self.DynamicTable:SetProxy(XUiPlanetExploreGridCharacter)
    self.DynamicTable:SetDelegate(self)
    self.GridRole.gameObject:SetActiveEx(false)
end

function XUiPlanetRole:UpdateCharacter()
    local characterList = XDataCenter.PlanetExploreManager.GetAllCharacter()
    if not self._CharacterSelected then
        self:SetSelected(characterList[1])
    end
    self.DynamicTable:SetDataSource(characterList)

    local index = 1
    if self._CharacterSelected then
        for i = 1, #characterList do
            if characterList[i] == self._CharacterSelected then
                index = i
                break
            end
        end
    end
    self.DynamicTable:ReloadDataASync(index)
end

---@param grid XUiPlanetExploreGridCharacter
function XUiPlanetRole:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:RegisterClick(function(character)
            self:SetSelected(character, true)
        end)
        grid:UpdateSelected(self._CharacterSelected)

    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.DynamicTable:GetData(index)
        grid:Update(data, self.IsTalent)
        grid:UpdateSelected(self._CharacterSelected)

    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
    end
end

function XUiPlanetRole:SetSelected(character, isShowSelectEffect)
    if not character then
        return
    end
    self._CharacterSelected = character
    XDataCenter.PlanetManager.ClearOneCharacterUnlockRed(self._CharacterSelected:GetCharacterId())
    self:UpdateSelected(isShowSelectEffect)
    self:UpdateData()
end

function XUiPlanetRole:UpdateSelected(isShowSelectEffect)
    local grids = self.DynamicTable:GetGrids()
    for index, grid in pairs(grids) do
        grid:UpdateSelected(self._CharacterSelected, isShowSelectEffect)
    end
end

function XUiPlanetRole:UpdateData()
    local character = self._CharacterSelected
    self.RImgHead:SetRawImage(character:GetIcon())
    self.TxtPlanet2.text = character:GetFrom()
    self.TxtName.text = character:GetName()
    if character:IsUnlock() then
        self.TxtSkillDesc.text = character:GetStory()
        self.TxtSkillDesc.gameObject:SetActiveEx(true)
        self.PanelTxt.gameObject:SetActiveEx(true)
        self.PanelTxt.verticalNormalizedPosition = 1
    else
        self.TxtSkillDesc.gameObject:SetActiveEx(false)
        self.PanelTxt.gameObject:SetActiveEx(false)
    end
    local buffList = character:GetBuff()
    local oneBuff = buffList[1]
    if oneBuff then
        self._GridBuff:Update(oneBuff)
        self._GridBuff.GameObject:SetActiveEx(true)
        self.PanelNoResult.gameObject:SetActiveEx(false)
    else
        self._GridBuff.GameObject:SetActiveEx(false)
        self.PanelNoResult.gameObject:SetActiveEx(true)
    end
    if self.SkillUnlocked then
        self.SkillUnlocked.gameObject:SetActiveEx(not character:IsUnlock())
        self.TxtSkillUnlocked.text = character:GetLockDesc()
    end
    self:UpdateBtnJoin()
    self:PlayAnimation("QieHuan")
end

function XUiPlanetRole:UpdateBtnJoin()
    if self._CharacterSelected then
        if not self._CharacterSelected:IsUnlock() then
            self:_ShowConfirm(false)
            self.BtnCancel.gameObject:SetActiveEx(false)
            if self.BtnUnlocked then
                self.BtnUnlocked.gameObject:SetActiveEx(true)
            end
            self.BtnCaptain.gameObject:SetActiveEx(false)
            return
        end
        if self.BtnUnlocked then
            self.BtnUnlocked.gameObject:SetActiveEx(false)
        end

        if self:CheckSelectCharInTeam() then
            self:_ShowConfirm(false)
            self.BtnCancel.gameObject:SetActiveEx(true)
            if not self:CheckSelectCharIsLeader() then
                self.BtnCaptain.gameObject:SetActiveEx(true)
            else
                self.BtnCaptain.gameObject:SetActiveEx(false)
            end
        else
            self.BtnCaptain.gameObject:SetActiveEx(false)
            self.BtnCancel.gameObject:SetActiveEx(false)
            self:_ShowConfirm(true, self:_IsTeamMax())
        end
    end
end

function XUiPlanetRole:_ShowConfirm(active, isDisable)
    self.BtnConfirm.gameObject:SetActiveEx(active)
    self.BtnConfirm:SetDisable(isDisable or false)
end

function XUiPlanetRole:_IsTeamMax()
    if self.IsTalent then
        local team = XDataCenter.PlanetManager.GetTeam()
        return team:GetAmount() >= team:GetCapacity()
    else
        local team = XDataCenter.PlanetExploreManager.GetTeam()
        return team:GetAmount() >= team:GetCapacity()
    end
end

function XUiPlanetRole:CheckSelectCharInTeam()
    if not self._CharacterSelected then
        return false
    end
    return self.IsTalent and self._CharacterSelected:IsInTalentTeam() or not self.IsTalent and self._CharacterSelected:IsInTeam()
end

function XUiPlanetRole:CheckSelectCharIsLeader()
    if not self._CharacterSelected then
        return false
    end
    return self.IsTalent and self._CharacterSelected:IsTalentTeamLeader() or not self.IsTalent and self._CharacterSelected:IsCaptain()
end

function XUiPlanetRole:OnClickJoin()
    if self.IsTalent then
        self:OnTalentClickJoin()
        return
    end
    local team = XDataCenter.PlanetExploreManager.GetTeam()
    team:JoinMember(self._CharacterSelected)
    XEventManager.DispatchEvent(XEventId.EVENT_PLANET_UPDATE_TEAM)
end

function XUiPlanetRole:OnClickKickOut()
    if self.IsTalent then
        self:OnTalentClickKickOut()
        return
    end
    local team = XDataCenter.PlanetExploreManager.GetTeam()
    team:KickOut(self._CharacterSelected)
    XEventManager.DispatchEvent(XEventId.EVENT_PLANET_UPDATE_TEAM)
end

function XUiPlanetRole:OnTeamUpdate()
    self:UpdateCharacter()
    self:UpdateBtnJoin()
    self:UpdateMemberAmount()
end

function XUiPlanetRole:OnClickCaptain()
    if self.IsTalent then
        self:OnTalentClickCaptain()
        return
    end
    local team = XDataCenter.PlanetExploreManager.GetTeam()
    team:SetCaptain(self._CharacterSelected)
end

function XUiPlanetRole:UpdateMemberAmount()
    local textAmount = 0
    if self.IsTalent then
        local team = XDataCenter.PlanetManager.GetTeam()
        textAmount = string.format("(%d/%d)", team:GetAmount(), team:GetCapacity())
    else
        local team = XDataCenter.PlanetExploreManager.GetTeam()
        textAmount = string.format("(%d/%d)", team:GetAmount(), team:GetCapacity())
    end
    self.TxtNumber.text = textAmount
    self.BtnConfirm:SetNameByGroup(1, textAmount)
end

function XUiPlanetRole:OnClickClose()
    self:Close()
    if self._CloseCb then
        self._CloseCb()
    end
end

--region 外部场景
function XUiPlanetRole:OnTalentClickCaptain()
    local team = XDataCenter.PlanetManager.GetTeam()
    team:SetLeader(self._CharacterSelected:GetCharacterId())
end

function XUiPlanetRole:OnTalentClickJoin()
    local team = XDataCenter.PlanetManager.GetTeam()
    team:JoinMember(self._CharacterSelected:GetCharacterId())
end

function XUiPlanetRole:OnTalentClickKickOut()
    local team = XDataCenter.PlanetManager.GetTeam()
    team:KickOut(self._CharacterSelected:GetCharacterId())
end
--endregion

return XUiPlanetRole