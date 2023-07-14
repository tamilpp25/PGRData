local XUiGridResonanceSkill = require("XUi/XUiEquipResonanceSkill/XUiGridResonanceSkill")

local SINGLE_SITE_RESONANCE_SKILL_NUM = 2

local XUiGridDoubleResonanceSkill = XClass(nil, "XUiGridDoubleResonanceSkill")

function XUiGridDoubleResonanceSkill:Ctor(ui, clickCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.ClickCb = clickCb
    self.ResonanceSkillGrids = {}
    XTool.InitUiObject(self)

    for i = 1, SINGLE_SITE_RESONANCE_SKILL_NUM do
        self["BtnAddResonanceSkill" .. i].CallBack = function()
            XMVCA:GetAgency(ModuleId.XEquip):OpenUiEquipDetail(self.EquipId, nil, self.CharacterId, nil, XEquipConfig.EquipDetailBtnTabIndex.Resonance)
            if clickCb then clickCb(self) end
        end
    end
    self:SetSelect(false)
    self.BtnClick.CallBack = function()
        if clickCb then clickCb(self) end
    end
end

function XUiGridDoubleResonanceSkill:Refresh(characterId, site)
    self:RefreshBySite(characterId, site)
end

--[[
	--@equipId:意识的id
]]
function XUiGridDoubleResonanceSkill:RefreshByEquipId(characterId, equipId, site)
    self.CharacterId = characterId

    self:RefreshTxtPos(site)
    if characterId and equipId then
        --已穿戴装备
        self.EquipId = equipId

        self:RefreshResonanceSkill(characterId, equipId)
    else
        --未穿戴装备
        self.PanelEmpty.gameObject:SetActiveEx(true)
        self.PanelNoResnoanceSkill.gameObject:SetActiveEx(false)
        self.ImgPos.gameObject:SetActiveEx(false)
        self.GridResnanceSkill1.gameObject:SetActiveEx(false)
        self.GridResnanceSkill2.gameObject:SetActiveEx(false)
    end
end

--[[
	--@site: 意识的位置
]]
function XUiGridDoubleResonanceSkill:RefreshBySite(characterId, site)
    self.CharacterId = characterId
    local wearingEquipId = XDataCenter.EquipManager.GetWearingEquipIdBySite(characterId, site)

    self:RefreshTxtPos(site)
    if wearingEquipId and wearingEquipId > 0 then
        --已穿戴装备
        self.EquipId = wearingEquipId

        self:RefreshResonanceSkill(characterId, wearingEquipId)
    else
        --未穿戴装备
        self.PanelEmpty.gameObject:SetActiveEx(true)
        self.PanelNoResnoanceSkill.gameObject:SetActiveEx(false)
        self.ImgPos.gameObject:SetActiveEx(false)
        self.GridResnanceSkill1.gameObject:SetActiveEx(false)
        self.GridResnanceSkill2.gameObject:SetActiveEx(false)
    end
end

function XUiGridDoubleResonanceSkill:RefreshResonanceSkill(characterId, equipId)
    local resonanceSkillNum = XDataCenter.EquipManager.GetResonanceSkillNum(equipId)
    if resonanceSkillNum == 0 then
        --穿戴中的装备无共鸣技能
        self.PanelEmpty.gameObject:SetActiveEx(true)
        self.PanelNoResnoanceSkill.gameObject:SetActiveEx(false)
        self.ImgPos.gameObject:SetActiveEx(false)
        self.GridResnanceSkill1.gameObject:SetActiveEx(false)
        self.GridResnanceSkill2.gameObject:SetActiveEx(false)
    else
        --有共鸣技能时
        for skillIndex = 1, SINGLE_SITE_RESONANCE_SKILL_NUM do
            local go = self["GridResnanceSkill" .. skillIndex]
            if XDataCenter.EquipManager.CheckEquipPosResonanced(equipId, skillIndex) then
                local grid = self.ResonanceSkillGrids[skillIndex]
                if not grid then
                    grid = XUiGridResonanceSkill.New(go, equipId, skillIndex, characterId, function(tmpEquipId, tmpPos, tmpCharacterId)
                        XLuaUiManager.Open("UiEquipResonanceSkillDetailInfo", tmpEquipId, tmpPos, tmpCharacterId)
                        if self.ClickCb then self.ClickCb(self) end
                    end)
                    self.ResonanceSkillGrids[skillIndex] = grid
                end
                grid:SetEquipIdAndPos(equipId, skillIndex)
                grid:Refresh()
                grid.GameObject:SetActiveEx(true)
            else
                go.gameObject:SetActiveEx(false)
            end
        end
        self.PanelEmpty.gameObject:SetActiveEx(false)
        self.PanelNoResnoanceSkill.gameObject:SetActiveEx(true)
        self.ImgPos.gameObject:SetActiveEx(true)
    end
end

function XUiGridDoubleResonanceSkill:RefreshTxtPos(site)
    local siteStr = "0" .. site
    self.TxtPos.text = siteStr
    self.TxtPosEmpty.text = siteStr
end

function XUiGridDoubleResonanceSkill:SetSelect(value)
    if self.ImgSelect then
        -- self.ImgSelect.gameObject:SetActiveEx(value)
        self.ImgSelect.gameObject:SetActiveEx(false)
    end
end

return XUiGridDoubleResonanceSkill