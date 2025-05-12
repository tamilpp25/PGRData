--============================================XUiGridKotodamaArtifactAffix============================
---@class XUiGridKotodamaArtifactAffix
---@field _Control XKotodamaActivityControl
local XUiGridKotodamaArtifactAffix = XClass(XUiNode, 'XUiGridKotodamaArtifactAffix')

function XUiGridKotodamaArtifactAffix:Refresh(affixId)
    local affixCfg = self._Control:GetArtifactAffixCfgById(affixId)
    if affixCfg then
        self.Name.text = affixCfg.Content
        self.Desc.text = XRoomSingleManager.GetEvenDesc(affixCfg.FightEventId)
    end
end

--============================================XUiPanelKotodamaArtifact============================
---@class XUiPanelKotodamaArtifact
---@field _Control XKotodamaActivityControl
local XUiPanelKotodamaArtifact = XClass(XUiNode, 'XUiPanelKotodamaArtifact')

function XUiPanelKotodamaArtifact:OnStart()
    self._AffixCtrls = {}
end

function XUiPanelKotodamaArtifact:OnEnable()
    self:Refresh()
end

function XUiPanelKotodamaArtifact:Refresh()
    local hasArtifact = self._Control:CheckHasArtifact()
    
    self.PanelArtifact.gameObject:SetActiveEx(hasArtifact)
    self.PanelArtifactCharacteristic.gameObject:SetActiveEx(hasArtifact)
    self.PanelArtifactEffect.gameObject:SetActiveEx(false)
    self.ImgEmpty.gameObject:SetActiveEx(not hasArtifact)
    
    if hasArtifact then
        local artifactData = self._Control:GetArtifactData()
        self.DescTxt.text = XUiHelper.FormatText(self._Control:GetClientConfigStringByKey('ArtifactBtnDescFormat'), self._Control:GetArtifactFullDesc())
        self.ArtifactName.text = self._Control:GetArtifactNameById(artifactData.ArtifactId)
        self.ArtifactDesc.text = self._Control:GetArtifactDescById(artifactData.ArtifactId)
        -- 读取组合Id遍历词缀显示
        local composeId = self._Control:GetArtifactComposeId()
        if XTool.IsNumberValid(composeId) then
            local composeCfg = self._Control:GetArtifactComposeCfgById(composeId)
            if composeCfg and not XTool.IsTableEmpty(composeCfg.ArtifactAffixIds) then
                self.PanelArtifactEffect.gameObject:SetActiveEx(true)
                for i, v in ipairs(composeCfg.ArtifactAffixIds) do
                    if self._AffixCtrls[i] then
                        self._AffixCtrls[i]:Open()
                        self._AffixCtrls[i]:Refresh(v)    
                    elseif self['PanelAffix'..i] then
                        self._AffixCtrls[i] = XUiGridKotodamaArtifactAffix.New(self['PanelAffix'..i], self)
                        self._AffixCtrls[i]:Open()
                        self._AffixCtrls[i]:Refresh(v)
                    end
                end
                -- 隐藏掉多余的词缀UI
                for i = #composeCfg.ArtifactAffixIds + 1, 10 do
                    if self._AffixCtrls[i] then
                        self._AffixCtrls[i]:Close()
                    elseif self['PanelAffix'..i] then
                        self['PanelAffix'..i].gameObject:SetActiveEx(false)
                    else
                        break
                    end
                end
            end
        end
    end
end

return XUiPanelKotodamaArtifact