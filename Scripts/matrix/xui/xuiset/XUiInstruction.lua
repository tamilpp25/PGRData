local XUiInstruction = XClass(nil, "XUiInstruction")

function XUiInstruction:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

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
    self:Init()
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
            local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
            if stageInfo then
                if stageInfo.Type == XDataCenter.FubenManager.StageType.TaikoMaster then
                    characterId = XTaikoMasterConfigs.GetCharacterIdByNpcId(templateId) or characterId
                elseif stageInfo.Type == XDataCenter.FubenManager.StageType.MoeWarParkour
                    or stageInfo.Type == XDataCenter.FubenManager.StageType.Maze
                then
                    characterId = XCharacterCuteConfig.GetCharacterIdByNpcId(templateId) or characterId
                end
            end
            --endregion
            self.Core[i] = XCharacterConfigs.GetCharTeachIconById(characterId)
            self.CoreHeadLine[i] = XCharacterConfigs.GetCharTeachHeadLineById(characterId)
            self.CoreDescription[i] = XCharacterConfigs.GetCharTeachDescriptionById(characterId)
            local iconPath = npc.Template.HeadImageName
            -- 兼容黑幕模式
            if npc.Fight.IsFubenDebug and npc.RLNpc then
                local template = npc.RLNpc:GetUiResTemplate();
                iconPath = template and template.HeadImageName or "";
            elseif npc.FightNpcData ~= nil then
                iconPath = XDataCenter.CharacterManager.GetFightCharHeadIcon(npc.FightNpcData.Character, characterId)
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
    self.GameObject:SetActive(true)
end

function XUiInstruction:HidePanel()
    self.IsShow = false
    self.GameObject:SetActive(false)
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