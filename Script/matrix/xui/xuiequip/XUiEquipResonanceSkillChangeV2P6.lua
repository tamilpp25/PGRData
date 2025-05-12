local XUiGridEquipResonanceSkillChangeV2P6 = require("XUi/XUiEquip/XUiGridEquipResonanceSkillChangeV2P6")
local XUiEquipResonanceSkillChangeV2P6 = XLuaUiManager.Register(XLuaUi, "UiEquipResonanceSkillChangeV2P6")

function XUiEquipResonanceSkillChangeV2P6:OnAwake()
    self.GridResonanceSkill.gameObject:SetActiveEx(false)

    self.ResonanceSkillGrids = {}
    self:SetButtonCallBack()
end

function XUiEquipResonanceSkillChangeV2P6:OnStart(characterId, equipId)
    self.CharacterId = characterId
    self.EquipId = equipId

    -- 共鸣数量、当前位置对应技能
    local equip = XMVCA:GetAgency(ModuleId.XEquip):GetEquip(self.EquipId)
    local resonanceInfoDic = equip:GetResonanceInfoDic()
    self.ResonanceCount = 0
    self.ResonancePosSkillDic = {}
    self.IsSelectFull = true
    for _, info in pairs(resonanceInfoDic) do
        if info and info.CharacterId == self.CharacterId then 
            self.ResonanceCount = self.ResonanceCount + 1
            self.ResonancePosSkillDic[info.Slot] = info.TemplateId
        end
    end

    self:UpdateView()
end

function XUiEquipResonanceSkillChangeV2P6:SetButtonCallBack()
    self:RegisterClickEvent(self.BtnTanchuangClose, self.Close)
    self:RegisterClickEvent(self.BtnCancel, self.Close)
    self:RegisterClickEvent(self.BtnEnter, self.OnBtnEnterClick)
end

function XUiEquipResonanceSkillChangeV2P6:OnBtnEnterClick()
    -- 未选满技能
    if not self.IsSelectFull then
        return
    end

    -- 只筛选变化的技能
    local equip = XMVCA:GetAgency(ModuleId.XEquip):GetEquip(self.EquipId)
    local slots = {}
    local selectSkillIds = {}
    for pos, skillId in pairs(self.ResonancePosSkillDic) do
        if equip:GetResonanceInfo(pos).TemplateId ~= skillId then
            table.insert(slots, pos)
            table.insert(selectSkillIds, skillId)
        end
    end

    if #slots == 0 then
        self:Close()
        return
    end

    XMVCA:GetAgency(ModuleId.XEquip):RequestEquipResonance(self.EquipId, slots, self.CharacterId, nil, nil, selectSkillIds, XEnumConst.EQUIP.RESONANCE_TYPE.WEAPON_SKILL)
    self:Close()
end

-- 刷新界面
function XUiEquipResonanceSkillChangeV2P6:UpdateView()
    -- 角色名
    local charConfig = XMVCA.XCharacter:GetCharacterTemplate(self.CharacterId)
    self.TxtCharacterName.text = charConfig.Name
    self.TxtCharacterNameOther.text = charConfig.TradeName

    -- 当前共鸣数量
    self:UpdateSelectSkillCount()
    self.TxtMaxSkillCount.text = tostring("/"..self.ResonanceCount)

    self:UpdateSkillList()
end

-- 刷新当前选择的技能数
function XUiEquipResonanceSkillChangeV2P6:UpdateSelectSkillCount()
    local selectCnt = 0
    for _, skillId in pairs(self.ResonancePosSkillDic) do
        if skillId and skillId ~= 0 then
            selectCnt = selectCnt + 1
        end
    end
    self.TxtCurSkillCount.text = tostring(selectCnt)
end

-- 刷新技能列表
function XUiEquipResonanceSkillChangeV2P6:UpdateSkillList()
    local pos = 1 -- 三个位置的技能列表都是一样，取第一个
    self.SkillInfoList = self._Control:GetResonancePreviewSkillInfoList(self.EquipId, self.CharacterId, pos)
    for index, skillInfo in ipairs(self.SkillInfoList) do
        local skillGrid = self.ResonanceSkillGrids[index]
        if not skillGrid then
            local item = CS.UnityEngine.Object.Instantiate(self.GridResonanceSkill)
            item.transform:SetParent(self.PanelSkillContent.transform, false)
            item.gameObject:SetActiveEx(true)
            skillGrid = XUiGridEquipResonanceSkillChangeV2P6.New(item, self)
            self.ResonanceSkillGrids[index] = skillGrid
        end

        skillGrid:Refresh(self.EquipId, skillInfo)
        skillGrid:UpdateSelectState(self.ResonancePosSkillDic)
    end
end

function XUiEquipResonanceSkillChangeV2P6:OnGridSkillClick(selectSkillId)
    -- 技能是否已选中
    local selectPos
    for pos, skillId in pairs(self.ResonancePosSkillDic) do
        if skillId == selectSkillId then 
            selectPos = pos
            break
        end
    end

    -- 已选中的取消选中
    if selectPos then
        self.ResonancePosSkillDic[selectPos] = 0
    else
        -- 技能未满的，可以成功选中
        local isSelectSuccess = false
        for pos, skillId in pairs(self.ResonancePosSkillDic) do
            if skillId == 0 then
                self.ResonancePosSkillDic[pos] = selectSkillId
                isSelectSuccess = true
                break
            end
        end

        -- 技能已选满，选中失败
        if not isSelectSuccess then
            return
        end
    end

    -- 刷新技能的选中
    for index, skillInfo in ipairs(self.SkillInfoList) do
        local skillGrid = self.ResonanceSkillGrids[index]
        skillGrid:UpdateSelectState(self.ResonancePosSkillDic)
    end
    self:UpdateSelectSkillCount()

    -- 刷新确定按钮
    self.IsSelectFull = true
    for pos, skillId in pairs(self.ResonancePosSkillDic) do
        if skillId == 0 then
            self.IsSelectFull = false
            break
        end
    end
    self.BtnEnter:SetDisable(not self.IsSelectFull)
end

return XUiEquipResonanceSkillChangeV2P6