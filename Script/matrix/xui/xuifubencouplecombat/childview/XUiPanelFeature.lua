--编队的特性图标控件
local XUiPanelFeature = XClass(nil, "XUiPanelFeature")

function XUiPanelFeature:Ctor(uiRoot, ui)
    self.UiRoot = uiRoot
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
    self:InitUi()
end

function XUiPanelFeature:InitUi()
    self.GameObject:SetActiveEx(true)
    self.PanelFeature = self.Transform:Find("PanelFeature")
    self.GridFeature = self.Transform:Find("PanelFeature/GridFeature")
    self.GridFeature.gameObject:SetActiveEx(false)
    self.GridFeatureList = {}
end

function XUiPanelFeature:Refresh(featureList, matchDic, characterId)
    if featureList and matchDic then
        self.GameObject:SetActiveEx(true)
    else
        self.GameObject:SetActiveEx(false)
        return
    end
    
    self.CharacterId = characterId
    self.FeatureList = featureList

    for i, v in ipairs(featureList) do
        local item = self.GridFeatureList[i]

        if not item then
            item = CS.UnityEngine.Object.Instantiate(self.GridFeature, self.PanelFeature)  -- 复制一个item
            self.GridFeatureList[i] = item
            --CsXUiHelper.RegisterClickEvent(item:Find("BgNormal"):GetComponent("Image"), function() self:ShowInfo() end)
            CsXUiHelper.RegisterClickEvent(item:Find("RImgIcon"):GetComponent("RawImage"), function() self:ShowInfo(i) end)
        end
        item.gameObject:SetActiveEx(true)
        local isActive = matchDic[v] and matchDic[v] > 0
        item:Find("BgNormal").gameObject:SetActiveEx(not isActive)
        item:Find("BgActive").gameObject:SetActiveEx(isActive)

        local icon = characterId and XFubenCoupleCombatConfig.GetCharacterIcon(characterId, i) or XFubenCoupleCombatConfig.GetFeatureIcon(v)
        local rImgIcon = item:Find("RImgIcon")
        if icon then
            rImgIcon:GetComponent("RawImage"):SetRawImage(icon)
        end
        rImgIcon.gameObject:SetActiveEx(icon and true or false)
    end
    for i = #featureList + 1, #self.GridFeatureList do
        self.GridFeatureList[i].gameObject:SetActiveEx(false)
    end

    self.GridFeature.gameObject:SetActiveEx(false)
end

function XUiPanelFeature:ShowInfo(index)
    local characterId = self.CharacterId
    local featureId = self.FeatureList[index]
    local name = characterId and XFubenCoupleCombatConfig.GetCharacterName(characterId, index) or XFubenCoupleCombatConfig.GetFeatureName(featureId)
    local desc = characterId and XFubenCoupleCombatConfig.GetCharacterDescription(characterId, index) or XFubenCoupleCombatConfig.GetFeatureDescription(featureId)
    XUiManager.UiFubenDialogTip(name, desc)
end

function XUiPanelFeature:OnDisable()
end

return XUiPanelFeature