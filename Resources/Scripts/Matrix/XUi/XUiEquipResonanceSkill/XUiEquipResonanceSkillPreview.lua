local XUiGridEquipResonanceSkillPreview = require("XUi/XUiEquipResonanceSkill/XUiGridEquipResonanceSkillPreview")
local XUiEquipResonanceSkillPreview = XLuaUiManager.Register(XLuaUi, "UiEquipResonanceSkillPreview")

function XUiEquipResonanceSkillPreview:OnAwake()
    self:AutoAddListener()

    self.GridResonanceSkill.gameObject:SetActiveEx(false)
end

function XUiEquipResonanceSkillPreview:OnStart(params)
    self.RootUi = params.rootUi
    self.Params = params
    self.SelectSkillInfo = params.selectSkillInfo

    self.BtnEnter:SetDisable(true, false)
    self.BtnCancel.gameObject:SetActiveEx(self.Params.isNeedSelectSkill)
    self.BtnEnter.gameObject:SetActiveEx(self.Params.isNeedSelectSkill)

    self:UpdateCharacterName()
    self:UpdateSkillPreviewScroll()
    self:UpdateResonanceSkillGridsBtnGroup()
end

function XUiEquipResonanceSkillPreview:UpdateCharacterName()
    local charConfig = XCharacterConfigs.GetCharacterTemplate(self.RootUi.SelectCharacterId)
    self.TxtCharacterName.text = charConfig.Name
    self.TxtCharacterNameOther.text = charConfig.TradeName
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
    local equipId = self.RootUi.EquipId
    local preSkillInfoList = self:GetPreSkillInfoList(equipId)

    for skillIndex, skillInfo in ipairs(preSkillInfoList) do
        if not self.ResonanceSkillGrids[skillIndex] then
            self.ResonanceSkillGrids[skillIndex] = self:CreateItem()
        end

        self.ResonanceSkillGrids[skillIndex]:Refresh({
            equipId = equipId,
            skillInfo = skillInfo,
            selectSkillInfo = self.SelectSkillInfo,
            selectCharacterId = self.RootUi.SelectCharacterId,
            pos = self.Params.pos
        })
    end
end

function XUiEquipResonanceSkillPreview:GetPreSkillInfoList(equipId)
    local equipId = self.RootUi.EquipId
    local list = XDataCenter.EquipManager.GetResonancePreSkillInfoList(equipId, self.RootUi.SelectCharacterId, self.RootUi.Pos)
    local equip = XDataCenter.EquipManager.GetEquip(equipId)
    
    if equip.ResonanceInfo then
        local getWeight = function (skillInfo)
            for i,v in pairs(equip.ResonanceInfo) do
                local bindCharacterId = v.CharacterId
                if bindCharacterId == self.RootUi.SelectCharacterId then
                    local s = XDataCenter.EquipManager.GetResonanceSkillInfo(equipId, v.Slot)
                    if XDataCenter.EquipManager.IsClassifyEqual(equipId, XEquipConfig.Classify.Awareness) then
                        if s.Id == skillInfo.Id and v.Slot == self.Params.pos then
                            return math.maxinteger
                        end
                    else
                        if s.Id == skillInfo.Id then
                            return math.maxinteger
                        end
                    end
                end
            end

            return skillInfo.Id
        end

        table.sort(list, function (a, b)
            local aWeight = getWeight(a)
            local bWeight = getWeight(b)

            return aWeight < bWeight
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