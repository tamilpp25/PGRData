local XUiGridCharacterIcon = XClass(nil, "XUiGridCharacterIcon")

function XUiGridCharacterIcon:Ctor(RootUI, index, uiIcon, exhibitionCfg)
    self.RootUI = RootUI
    self.Index = index
    self.GameObject = uiIcon.gameObject
    self.Transform = uiIcon.transform
    self.Behaviour = self.GameObject:AddComponent(typeof(CS.XLuaBehaviour))
    XTool.InitUiObject(self)
    self:Refresh(exhibitionCfg)
    self:AddBtnListener()
end

function XUiGridCharacterIcon:Refresh(exhibitionCfg)
    self.CharacterId = exhibitionCfg and exhibitionCfg.CharacterId or 0
    self.RImgIcon:SetRawImage(XDataCenter.ExhibitionManager.GetCharHeadPortrait(self.CharacterId, true))
    if self.CharacterId == nil or self.CharacterId == 0 then
        self.ImgMask.gameObject:SetActive(false)
        self.LevelPanel.gameObject:SetActive(false)
        self.ImgRedPoint.gameObject:SetActive(false)
        --local levelConfig = XExhibitionConfigs.GetExhibitionGrowUpLevelConfig(XCharacterConfigs.GrowUpLevel.New)
        --self.RootUI:SetUiSprite(self.ImgIconFrame, levelConfig.IconFrame)
    elseif self:IsOwnCharacter(self.CharacterId) then
        self.ImgMask.gameObject:SetActive(false)
        local growUpLevel = XDataCenter.ExhibitionManager.GetCharacterGrowUpLevel(self.CharacterId, true)
        local levelConfig = XExhibitionConfigs.GetExhibitionGrowUpLevelConfig(growUpLevel)
        if growUpLevel == XCharacterConfigs.GrowUpLevel.New then
            self.LevelPanel.gameObject:SetActive(false)
            self.RootUI:SetUiSprite(self.ImgIconFrame, levelConfig.IconFrame)
        else
            self.RootUI:SetUiSprite(self.ImgLevel, levelConfig.LevelLogo)
            self.RootUI:SetUiSprite(self.ImgLevelFrame, levelConfig.LevelFrame)
            self.RootUI:SetUiSprite(self.ImgIconFrame, levelConfig.IconFrame)
            self.LevelPanel.gameObject:SetActive(true)
        end
        if self.RootUI.IsSelf then
            local showRedPoint = XDataCenter.ExhibitionManager.CheckNewRewardByCharacterId(self.CharacterId)
            self.ImgRedPoint.gameObject:SetActive(showRedPoint)
            if self.IsNew ~= showRedPoint then
                if self.IsNew ~= nil then
                    self.RootUI:CheckTabRedDot()
                end
                self.IsNew = showRedPoint
            end
        else
            self.ImgRedPoint.gameObject:SetActive(false)
        end
    else
        self.ImgMask.gameObject:SetActive(true)
        self.LevelPanel.gameObject:SetActive(false)
        self.ImgRedPoint.gameObject:SetActive(false)
    end
end

function XUiGridCharacterIcon:IsOwnCharacter(characterId)
    return XDataCenter.ExhibitionManager.CheckIsOwnCharacter(characterId, true)
end

function XUiGridCharacterIcon:AddBtnListener()
    self:RegisterClickEvent(self.BtnSelect, self.BtnSelectClick)
end

function XUiGridCharacterIcon:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiGridExhibition:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiGridExhibition:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiGridCharacterIcon:BtnSelectClick()
    if self.RootUI.IsSelf then
        if self.CharacterId == nil or self.CharacterId == 0 then
            XUiManager.TipText("ExhibitionUnknownCharacter")
        elseif XDataCenter.CharacterManager.IsOwnCharacter(self.CharacterId) then
            self.RootUI:StartFocus(self.Index, self.CharacterId)
        else
            XUiManager.TipText("ExhibitionNotObtainCharacter")
        end
    end
end

function XUiGridCharacterIcon:CharacterGrowUp()
    self.AnimCharacterIcon:Play()
    self.Behaviour.LuaUpdate = function() self:CheckAnimEnd() end
end

function XUiGridCharacterIcon:CheckAnimEnd()
    if self.AnimCharacterIcon.time > self.AnimCharacterIcon.duration / 2 then
        self:Refresh(self.CharacterId)
        self.Behaviour.LuaUpdate = nil
    end
end

return XUiGridCharacterIcon