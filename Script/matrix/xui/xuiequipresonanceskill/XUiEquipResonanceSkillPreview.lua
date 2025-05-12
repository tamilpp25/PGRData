local XUiGridEquipResonanceSkillPreview = require("XUi/XUiEquipResonanceSkill/XUiGridEquipResonanceSkillPreview")
local XUiEquipResonanceSkillPreview = XLuaUiManager.Register(XLuaUi, "UiEquipResonanceSkillPreview")

function XUiEquipResonanceSkillPreview:OnAwake()
    self:AutoAddListener()

    self.GridResonanceSkill.gameObject:SetActiveEx(false)
end

function XUiEquipResonanceSkillPreview:OnStart(params)
    self.RootUi = params.rootUi
    self.Params = params
    self.LastSelectSkillInfo = params.selectSkillInfo

    self.BtnEnter:SetDisable(true, false)
    self.BtnCancel.gameObject:SetActiveEx(self.Params.isNeedSelectSkill)
    self.BtnEnter.gameObject:SetActiveEx(self.Params.isNeedSelectSkill)

    self:UpdateCharacterName()
    self:UpdateSkillPreviewScroll()
    self:UpdateResonanceSkillGridsBtnGroup()
end

function XUiEquipResonanceSkillPreview:UpdateCharacterName()
    if self.Params.selectCharacterId then
        local charConfig = XMVCA.XCharacter:GetCharacterTemplate(self.Params.selectCharacterId)
        self.TxtCharacterName.text = charConfig.Name
        self.TxtCharacterNameOther.text = charConfig.TradeName
    else
        self.TxtCharacterName.text = ""
        self.TxtCharacterNameOther.text = ""
    end
end

--@region Update PreviewScroll Item

function XUiEquipResonanceSkillPreview:UpdateResonanceSkillGridsBtnGroup()
    if not self.Params.isNeedSelectSkill then
        return
    end
    local btnGroup = self.PanelCharacterContent:GetComponent("XUiButtonGroup")
    local tlButtonGo = {}
    for i,v in ipairs(self.ResonanceSkillGrids) do
        table.insert(tlButtonGo, v.GameObject:GetComponent("XUiButton"))
    end

    btnGroup:Init(tlButtonGo, function(index) self:OnItemClick(index) end)
end

function XUiEquipResonanceSkillPreview:UpdateSkillPreviewScroll()
    self.ResonanceSkillGrids = {}
    local equipId = self.Params.equipId
    local preSkillInfoList = self:GetPreSkillInfoList(equipId)

    for skillIndex, skillInfo in ipairs(preSkillInfoList) do
        if not self.ResonanceSkillGrids[skillIndex] then
            self.ResonanceSkillGrids[skillIndex] = self:CreateItem()
        end

        self.ResonanceSkillGrids[skillIndex]:Refresh({
            equipId = equipId,
            skillInfo = skillInfo,
            selectSkillInfo = self.LastSelectSkillInfo,
            selectCharacterId = self.Params.selectCharacterId,
            pos = self.Params.pos,
            isIgnoreResonance = self.Params.isIgnoreResonance,
        })
    end
end

function XUiEquipResonanceSkillPreview:GetPreSkillInfoList(equipId)
    local list = self._Control:GetResonancePreviewSkillInfoList(equipId, self.Params.selectCharacterId, self.Params.pos)
    local equip = XMVCA.XEquip:GetEquip(equipId)
    
    if equip.ResonanceInfo then
        -- 默认按照list的顺序
        local skillOrderDic = {}
        for i, skillInfo in ipairs(list) do
            skillOrderDic[skillInfo.Id] = i
        end

        -- 已共鸣的放最后
        for _, resInfo in pairs(equip.ResonanceInfo) do
            skillOrderDic[resInfo.TemplateId] = math.maxinteger
        end

        table.sort(list, function (a, b)
            return skillOrderDic[a.Id] < skillOrderDic[b.Id]
        end)
    end

    return list
end

function XUiEquipResonanceSkillPreview:CreateItem()
    local item = CS.UnityEngine.Object.Instantiate(self.GridResonanceSkill)  -- 复制一个item
    local grid = XUiGridEquipResonanceSkillPreview.New(item)
    grid.Transform:SetParent(self.PanelCharacterContent, false)
    grid.GameObject:SetActiveEx(true)

    return grid
end

function XUiEquipResonanceSkillPreview:OnItemClick(index)
    self.SelectSkillInfo = self.ResonanceSkillGrids[index]:GetSkillInfo()
    self.BtnEnter:SetDisable(false, false)
end

--@endregion


function XUiEquipResonanceSkillPreview:AutoAddListener()
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnCancel, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnEnter, self.OnBtnEnterClick)
end

function XUiEquipResonanceSkillPreview:OnBtnCloseClick()
    self:Close()
end

function XUiEquipResonanceSkillPreview:OnBtnEnterClick()
    if self.SelectSkillInfo then
        self.Params.ClickCb(self.SelectSkillInfo)
        self:Close()
    end
end