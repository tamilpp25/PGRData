
local XUiEquipGuideItemInfo = XLuaUiManager.Register(XLuaUi, "UiEquipGuideItemInfo")

function XUiEquipGuideItemInfo:OnAwake()
    self:InitCb()
end 

function XUiEquipGuideItemInfo:OnStart(templateId, equipType)
    self.Id = templateId
    self.EquipType = equipType
    self:InitView()
end 

function XUiEquipGuideItemInfo:InitCb()
    self:RegisterClickEvent(self.BtnClose, self.Close)
    self.BtnGet.CallBack = function() self:OnBtnGetClick() end
end 

function XUiEquipGuideItemInfo:InitView()
    self.PanelAwarenessSkillDes.gameObject:SetActiveEx(self.EquipType == XEquipGuideConfigs.EquipType.Suit)
    self.PanelWeapon.gameObject:SetActiveEx(self.EquipType == XEquipGuideConfigs.EquipType.Weapon)
    
    if self.EquipType == XEquipGuideConfigs.EquipType.Weapon then  --武器
        self.RImgIcon:SetRawImage(XDataCenter.EquipManager.GetEquipIconPath(self.Id))
        self.TxtName.text = XDataCenter.EquipManager.GetEquipName(self.Id)
        local weaponTemplate = XEquipConfig.GetEquipCfg(self.Id)
        local skillTemplate = XEquipConfig.GetWeaponSkillTemplate(weaponTemplate.WeaponSkillId)
        self.TemplateId = self.Id
        self:RefreshTemplateGrids({self.GridWeaponDes}, {skillTemplate}, nil, nil, "GridWeaponDesc",
                function(grid, tmp)
                    grid.TxtWeaponDes.text = tmp.Description
                    grid.TxtDescription.text = tmp.Name
                end
        )
        self.TxtType.text = XArchiveConfigs.GetWeaponGroupName(XDataCenter.EquipManager.GetEquipTypeByTemplateId(self.Id))
        self.ImgQuality:SetSprite(XDataCenter.EquipManager.GetEquipQualityPath(self.Id))
    elseif self.EquipType == XEquipGuideConfigs.EquipType.Suit then --意识
        local template = XEquipConfig.GetEquipSuitCfg(self.Id)
        self.RImgIcon:SetRawImage(template.IconPath)
        self.TxtName.text = template.Name
        local skillData = XDataCenter.EquipManager.GetSuitActiveSkillDesList(self.Id, XEquipConfig.MAX_SUIT_COUNT)
        self:RefreshTemplateGrids(self.GridSkillDes, skillData, self.SkillPaneContent, nil, "GridSkillDes",
                function(grid, tmp)
                    grid.TxtSkillDes.text = tmp.SkillDes
                    grid.TxtDescription.text = tmp.PosDes
                end
        )
        self.TxtType.text = template.Description
        --意识套装第一个
        self.TemplateId = XEquipConfig.GetEquipTemplateIdsBySuitId(self.Id)[1]
        self.ImgQuality:SetSprite(XDataCenter.EquipManager.GetEquipQualityPath(self.TemplateId))
    end
    
end 

function XUiEquipGuideItemInfo:OnBtnGetClick()
    if not XTool.IsNumberValid(self.TemplateId) then
        return
    end
    local data = XEquipGuideConfigs.GeneratorEquipSkipData(self.TemplateId)
    XLuaUiManager.Open("UiEquipStrengthenSkip", data)
end 