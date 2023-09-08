local XUiGridResonanceSkillOther = require("XUi/XUiEquipResonanceSkill/XUiGridResonanceSkillOther")
local XUiGridResonanceDoubleSkillOther = XClass(XUiNode, "XUiGridResonanceDoubleSkillOther")

function XUiGridResonanceDoubleSkillOther:OnStart()
    self.ResonanceSkillGrids = {}
    for i = 1, XEnumConst.EQUIP.AWARENESS_RESONANCE_COUNT do
        self["BtnAddResonanceSkill" .. i].CallBack = function()
            self:OnBtnResonanceClick(i)
        end
    end
end

--@site: 意识的位置
function XUiGridResonanceDoubleSkillOther:RefreshBySite(equipData, characterId, site)
    self.EquipData = equipData
    self.CharacterId = characterId
    self.Site = site
    self.EquipId = equipData and equipData.Id

    self:RefreshTxtPos(site)
    local isWearing = self.EquipId and self.EquipId > 0
    if isWearing then
        --已穿戴装备
        self:RefreshResonanceSkill()
    else
        --未穿戴装备
        self.PanelEmpty.gameObject:SetActiveEx(true)
        self.PanelNoResnoanceSkill.gameObject:SetActiveEx(false)
        self.ImgPos.gameObject:SetActiveEx(false)
        self.GridResnanceSkill1.gameObject:SetActive(false)
        self.GridResnanceSkill2.gameObject:SetActive(false)
    end
end

function XUiGridResonanceDoubleSkillOther:RefreshResonanceSkill()
    local resonanceSkillNum = 0
    local resonanceInfo = self.EquipData.ResonanceInfo
    if resonanceInfo then
        resonanceSkillNum = #resonanceInfo
    end
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
            local haveResonance = resonanceInfo[skillIndex]
            go.gameObject:SetActiveEx(haveResonance)
            self["PanelNoEquip0" .. skillIndex].gameObject:SetActiveEx(not haveResonance)
            if haveResonance then
                local grid = self.ResonanceSkillGrids[skillIndex]
                if not grid then
                    grid = XUiGridResonanceSkillOther.New(go, self, self.EquipId, skillIndex, self.CharacterId, function()
                        self:OnBtnResonanceClick()
                    end)
                    self.ResonanceSkillGrids[skillIndex] = grid
                end
                grid:Open()
                grid:SetEquipIdAndPos(self.EquipData, skillIndex)
                grid:SetCharacterId(self.CharacterId)
                local skillInfo = XDataCenter.EquipManager.GetResonanceSkillInfoByEquipData(self.EquipData, skillIndex)
                grid:Refresh(skillInfo, self.EquipData.ResonanceInfo[skillIndex].CharacterId)
            end
        end
        self.PanelEmpty.gameObject:SetActiveEx(false)
        self.PanelNoResnoanceSkill.gameObject:SetActiveEx(true)
        self.ImgPos.gameObject:SetActiveEx(true)
    end
end

function XUiGridResonanceDoubleSkillOther:RefreshTxtPos(site)
    local siteStr = "0" .. site
    self.TxtPos.text = siteStr
    self.TxtPosEmpty.text = siteStr
end

function XUiGridResonanceDoubleSkillOther:OnBtnResonanceClick(pos)
    -- XLuaUiManager.Open("UiEquipDetailV2P6", self.EquipId, nil, self.CharacterId, nil, XEnumConst.EQUIP.UI_EQUIP_DETAIL_BTN_INDEX.RESONANCE, nil, pos)
end

return XUiGridResonanceDoubleSkillOther