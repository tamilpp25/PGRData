-- v1.32 角色特性标识
--====================================================================
local XGridFeature  = XClass(nil, "XGridFeature")

function XGridFeature:Ctor(ui, clickCB)
    self.Ui = ui
    self:InitUiObj(ui)
    self:AddClickListener(clickCB)
end

function XGridFeature:InitUiObj(ui)
    XUiHelper.InitUiClass(self, ui)
    if self:IsInBattleRoom() then
        self.RImgIcon = self.Transform:Find("RImgIcon"):GetComponent("RawImage")
        self.BgNormal = self.Transform:Find("BgNormal")
        self.BgActive = self.Transform:Find("BgActive")
    end
end

function XGridFeature:AddClickListener(clickCB)
    if clickCB then
        XUiHelper.RegisterClickEvent(self, self.RImgIcon, clickCB)
        if not self:IsInBattleRoom() then
            XUiHelper.RegisterClickEvent(self, self.RImgIconActive, clickCB)
        end
    end
end

function XGridFeature:RefreshIcon(icon)
    if icon then
        self.RImgIcon:SetRawImage(icon)
        if not self:IsInBattleRoom() then
            self.RImgIconActive:SetRawImage(icon)
        end
    end
    self.RImgIcon.gameObject:SetActiveEx(icon and true or false)
    if not self:IsInBattleRoom() then
        self.RImgIconActive.gameObject:SetActiveEx(icon and true or false)
    end
end

function XGridFeature:SetActive(isActive)
    if self:IsInBattleRoom() then
        self.BgNormal.gameObject:SetActiveEx(not isActive)
        self.BgActive.gameObject:SetActiveEx(isActive)
    else
        self.GameObject:SetActiveEx(true)
        self.Inactive.gameObject:SetActiveEx(not isActive)
        self.TheActivation.gameObject:SetActiveEx(isActive)
    end
end

-- 队伍房间和选角用同一个脚本，所以分两套
function XGridFeature:IsInBattleRoom()
    return XTool.UObjIsNil(self.Inactive)
end

function XGridFeature:SetOpen(isActive)
    self.GameObject:SetActiveEx(isActive)
end

--====================================================================


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
            self.GridFeatureList[i] = XGridFeature.New(item, function() self:ShowInfo(i) end)
        end
        local icon = characterId and XFubenCoupleCombatConfig.GetCharacterIcon(characterId, i) or XFubenCoupleCombatConfig.GetFeatureIcon(v)
        local isActive = matchDic[v] and matchDic[v] > 0
        self.GridFeatureList[i]:RefreshIcon(icon)
        self.GridFeatureList[i]:SetActive(isActive)
        self.GridFeatureList[i]:SetOpen(true)
    end
    -- 多余标识隐藏
    for i = #featureList + 1, #self.GridFeatureList do
        self.GridFeatureList[i]:SetOpen(false)
    end
    -- Item模板隐藏
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