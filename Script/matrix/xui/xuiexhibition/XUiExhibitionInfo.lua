local XUiExhibitionInfo = XLuaUiManager.Register(XLuaUi, "UiExhibitionInfo")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local XUiPanelExhibitionNormalInfo = require("XUi/XUiExhibition/XUiPanelExhibitionNormalInfo") -- 普通解放数据面板
local XUiPanelExhibitionSuperInfo = require("XUi/XUiExhibition/XUiPanelExhibitionSuperInfo") -- 超解数据面板

local TabIndexToGrowUpLevel = {
    XEnumConst.CHARACTER.GrowUpLevel.Lower,
    XEnumConst.CHARACTER.GrowUpLevel.Middle,
    XEnumConst.CHARACTER.GrowUpLevel.Higher,
    XEnumConst.CHARACTER.GrowUpLevel.Super,
}

-- index 1-3 普通解放
-- index 4 超解
local PanelIndexDic = 
{
    [1] = "PanelExhibitionNormalInfo",
    [2] = "PanelExhibitionNormalInfo",
    [3] = "PanelExhibitionNormalInfo",
    [4] = "PanelExhibitionSuperInfo"
}

function XUiExhibitionInfo:OnAwake()
    self.GridRewardItem.gameObject:SetActive(false)
    self:InitListener()
    self:InitPanel()
end

function XUiExhibitionInfo:InitPanel()
    self.PanelExhibitionNormalInfo = XUiPanelExhibitionNormalInfo.New(self.PanelCharacterTaskNormal, self)
    self.PanelExhibitionSuperInfo = XUiPanelExhibitionSuperInfo.New(self.PanelCharacterTaskSuper, self)
end

function XUiExhibitionInfo:OnStart(characterId, showType)
    self.CharacterId = characterId
    self.ShowType = showType or XDataCenter.ExhibitionManager.ExhibitionType.STRUCT
    self:InitModelRoot()
    self:InitTabBtnGroup()
    self:RegisterRedPointEvent()
end

function XUiExhibitionInfo:OnEnable()
    CS.XGraphicManager.UseUiLightDir = true
    self:UpdateView()
end

function XUiExhibitionInfo:OnDisable()
    CS.XGraphicManager.UseUiLightDir = false
end

function XUiExhibitionInfo:InitModelRoot()
    local root = self.UiModelGo
    self.PanelRoleModel = root:FindTransform("PanelRoleModel")
    self.EffectHuanren1 = root:FindTransform("ImgEffectHuanren1")
    self.EffectHuanren = root:FindTransform("ImgEffectHuanren")
    self.EffectHuanren.gameObject:SetActiveEx(false)
    self.EffectHuanren1.gameObject:SetActiveEx(false)
    self.RoleModelPanel = XUiPanelRoleModel.New(self.PanelRoleModel, self.Name, nil, true, nil, true)
end

function XUiExhibitionInfo:InitListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    -- self.BtnBreak.CallBack = function() self:OnBtnBreakClick() end
    self.BtnShowInfoToggle.CallBack = function(value) self:OnBtnShowInfoToggleClick(value) end
end

function XUiExhibitionInfo:RegisterRedPointEvent()
    local characterId = self.CharacterId
    self:AddRedPointEvent(self.BtnTog1, self.OnCheckExhibitionRedPoint, self, { XRedPointConditions.Types.CONDITION_EXHIBITION_NEW }, { characterId, 1 })
    self:AddRedPointEvent(self.BtnTog2, self.OnCheckExhibitionRedPoint, self, { XRedPointConditions.Types.CONDITION_EXHIBITION_NEW }, { characterId, 2 })
    self:AddRedPointEvent(self.BtnTog3, self.OnCheckExhibitionRedPoint, self, { XRedPointConditions.Types.CONDITION_EXHIBITION_NEW }, { characterId, 3 })
    self:AddRedPointEvent(self.BtnTog4, self.OnCheckExhibitionRedPoint, self, { XRedPointConditions.Types.CONDITION_EXHIBITION_NEW }, { characterId, 4 })
end

function XUiExhibitionInfo:OnCheckExhibitionRedPoint(count, args)
    local characterId = args[1]
    local index = args[2]
    local growUpLevel = XDataCenter.ExhibitionManager.GetCharacterGrowUpLevel(characterId, true)
    self["BtnTog" .. index]:ShowReddot(count >= 0 and growUpLevel == index)
end

function XUiExhibitionInfo:InitTabBtnGroup()
    local tabGroup = {
        self.BtnTog1,
        self.BtnTog2,
        self.BtnTog3,
        self.BtnTog4,
    }
    self.PanelTogs:Init(tabGroup, function(tabIndex) self:OnClickTabCallBack(tabIndex) end)
    self:AutoSelectLastGrowUpLevel()
end

-- 自动选择最高一级可解放的选项
function XUiExhibitionInfo:AutoSelectLastGrowUpLevel()
    local selected = false
    local lastIndex = 0
    local growUpLevel = XDataCenter.ExhibitionManager.GetCharacterGrowUpLevel(self.CharacterId, true)
    for index, level in pairs(TabIndexToGrowUpLevel) do
        if level == growUpLevel + 1 then
            self.PanelTogs:SelectIndex(index)
            selected = true
            break
        end
        lastIndex = index
    end
    if not selected then
        self.PanelTogs:SelectIndex(lastIndex)
    end
end

function XUiExhibitionInfo:OnClickTabCallBack(tabIndex)
    self.SelectedIndex = tabIndex

    self:UpdateView()
    self:PlayAnimation("ExhibitionTaskQiehuan")
end

function XUiExhibitionInfo:UpdateView()
    if not self.SelectedIndex then
        return
    end

    self.BtnShowInfoToggle:SetButtonState(XUiButtonState.Select)
    self:UpdateCharacterInfo()
    self:UpdateCharacterModel(TabIndexToGrowUpLevel[self.SelectedIndex])
    self:UpdateBtnState()

    -- index 1-3 普通解放
    for k, v in pairs(PanelIndexDic) do
        local panelName = PanelIndexDic[k]
        self[panelName]:Hide()
    end
    local panelName = PanelIndexDic[self.SelectedIndex]
    local targetPanel = self[panelName]
    local taskConfig = XExhibitionConfigs.GetCharacterGrowUpTask(self.CharacterId, TabIndexToGrowUpLevel[self.SelectedIndex])
    targetPanel:Refresh(self.CharacterId, taskConfig)
    targetPanel:Show()
end

function XUiExhibitionInfo:UpdateBtnState()
    local growUpLevel = XDataCenter.ExhibitionManager.GetCharacterGrowUpLevel(self.CharacterId, true)
    for index, level in pairs(TabIndexToGrowUpLevel) do
        self["BtnTog"..index]:ShowTag(level == growUpLevel)
    end
end

function XUiExhibitionInfo:UpdateCharacterInfo()
    local characterId = self.CharacterId
    self.TxtName.text = XMVCA.XCharacter:GetCharacterName(characterId)
    self.TxtNameHorizontal.text = XMVCA.XCharacter:GetCharacterName(characterId)
    self.TxtType.text = XMVCA.XCharacter:GetCharacterTradeName(characterId)
    self.TxtNumber.text = XMVCA.XCharacter:GetCharacterCodeStr(characterId)

    local detailConfig = XMVCA.XCharacter:GetCharDetailTemplate(characterId)
    local isShowHorText = detailConfig.LiberationShowType
    self.TxtNameHorizontal.gameObject:SetActiveEx(isShowHorText)
    self.TxtName.gameObject:SetActiveEx(not isShowHorText)

    -- 解放标签改到按钮下方了
    -- local growUpLevel = XDataCenter.ExhibitionManager.GetCharacterGrowUpLevel(characterId, true)
    -- local levelIcon = XExhibitionConfigs.GetExhibitionLevelIconByLevel(growUpLevel)
    -- if not levelIcon or levelIcon == "" then
    --     self.ImgClassIcon.gameObject:SetActive(false)
    -- else
    --     self:SetUiSprite(self.ImgClassIcon, levelIcon)
    --     self.ImgClassIcon.gameObject:SetActive(true)
    -- end
end

function XUiExhibitionInfo:UpdateCharacterModel(growUpLevel)
    local characterId = self.CharacterId
    growUpLevel = growUpLevel or XDataCenter.ExhibitionManager.GetCharacterGrowUpLevel(characterId, true)
    local modelId = XMVCA.XCharacter:GetCharLiberationLevelModelId(characterId, growUpLevel)

    self.RoleModelPanel:UpdateCharacterModelByModelId(modelId, characterId, self.PanelRoleModel, XModelManager.MODEL_UINAME.XUiExhibitionInfo, function(model)
        self.PanelDrag.Target = model.transform
        self.EffectHuanren.gameObject:SetActiveEx(false)
        self.EffectHuanren1.gameObject:SetActiveEx(false)
        if XMVCA.XCharacter:GetIsIsomer(characterId) then
            self.EffectHuanren1.gameObject:SetActiveEx(true)
        else
            self.EffectHuanren.gameObject:SetActiveEx(true)
        end
    end, growUpLevel, true)
end

function XUiExhibitionInfo:OnBtnBackClick()
    self:Close()
end

function XUiExhibitionInfo:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiExhibitionInfo:OnBtnBreakClick()
    local characterId = self.CharacterId
    local curSelectLevel = TabIndexToGrowUpLevel[self.SelectedIndex]
    local growUpLevel = XDataCenter.ExhibitionManager.GetCharacterGrowUpLevel(characterId, true)
    if curSelectLevel ~= growUpLevel + 1 then
        XUiManager.TipText("CharacterLiberateShouldFollowOrder")
        return
    end

    XDataCenter.ExhibitionManager.GetGatherReward(characterId, curSelectLevel, function()
        CS.XAudioManager.PlaySound(XSoundManager.UiBasicsMusic.UiCharacter_Liberation)
        self:AutoSelectLastGrowUpLevel()
    end)
end

function XUiExhibitionInfo:OnBtnShowInfoToggleClick(value)
    local growUpLevel = value == XUiButtonState.Press and TabIndexToGrowUpLevel[self.SelectedIndex]
    self:UpdateCharacterModel(growUpLevel)
end

return XUiExhibitionInfo