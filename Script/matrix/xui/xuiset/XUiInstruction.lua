local XUiInstruction = XClass(nil, "XUiInstruction")

function XUiInstruction:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.Npc = { self.Npc1, self.Npc2, self.Npc3 }
    self.TogPortrait = { self.TogPortrait1, self.TogPortrait2, self.TogPortrait3 }
    self.PanelNpc:Init(self.Npc, function(index) self:OnPanelNpc(index) end)
    self.Core = {}
    self.CoreDescription = {}
    self:Init()
end

function XUiInstruction:Init()
    local role = CS.XFight.GetActivateClientRole()
    local firstIndex = role.Captain and (role.Captain.Index + 1) or 1
    for i = 1, 3 do
        local hasNpc, npc = role:GetNpc(i - 1)
        if not hasNpc then
            self.Npc[i].gameObject:SetActiveEx(false)
        else
            local templateId = npc.TemplateId
            local characterId = math.floor(templateId / 10)
            --region 音游 将小人id转回普通角色id
            local stageId = CS.XFight.Instance.FightData.StageId
            local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
            if stageInfo and stageInfo.Type == XDataCenter.FubenManager.StageType.TaikoMaster then        
                characterId = XTaikoMasterConfigs.GetCharacterIdByNpcId(templateId) or characterId
            elseif stageInfo and stageInfo.Type == XDataCenter.FubenManager.StageType.MoeWarParkour then
                characterId = XFubenSpecialTrainConfig.GetCharacterIdByNpcId(templateId) or characterId
            end
            --endregion
            self.Core[i] = XCharacterConfigs.GetCharTeachIconById(characterId)
            self.CoreDescription[i] = XCharacterConfigs.GetCharTeachDescriptionById(characterId)
            local iconPath = npc.Template.HeadImageName
            -- 兼容黑幕模式
            if npc.Fight.IsFubenDebug and npc.RLNpc then
                local template = npc.RLNpc:GetUiResTemplate();
                iconPath = template and template.HeadImageName or "";
            elseif npc.FightNpcData ~= nil then
                iconPath = XDataCenter.CharacterManager.GetFightCharHeadIcon(npc.FightNpcData.Character)
            end
            self.TogPortrait[i]:SetSprite(iconPath)
        end
    end
    self.PanelNpc:SelectIndex(firstIndex)
end

function XUiInstruction:OnPanelNpc(index)
    self.ImgCoreSkill:SetRawImage(self.Core[index])
    self.TxtCoreDescription.text = self.CoreDescription[index]
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