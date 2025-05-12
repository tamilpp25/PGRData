---@class XUiInstruction : XUiNode
local XUiInstruction = XClass(XUiNode, "XUiInstruction")

function XUiInstruction:OnStart()
    self.Npc = { self.Npc1, self.Npc2, self.Npc3 }
    self.TogPortrait = { self.TogPortrait1, self.TogPortrait2, self.TogPortrait3 }
    self.PanelNpc:Init(self.Npc, function(index) self:OnPanelNpc(index) end)
    
    self.TxtSkillName.gameObject:SetActiveEx(false)
    self.TxtSkillbrief.gameObject:SetActiveEx(false)
    
    self.Core = {}
    self.CoreHeadLine = {}
    self.CoreDescription = {}

    self.CoreHeadLineGo = {}
    self.CoreDesGo = {}

    self.GridOwnDic = {}
    self.GridEnemyDic = {}
    self:Init()
end

function XUiInstruction:OnEnable()
    self:ShowPanel()
    self:RefreshPanelAffix()
end

function XUiInstruction:OnDisable()
    self:HidePanel()
end

function XUiInstruction:RefreshPanelAffix()
    local fight = CS.XFight.Instance
    if not fight then
        return
    end

    local uiAffix = fight.UiManager:GetUi(typeof(CS.XUiFightAffix))
    if not uiAffix then
        return
    end

    local selfAffixList = uiAffix:DoGetSelfUiAffixes()
    local enemyAffixList = uiAffix:DoGetEnemyUiAffixes()

    selfAffixList = XTool.CsList2LuaTable(selfAffixList)
    enemyAffixList = XTool.CsList2LuaTable(enemyAffixList)

    local selfAffixListFinal = {}
    for k, v in pairs(selfAffixList) do
        if v.AffixData.IsTrigger then
            table.insert(selfAffixListFinal, v)
        end
    end

    local enemyAffixListFinal = {}
    for k, v in pairs(enemyAffixList) do
        if v.AffixData.IsTrigger then
            table.insert(enemyAffixListFinal, v)
        end
    end

    local isSelfEmpty = XTool.IsTableEmpty(selfAffixListFinal)
    self.PanelNoneOwn.gameObject:SetActiveEx(isSelfEmpty)
    
    local isEnemyEmpty = XTool.IsTableEmpty(enemyAffixListFinal)
    self.PanelNoneEnemy.gameObject:SetActiveEx(isEnemyEmpty)

    local XGridAffix = require("XUi/XUiSet/ChildItem/XGridAffix")
    for k, data in pairs(selfAffixListFinal) do
        local grid = self.GridOwnDic[k]
        if not grid then
            local uiGo = XUiHelper.Instantiate(self.PanelDataOwn, self.PanelDataOwn.parent)
            uiGo.gameObject:SetActiveEx(false)
            grid = XGridAffix.New(uiGo, self)
            self.GridOwnDic[k] = grid
        end
        if self.PanelAffix.gameObject.activeSelf then
            grid:Open()
        else
            grid:Close()
        end
        grid:Refresh(data)
    end

    for k, data in pairs(enemyAffixListFinal) do
        local grid = self.GridEnemyDic[k]
        if not grid then
            local uiGo = XUiHelper.Instantiate(self.PanelDataEnemy, self.PanelDataEnemy.parent)
            uiGo.gameObject:SetActiveEx(false)
            grid = XGridAffix.New(uiGo, self)
            self.GridEnemyDic[k] = grid
        end
        if self.PanelAffix.gameObject.activeSelf then
            grid:Open()
        else
            grid:Close()
        end
        grid:Refresh(data)
    end

    self.PanelDataOwn.gameObject:SetActiveEx(false)
    self.PanelDataEnemy.gameObject:SetActiveEx(false)
end

function XUiInstruction:Init()
    local role = CS.XFight.GetActivateClientRole()
    local firstIndex = role.Npc and (role.Npc.Index + 1) or 1
    local firstHasNpc = role:GetNpc(firstIndex - 1)
    if not firstHasNpc then
        firstIndex = nil
    end
    
    for i = 1, 3 do
        local hasNpc, npc = role:GetNpc(i - 1)
        if not hasNpc then
            self.Npc[i].gameObject:SetActiveEx(false)
        else
            local templateId = npc.TemplateId
            local characterId = math.floor(templateId / 10)
            --region 将Q版机器人id转回普通角色id
            local stageId = CS.XFight.Instance.FightData.StageId
            ---@type XFubenAgency
            local fubenAgency = XMVCA:GetAgency(ModuleId.XFuben)
            if fubenAgency:IsStageCute(stageId) then
                characterId = XCharacterCuteConfig.GetCharacterIdByNpcId(templateId) or characterId
            end
            --endregion
            self.Core[i] = XMVCA.XCharacter:GetCharTeachIconById(characterId)
            self.CoreHeadLine[i] = XMVCA.XCharacter:GetCharTeachHeadLineById(characterId)
            self.CoreDescription[i] = XMVCA.XCharacter:GetCharTeachDescriptionById(characterId)
            local iconPath = npc.Template.HeadImageName
            -- 兼容黑幕模式
            if npc.Fight and npc.Fight.IsFubenDebug and npc.RLNpc then
                local template = npc.RLNpc:GetUiResTemplate();
                iconPath = template and template.HeadImageName or "";
            elseif npc.FightNpcData ~= nil then
                iconPath = XMVCA.XCharacter:GetFightCharHeadIcon(npc.FightNpcData.Character, characterId)
            end
            self.TogPortrait[i]:SetSprite(iconPath)

            firstIndex = firstIndex or i
        end
    end
    self.PanelNpc:SelectIndex(firstIndex or 1)
end

function XUiInstruction:OnPanelNpc(index)
    self.ImgCoreSkill:SetRawImage(self.Core[index])

    for _, go in pairs(self.CoreHeadLineGo) do
        go:SetActiveEx(false)
    end
    for _, go in pairs(self.CoreDesGo) do
        go:SetActiveEx(false)
    end
    for i, message in pairs(self.CoreDescription[index] or {}) do
        local headLine = self.CoreHeadLine[index][i]
        if headLine then
            self:SetTextInfo(self.TxtSkillName.gameObject, self.CoreHeadLineGo, i, headLine)
        end
        self:SetTextInfo(self.TxtSkillbrief.gameObject, self.CoreDesGo, i, message)
    end
end

function XUiInstruction:SetTextInfo(targetGo, txtGo, i, info)
    local go = txtGo[i]
    if not go then
        go = XUiHelper.Instantiate(targetGo, self.PanelReward)
        txtGo[i] = go
    end
    go:SetActiveEx(true)
    local goTxt = go:GetComponent("Text")
    goTxt.text = XUiHelper.ConvertLineBreakSymbol(info)
    go.transform:SetAsLastSibling()
end

function XUiInstruction:ShowPanel()
    self.IsShow = true
end

function XUiInstruction:HidePanel()
    self.IsShow = false
end

function XUiInstruction:CheckDataIsChange()

    return false
end

function XUiInstruction:SaveChange()

end

function XUiInstruction:CancelChange()

end

function XUiInstruction:ResetToDefault()

end

return XUiInstruction