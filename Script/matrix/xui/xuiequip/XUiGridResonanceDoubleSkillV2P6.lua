local XUiGridResonanceSkill = require("XUi/XUiEquipResonanceSkill/XUiGridResonanceSkill")
local XUiGridResonanceDoubleSkillV2P6 = XClass(nil, "XUiGridResonanceDoubleSkillV2P6")

function XUiGridResonanceDoubleSkillV2P6:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.ResonanceSkillGrids = {}
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    for i = 1, XEnumConst.EQUIP.AWARENESS_RESONANCE_COUNT do
        self["BtnAddResonanceSkill" .. i].CallBack = function()
            self:OnBtnResonanceClick(i)
        end
    end
end

function XUiGridResonanceDoubleSkillV2P6:SetForbidGotoEquip(flag)
    self.ForbidGotoEquip = flag
end

--@site: 意识的位置
function XUiGridResonanceDoubleSkillV2P6:RefreshBySite(characterId, site)
    self.CharacterId = characterId
    self.EquipId = XMVCA.XEquip:GetCharacterEquipId(characterId, site)

    self:RefreshTxtPos(site)
    local isWearing = self.EquipId and self.EquipId > 0
    if isWearing then
        --已穿戴装备
        self:RefreshResonanceSkill(characterId, self.EquipId)
    else
        --未穿戴装备
        self.PanelEmpty.gameObject:SetActiveEx(true)
        self.PanelNoResnoanceSkill.gameObject:SetActiveEx(false)
        self.ImgPos.gameObject:SetActiveEx(false)
        self.GridResnanceSkill1.gameObject:SetActive(false)
        self.GridResnanceSkill2.gameObject:SetActive(false)
    end
end

function XUiGridResonanceDoubleSkillV2P6:RefreshResonanceSkill(characterId, equipId)
    local resonanceSkillNum = XMVCA.XEquip:GetResonanceSkillNum(equipId)
    if resonanceSkillNum == 0 then
        --穿戴中的装备无共鸣技能
        self.PanelEmpty.gameObject:SetActiveEx(true)
        self.PanelNoResnoanceSkill.gameObject:SetActiveEx(false)
        self.ImgPos.gameObject:SetActiveEx(false)
        self.GridResnanceSkill1.gameObject:SetActiveEx(false)
        self.GridResnanceSkill2.gameObject:SetActiveEx(false)
    else
        --有共鸣技能时
        for skillIndex = 1, XEnumConst.EQUIP.AWARENESS_RESONANCE_COUNT do
            local go = self["GridResnanceSkill" .. skillIndex]
            local haveResonance = XMVCA.XEquip:CheckEquipPosResonanced(equipId, skillIndex)
            go.gameObject:SetActiveEx(haveResonance)
            self["PanelNoEquip0" .. skillIndex].gameObject:SetActiveEx(not haveResonance)
            if haveResonance then
                local grid = self.ResonanceSkillGrids[skillIndex]
                if not grid then
                    grid = XUiGridResonanceSkill.New(go, equipId, skillIndex, characterId, function()
                        self:OnBtnResonanceClick()
                    end)
                    self.ResonanceSkillGrids[skillIndex] = grid
                end
                grid:SetEquipIdAndPos(equipId, skillIndex)
                grid:SetCharacterId(characterId)
                grid:Refresh()
            end
        end
        self.PanelEmpty.gameObject:SetActiveEx(false)
        self.PanelNoResnoanceSkill.gameObject:SetActiveEx(true)
        self.ImgPos.gameObject:SetActiveEx(true)
    end
end

function XUiGridResonanceDoubleSkillV2P6:RefreshTxtPos(site)
    local siteStr = "0" .. site
    self.TxtPos.text = siteStr
    self.TxtPosEmpty.text = siteStr
end

function XUiGridResonanceDoubleSkillV2P6:OnBtnResonanceClick(pos)
    if self.ForbidGotoEquip then
        return
    end

    XLuaUiManager.Open("UiEquipResonanceQuick", self.CharacterId)

    if self.RootUi then
        XMVCA.XCharacter:BuryingUiCharacterAction(self.RootUi.Name, XGlobalVar.BtnUiCharacterSystemV2P6.BtnGridResnanceSkill, self.CharacterId)
    end
end

return XUiGridResonanceDoubleSkillV2P6