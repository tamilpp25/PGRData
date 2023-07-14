local XGridNieRUpLvDetail = XClass(nil, "XGridNieRUpLvDetail")
local TIME_TWEEN = 1.5

function XGridNieRUpLvDetail:Ctor(rootUi, ui)
    self.RootUi = rootUi
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    
end

function XGridNieRUpLvDetail:UpdateInfo(data)
    local nierCharacter = XDataCenter.NieRManager.GetNieRCharacterByCharacterId(data.Id)
    local characterId = nierCharacter:GetRobotCharacterId()
    local charConfig = XCharacterConfigs.GetCharacterTemplate(characterId)
    local nameStr = nierCharacter:GetNieRCharName()
    
    self.TxtName.text = nameStr
    local fashionId = nierCharacter:GetNieRFashionId()
    self.RawImage:SetRawImage(XDataCenter.FashionManager.GetFashionHalfBodyImage(fashionId))
    self.TxtLevel.text = data.OldLevel

    local itemId = data.Item.TemplateId
    local itemCount = data.Item.Count

    self.RImgIcon:SetRawImage(XDataCenter.ItemManager.GetItemBigIcon(itemId))
    XUiHelper.SetQualityIcon(self.RootUi, self.ImgQuality, XDataCenter.ItemManager.GetItemQuality(itemId))

    self.TxtUpLvCavansGroup.alpha = 0
    if data.IsOldMaxLevel then
        self.TxtExpNow.text = ""
        self.TxtExpALL.text = "Max"
        self.ImgExpBar.fillAmount = 1
        self.TxtCount.text = "+" .. itemCount
    else
        local newLevel = nierCharacter:GetNieRCharacterLevel()
        local newExp = nierCharacter:GetNieRCharacterExp()
        local oldMaxExp = data.OldMaxExp
        local newMaxExp = nierCharacter:GetNieRCharacterMaxExp()
        local changeExp
        local changeCount
        if data.OldLevel < newLevel then
            changeExp = oldMaxExp - data.OldExp
        else
            changeExp = newExp - data.OldExp
        end
        self.TxtExpALL.text = "/" .. oldMaxExp
        XUiHelper.Tween(TIME_TWEEN, function(f)
            if XTool.UObjIsNil(self.Transform) then
                return
            end
            local tmpChangeExp = math.floor(f * changeExp)
            local tmpPercent = (data.OldExp + tmpChangeExp) / oldMaxExp

            self.TxtExpNow.text = tmpChangeExp
            self.ImgExpBar.fillAmount = tmpPercent
            self.TxtCount.text = "+" .. tmpChangeExp
        end, function()
            if XTool.UObjIsNil(self.Transform) then
                return
            end
            local isMaxLevel = nierCharacter:CheckNieRCharacterMaxLevel()
            if data.OldLevel < newLevel then
                self.LevelUpEnable.gameObject:PlayTimelineAnimation(function()
                    self.LevelUpDisable.gameObject:PlayTimelineAnimation(function()
                    end)
                end)
            end
            if isMaxLevel then
                self.TxtLevel.text = newLevel
                self.TxtExpNow.text = ""
                self.TxtExpALL.text = "Max"
                self.ImgExpBar.fillAmount = 1
                self.TxtCount.text = "+" .. itemCount
            else
                self.TxtLevel.text = newLevel
                self.TxtExpNow.text = newExp
                self.TxtExpALL.text = "/" .. newMaxExp
                self.ImgExpBar.fillAmount = newExp / newMaxExp
                self.TxtCount.text = "+" .. itemCount
                
            end
        end)
    end



end


return XGridNieRUpLvDetail