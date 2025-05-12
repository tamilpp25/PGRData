---@class XUiPanelBossInshotTeam
local XUiPanelBossInshotTeam = XClass(nil, "XUiPanelBossInshotTeam")

function XUiPanelBossInshotTeam:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:RegisterUiEvents()
end

-- team : XTeam
function XUiPanelBossInshotTeam:SetData(team, stageId, rootUi)
    self.Team = team
    self.StageId = stageId
    self.RootUi = rootUi
    self:Refresh()
end

function XUiPanelBossInshotTeam:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.GridTalent1:GetObject("BtnClick"), self.OnBtnTalentClick1)
    XUiHelper.RegisterClickEvent(self, self.GridTalent2:GetObject("BtnClick"), self.OnBtnTalentClick2)
end

function XUiPanelBossInshotTeam:OnBtnTalentClick1()
    local pos, entityId = self:GetTeamFirstEntity()
    if not pos then return end

    local talentPos = 1
    XMVCA.XBossInshot:SetCharacterDetailTalentPos(talentPos)
    self.RootUi:OnBtnCharacterClicked(pos)
end

function XUiPanelBossInshotTeam:OnBtnTalentClick2()
    local pos, entityId = self:GetTeamFirstEntity()
    if not pos then return end

    local talentPos = 2
    XMVCA.XBossInshot:SetCharacterDetailTalentPos(talentPos)
    self.RootUi:OnBtnCharacterClicked(pos)
end

function XUiPanelBossInshotTeam:Refresh()
    local pos, entityId = self:GetTeamFirstEntity()
    local selTalentIds = {}
    if entityId ~= nil then
        local characterId = XEntityHelper.GetCharacterIdByEntityId(entityId)
        selTalentIds = XMVCA.XBossInshot:GetCharacterSelectTalentIds(characterId)
    end
    
    -- 手动穿戴的天赋    
    for i = 1, XEnumConst.BOSSINSHOT.WEAR_TALENT_MAX_CNT do
        local talentId = selTalentIds[i]
        local uiObj = self["GridTalent"..i]
        local isEquipTalent = talentId ~= nil and talentId ~= 0
        uiObj:GetObject("PanelTalent").gameObject:SetActiveEx(isEquipTalent)
        uiObj:GetObject("PanelAdd").gameObject:SetActiveEx(not isEquipTalent)
        if isEquipTalent then
            local config = XMVCA.XBossInshot:GetConfigBossInshotTalent(talentId)
            uiObj:GetObject("RImgIcon"):SetRawImage(config.Icon)
            uiObj:GetObject("TxtName").text = config.Name
            uiObj:GetObject("TxtDesc").text = config.Desc
        end
    end
end

function XUiPanelBossInshotTeam:GetTeamFirstEntity()
    local entityIds = self.Team:GetEntityIds()
    for i, entityId in pairs(entityIds) do
        if entityId and entityId ~= 0 then
            return i, entityId
        end
    end
    return nil
end

return XUiPanelBossInshotTeam