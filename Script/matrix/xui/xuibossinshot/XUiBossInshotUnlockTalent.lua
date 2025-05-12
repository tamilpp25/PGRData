---@class XUiBossInshotUnlockTalent:XLuaUi
---@field private _Control XBossInshotControl
local XUiBossInshotUnlockTalent = XLuaUiManager.Register(XLuaUi, "UiBossInshotUnlockTalent")

function XUiBossInshotUnlockTalent:OnAwake()
    self.TalentUiObjs = { self.GridTalent }
    self:RegisterUiEvents()
end

function XUiBossInshotUnlockTalent:OnStart(characterId, newTalentIds)
    self.CharacterId = characterId
    self.NewTalentIds = newTalentIds
end

function XUiBossInshotUnlockTalent:OnEnable()
    self:Refresh()
end

function XUiBossInshotUnlockTalent:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnClose, self.Close)
end

function XUiBossInshotUnlockTalent:Refresh()
    self:RefreshCharacterInfo()
    self:RefreshTalents()
end

function XUiBossInshotUnlockTalent:RefreshCharacterInfo()
    local tradeName = XMVCA.XCharacter:GetCharacterTradeName(self.CharacterId)
    local icon = XMVCA.XCharacter:GetCharSmallHeadIcon(self.CharacterId, true)
    self.TxtTitle.text = XUiHelper.GetText("BossInshotTalentUnlock", tradeName)
    self.TextName.text = XMVCA.XCharacter:GetCharacterFullNameStr(self.CharacterId)
    self.RImgHeadIcon:SetRawImage(icon)
end

function XUiBossInshotUnlockTalent:RefreshTalents()
    for _, uiObj in ipairs(self.TalentUiObjs) do
        uiObj.gameObject:SetActiveEx(false)
    end
    
    local CSInstantiate = CS.UnityEngine.Object.Instantiate
    for i, talentId in ipairs(self.NewTalentIds) do
        local uiObj = self.TalentUiObjs[i]
        if not uiObj then
            uiObj = CSInstantiate(self.GridTalent, self.PanelTalent)
        end
        uiObj.gameObject:SetActiveEx(true)

        local config = self._Control:GetConfigBossInshotTalent(talentId)
        uiObj:GetObject("RImgIcon"):SetRawImage(config.Icon)
        uiObj:GetObject("TxtName").text = config.Name
        uiObj:GetObject("TxtDesc").text = config.Desc
    end
end

return XUiBossInshotUnlockTalent