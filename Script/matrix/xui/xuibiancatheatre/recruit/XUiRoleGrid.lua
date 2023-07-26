----------------羁绊格子--------------------
local XUiGridFeature = XClass(nil, "XUiGridFeature")

function XUiGridFeature:Ctor(ui)
    self.Transform = ui.transform
    self.GameObject = ui.gameObject
    XTool.InitUiObject(self)
    self.BgKuang = XUiHelper.TryGetComponent(self.Transform, "BgKuang")
    if self.BgKuang then
        self.BgKuang.gameObject:SetActiveEx(false)
    end
    XUiHelper.RegisterClickEvent(self, self.Button, function() self:OnButtonClick() end)
end

--combo：XTheatreCombo
function XUiGridFeature:Refresh(combo, isCurStepRecruit, roleId)
    if not combo then
        return
    end
    self.Combo = combo
    self.RImgIcon:SetRawImage(combo:GetIconPath())
    --背景颜色
    local isNextLevel = not isCurStepRecruit
    local color = combo:GetQualityColor(isNextLevel)
    if color then
        self.BgNormal.color = color
    end
    if self.BgKuang then
        local isRoleDecay = XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager():CheckRoleIsDecayByCharacterId(roleId)
        self.BgKuang.gameObject:SetActiveEx(combo:GetComboIsHaveDecay() and isRoleDecay)
    end
    self.GameObject:SetActiveEx(true)
end

function XUiGridFeature:OnButtonClick()
    XLuaUiManager.Open("UiBiancaTheatreComboTips", self.Combo)
end



--------------招募界面：招募角色的控件-------------------
local XUiRoleGrid = XClass(nil, "XUiRoleGrid")
local UiButtonState = CS.UiButtonState
local EFFECT_COUNT = 3

function XUiRoleGrid:Ctor(ui, modelPanel, rootUi, gridIndex)
    self.Transform = ui.transform
    self.GameObject = ui.gameObject
    XTool.InitUiObject(self)
    self.ModelPanel = modelPanel
    self.RootUi = rootUi
    self.GridIndex = gridIndex
    self.TxtName.text = ""
    self.GridFeatureList = {}
    self.AdventureManager = XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager()
    self.ComboList = XDataCenter.BiancaTheatreManager.GetComboList()
    local adventureChapter = self.AdventureManager:GetCurrentChapter()
    local curStep = adventureChapter:GetCurStep()
    self.IsDecay = curStep:GetStepType() == XBiancaTheatreConfigs.XStepType.DecayRecruitCharacter

    self.BtnRecruit.CallBack = function() self:OnBtnRecruitClick() end
    self.BtnRankUp.CallBack = function() self:OnBtnRecruitClick() end
    self.BtnCorruption.CallBack = function() self:OnBtnCorruptionClick() end
    self.BtnRecruit.gameObject:SetActiveEx(not self.IsDecay)
    self.BtnCorruption.gameObject:SetActiveEx(self.IsDecay)
    self.GridFeature.gameObject:SetActiveEx(false)
end

function XUiRoleGrid:Destroy()
    self.ModelPanel:RemoveRoleModelPool()
end

function XUiRoleGrid:RefreshDatas(adventureRole, playEffect)
    self.AdventureRole = adventureRole
    if not adventureRole then
        self.GameObject:SetActiveEx(false)
        self.ModelPanel:HideRoleModel()
        return
    end

    local adventureManager = self.AdventureManager
    local adventureChapter = adventureManager:GetCurrentChapter()
    local curStep = adventureChapter:GetCurStep()
    local baseCharacterId = adventureRole:GetBaseId()

    --角色名
    self.TxtName.text = adventureRole:GetRoleName()

    --是否已招募/升星
    local curRecruitRole = adventureManager:GetRoleByCharacterId(baseCharacterId)
    local isRecruit = curRecruitRole ~= nil
    local isCurStepRecruit = curStep:IsRecruitCharacter(baseCharacterId)
    if self.OverRecruit then
        self.OverRecruit.gameObject:SetActiveEx(isCurStepRecruit)
        if self.IsDecay then
            self.OverRecruit.transform:Find("Text"):GetComponent("Text").text = XBiancaTheatreConfigs.GetClientConfig("RecruitOverDecayTxt")
        end
    end

    --是否可招募
    local isCanRecruit = adventureChapter:GetRecruitCount() > 0
    self.BtnRecruit:SetDisable(not isCanRecruit, isCanRecruit)
    self.BtnCorruption:SetDisable(not isCanRecruit, isCanRecruit)
    self.BtnRankUp:SetDisable(not isCanRecruit, isCanRecruit)
    --是否可升星（已招募角色列表中存在该角色，且当前招募刷新列表中未被招募，则显示升星）
    self.IsShowRankUp = isRecruit and not isCurStepRecruit and not self.IsDecay
    self.BtnRecruit.gameObject:SetActiveEx(not isCurStepRecruit and not self.IsShowRankUp and not self.IsDecay)
    self.BtnRankUp.gameObject:SetActiveEx(not isCurStepRecruit and self.IsShowRankUp and not self.IsDecay)
    self.BtnCorruption.gameObject:SetActiveEx(not isCurStepRecruit and not self.IsShowRankUp and self.IsDecay)

    --羁绊星星数
    local level = adventureRole:GetLevel()
    local curRoleLevel = curRecruitRole and curRecruitRole:GetLevel() or 0
    self.TxtLevel.text = isCurStepRecruit and curRoleLevel or level + curRoleLevel 

    self:UpdateCombo(adventureRole:GetCharacterComboIds(), isCurStepRecruit, adventureRole:GetBaseId())
    self:UpdateRoleModel(adventureRole:GetCharacterId(), adventureRole:GetRawDataId(), playEffect)

    self.GameObject:SetActiveEx(true)
end

--更新羁绊图标
function XUiRoleGrid:UpdateCombo(childComboIds, isCurStepRecruit, roleId)
    local gridFeature
    local combo
    for i, childComboId in ipairs(childComboIds) do
        combo = self.ComboList:GetComboByComboId(childComboId)
        gridFeature = self.GridFeatureList[i]
        if not gridFeature then
            gridFeature = XUiGridFeature.New(XUiHelper.Instantiate(self.GridFeature, self.PanelFeature))
            self.GridFeatureList[i] = gridFeature
        end
        gridFeature:Refresh(combo, isCurStepRecruit, roleId)
    end
    for i = #childComboIds + 1, #self.GridFeatureList do
        self.GridFeatureList[i].GameObject:SetActiveEx(false)
    end
end

--更新模型
function XUiRoleGrid:UpdateRoleModel(charId, robotId, playEffect)
    if not charId or not robotId then return end
    self.GameObject:SetActiveEx(true)
    if not self.ShowEffect then
        self.ShowEffect = {}
        for i = 1, EFFECT_COUNT do
            self.ShowEffect[i] = self.ModelPanel.Transform:Find("ImgEffectHuanren" .. i)
        end
    end

    -- 腐化特效
    self.EffectCorruption = self.ModelPanel.Transform:Find("Effect")
    if not self.EffectCorruption then
        local effectUrl = XBiancaTheatreConfigs.GetDecayRoleEffect()
        self.EffectCorruption = CS.UnityEngine.GameObject("Effect")
        self.EffectCorruption.transform:SetParent(self.ModelPanel.Transform, false)
        self.EffectCorruption.gameObject:SetActiveEx(false)
        if not string.IsNilOrEmpty(effectUrl) then
            self.EffectCorruption:LoadPrefab(effectUrl)
        end
    end

    local quality = XRobotManager.GetRobotCharacterQuality(robotId)
    for i, v in ipairs(self.ShowEffect) do
        v.gameObject:SetActiveEx(false)
        if (i == quality or (i == #self.ShowEffect and quality >= i)) and playEffect then
            v.gameObject:SetActiveEx(true)
            local effectObj = v
            XScheduleManager.ScheduleOnce(function()
                if not XTool.UObjIsNil(effectObj) then
                    effectObj.gameObject:SetActiveEx(false)
                end
            end, XScheduleManager.SECOND)
        end
    end
    -- 腐化结束后如果模型隐藏就不再刷新模型
    if not self.ModelPanel.GameObject.activeSelf then
        return
    end
    self.ModelPanel:ShowRoleModel()
    local robotCfg = XRobotManager.GetRobotTemplate(robotId)
    self.ModelPanel:UpdateRobotModel(robotId, 
        charId, 
        nil, 
        robotCfg and robotCfg.FashionId, 
        robotCfg and robotCfg.WeaponId)
end

function XUiRoleGrid:OnBtnRecruitClick()
    self.RootUi:ShowTips(self.AdventureRole, false, self.IsShowRankUp)
end

function XUiRoleGrid:OnBtnCorruptionClick()
    self.RootUi:ShowTips(self.AdventureRole, false, self.IsShowRankUp, true)
end

function XUiRoleGrid:SetModelActive(active)
    if not self.AdventureRole then
        return
    end
    self.ModelPanel.GameObject:SetActiveEx(active)
end

-- 展示腐化特效
function XUiRoleGrid:ShowDecayEffect()
    if self.EffectCorruption then
        self.EffectCorruption.gameObject:SetActiveEx(false)
        self.EffectCorruption.gameObject:SetActiveEx(true)
    end
end

-- 模型换位：用于腐化时在Ui层将被腐化的角色模型转到中间
function XUiRoleGrid:ChangeModelPosition(position, rotation)
    if self.ModelPanel then
        self.ModelPanel.Transform.position = position
        self.ModelPanel.Transform.rotation = rotation
    end
end

function XUiRoleGrid:GetModelTransformParams()
    if self.ModelPanel then
        return self.ModelPanel.Transform.position, self.ModelPanel.Transform.rotation
    end
end

-- Ui换位：用于腐化时在Ui层将被腐化的角色模型转到中间
function XUiRoleGrid:ChangeUiPosition(position)
    if self.Transform then
        self.Transform.position = position
    end
end

function XUiRoleGrid:GetUiPosition()
    if self.Transform then
        return self.Transform.position
    end
end

return XUiRoleGrid