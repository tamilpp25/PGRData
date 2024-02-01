--肉鸽玩法招募主界面
local XUiBiancaTheatreRecruit = XLuaUiManager.Register(XLuaUi, "UiBiancaTheatreRecruit")
local XUiRolePanel = require("XUi/XUiBiancaTheatre/Recruit/XUiRolePanel")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local XUiDownPanel = require("XUi/XUiBiancaTheatre/Recruit/XUiDownPanel")
local XUiRoleDetailPanel = require("XUi/XUiBiancaTheatre/Recruit/XUiRoleDetailPanel")
local XUiBiancaTheatrePanelDown = require("XUi/XUiBiancaTheatre/Common/XUiBiancaTheatrePanelDown")
local XUiBiancaTheatrePanelFetters = require("XUi/XUiBiancaTheatre/Common/XUiBiancaTheatrePanelFetters")
local XUiPanelItemChange = require("XUi/XUiBiancaTheatre/Common/XUiPanelItemChange")

function XUiBiancaTheatreRecruit:OnAwake()
    XUiHelper.NewPanelActivityAssetSafe(XDataCenter.BiancaTheatreManager.GetAdventureAssetItemIds(), self.PanelSpecialTool, self, nil, XDataCenter.BiancaTheatreManager.AdventureAssetItemOnBtnClick)
    self.Effect = XUiHelper.TryGetComponent(self.Transform, "FullScreenBackground/Effect")
    self:AddListener()
    self:InitItemChange()
end

function XUiBiancaTheatreRecruit:OnStart(isPlayMovie)
    -- 默认不播放
    if isPlayMovie == nil then isPlayMovie = false end
    self.IsPlayMovie = isPlayMovie

    self.AdventureManager = XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager()
    self.AdventureChapter = self.AdventureManager:GetCurrentChapter()
    self.CurStep = self.AdventureChapter:GetCurStep()
    local chapterId = self.AdventureChapter:GetCurrentChapterId()

    self.XUiPanelDown = XUiDownPanel.New(self.PanelDown, self, self.AdventureChapter, self.CurStep)
    self.XUiPanelRoleDetail = XUiRoleDetailPanel.New(self.PanelRoleDetails1, self, handler(self, self.HideTips))
    self.XUiPanelRoleDecayDetail = XUiRoleDetailPanel.New(self.PanelRoleDetails2, self, function()
        self:HideTips()
        if not self:IsDecayTick() then return end
        self:ShowDecayAnim(function ()
            self.XUiPanelDown:OnBtnMainClick()
        end)
    end)
    self.XUiCommonPanelDown = XUiBiancaTheatrePanelDown.New(self.PanelDown)
    self.XUiPanelFetters = XUiBiancaTheatrePanelFetters.New(self.PanelFetters)

    self:UpdateBg()
    self:UpdateVisionEffect()

    --招募券名
    self.TextTitle.text = XBiancaTheatreConfigs.GetRecruitTicketName(self.CurStep:GetTickId())
    self:InitUiScene(chapterId)
    self.PanelChar:GetComponent("UiObject"):GetObject("GridMulitiplayerRoomChar").gameObject:SetActiveEx(false)

    -- 抽空提示
    self:UpdateRecruitTip()
    -- 入场音效
    XDataCenter.BiancaTheatreManager.PlayGetRewardSound(nil, 3)
end

function XUiBiancaTheatreRecruit:OnEnable()
    self:Refresh()
    XEventManager.AddEventListener(XEventId.EVENT_THEATRE_RECRUIT_COMPLETE, self.RecruitCompleteRefresh, self)
    local beginStoryId = self.AdventureChapter:GetBeginStoryId()
    if beginStoryId and self.IsPlayMovie then
        XDataCenter.MovieManager.PlayMovie(beginStoryId, function()
            self.IsPlayMovie = false
        end)
    end
end

function XUiBiancaTheatreRecruit:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_THEATRE_RECRUIT_COMPLETE, self.RecruitCompleteRefresh, self)
end

function XUiBiancaTheatreRecruit:OnDestroy()
    self.XUiPanelFetters:Delete()
end

function XUiBiancaTheatreRecruit:Refresh()
    self:UpdateRecruitNumber()
    self:UpdateRefreshCount()
    self:UpdateDecayTitle()

    self:RefreshItemChange()

    self.XUiPanelDown:Refresh()
    self.XUiCommonPanelDown:Refresh()
    self.XUiPanelFetters:Refresh(true)
end

---货币栏位特效
function XUiBiancaTheatreRecruit:InitItemChange()
    self.PanelEnergyChange = XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/PanelEnergyChange")
    self.PanelEnergyChange2 = XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/PanelEnergyChange2")
    local panelEnergyChangeList = {
        self.PanelEnergyChange2,
        self.PanelEnergyChange,
    }
    for index, itemId in ipairs(XDataCenter.BiancaTheatreManager.GetAdventureAssetItemIds()) do
        if panelEnergyChangeList[index] then
            self["ItemChange" .. index] = XUiPanelItemChange.New(panelEnergyChangeList[index], itemId)
        end
    end
end

function XUiBiancaTheatreRecruit:RefreshItemChange()
    for index, _ in ipairs(XDataCenter.BiancaTheatreManager.GetAdventureAssetItemIds()) do
        if self["ItemChange" .. index] then
            self["ItemChange" .. index]:Refresh()
        end
    end
end

-- 招募
--------------------------------------------------------------------------------

--招募成功刷新
function XUiBiancaTheatreRecruit:RecruitCompleteRefresh()
    self:Refresh()
    if self.Character3DPanel then
        self.Character3DPanel:UpdateData(false)
    end
end

--刷新次数
function XUiBiancaTheatreRecruit:UpdateRefreshCount()
    self.BtnRefresh:SetNameByGroup(1, self.AdventureChapter:GetRefreshRoleCount())
end

--剩余招募次数
function XUiBiancaTheatreRecruit:UpdateRecruitNumber()
    self.TxtRecruitCount.text = self.AdventureChapter:GetRecruitCount()
end

function XUiBiancaTheatreRecruit:UpdateRecruitTip()
    local floorIndexes = self.CurStep:GetFloorIndexes()
    local isHaveRole = false
    for _, value in ipairs(self.CurStep.RefreshCharacterIds) do
        if XTool.IsNumberValid(value) then
            isHaveRole = true
        end
    end
    if not isHaveRole then
        XUiManager.TipError(XBiancaTheatreConfigs.GetClientConfig("RecruitAreNotRole"))
    end
    if XTool.IsTableEmpty(floorIndexes) then
        return
    end

    local resultIndexes = {}
    for index, value in ipairs(floorIndexes) do
        if value > 0 then
            table.insert(resultIndexes, index)
        end
    end
    if XTool.IsTableEmpty(resultIndexes) then return end

    local text = ""
    for i = 1, #resultIndexes - 1, 1 do
        text = text .. resultIndexes[i] .. "、"
    end
    text = text .. resultIndexes[#resultIndexes]
    if string.IsNilOrEmpty(text) then
        return
    end
    XUiManager.TipError(string.format(XBiancaTheatreConfigs.GetClientConfig("RecruitFloorIndexesTxt"), text))
end

function XUiBiancaTheatreRecruit:Set3DCharacter()
    local uiModelRoot = self.UiModelGo.transform
    local models = {
        [1] = XUiPanelRoleModel.New(uiModelRoot:FindTransform("PanelModelCase1"), self.Name, nil, true, nil, true, true),
        [2] = XUiPanelRoleModel.New(uiModelRoot:FindTransform("PanelModelCase2"), self.Name, nil, true, nil, true, true),
        [3] = XUiPanelRoleModel.New(uiModelRoot:FindTransform("PanelModelCase3"), self.Name, nil, true, nil, true, true),
    }
    self.Character3DPanel = XUiRolePanel.New(self.PanelChar, self, models)
    self.Character3DPanel:UpdateData(true)
end

function XUiBiancaTheatreRecruit:InitUiScene(chapterId)
    local sceneUrl = XBiancaTheatreConfigs.GetChapterSceneUrl(chapterId)
    local modelUrl = XBiancaTheatreConfigs.GetChapterModelUrl(chapterId)
    self:LoadUiScene(sceneUrl, modelUrl, function()
        if XTool.UObjIsNil(self.GameObject) then
            return
        end
        self:Set3DCharacter()
    end)
end

function XUiBiancaTheatreRecruit:UpdateBg()
    local chapter = self.AdventureManager:GetCurrentChapter()
    local chapterId = chapter:GetCurrentChapterId()
    if self.RImgBgA then
        local bgA = XBiancaTheatreConfigs.GetChapterBgA(chapterId)
        self.RImgBgA:SetRawImage(bgA)
    end
    if self.RImgBgB then
        local bgB = XBiancaTheatreConfigs.GetChapterBgB(chapterId)
        self.RImgBgB:SetRawImage(bgB)
    end
end

--------------------------------------------------------------------------------

-- 腐化相关
--------------------------------------------------------------------------------

function XUiBiancaTheatreRecruit:UpdateDecayTitle()
    self.TextTitleTips.gameObject:SetActiveEx(self:IsDecayTick())
    if self:IsDecayTick() then
        self.TextTitleTips.text = XUiHelper.ReplaceTextNewLine(XBiancaTheatreConfigs.GetClientConfig("RecruitDecayTitleTxt"))
        self.RefreshText.text = XBiancaTheatreConfigs.GetClientConfig("RecruitDecayRefreshTxt")
    end
end

function XUiBiancaTheatreRecruit:IsDecayTick()
    return self.CurStep:GetStepType() == XBiancaTheatreConfigs.XStepType.DecayRecruitCharacter
end

function XUiBiancaTheatreRecruit:ShowDecayAnim(cb)
    local name
    local gridIndex

    local adventureChapter = self.AdventureManager:GetCurrentChapter()
    local recruitRoleDic = adventureChapter:GetRecruitRoleDic()
    for i, adventureRole in pairs(recruitRoleDic or {}) do
        local characterId = adventureRole:GetBaseId()
        if self.CurStep:IsRecruitCharacter(characterId) then
            name = adventureRole:GetRoleName()
            gridIndex = i
        end
    end

    self.TxtCorruptionTip.text = string.format(XBiancaTheatreConfigs.GetClientConfig("RecruitDecayTxt"), name)

    self.PanelCorruption.gameObject:SetActiveEx(true)
    self:PlayAnimationWithMask("PanelCorruptionEnable", function ()
        self.PanelCorruption.gameObject:SetActiveEx(false)
        -- self.Character3DPanel:ShowModel()
        if cb then cb() end
    end)
    self.Character3DPanel:HideModel(gridIndex)
end

---腐化特效
function XUiBiancaTheatreRecruit:UpdateVisionEffect()
    local adventureManager = XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager()
    local visionValue = adventureManager:GetVisionValue() or 0
    local visionId = XBiancaTheatreConfigs.GetVisionIdByValue(visionValue)
    local isVisionOpen = XDataCenter.BiancaTheatreManager.CheckVisionIsOpen()
    if self.Effect then
        self.Effect.gameObject:LoadUiEffect(XBiancaTheatreConfigs.GetVisionUiEffectUrl(visionId))
        self.Effect.gameObject:SetActiveEx(isVisionOpen)
    end
end

--------------------------------------------------------------------------------

-- 按钮相关
--------------------------------------------------------------------------------

function XUiBiancaTheatreRecruit:AddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnRefresh, self.OnBtnRefreshClick)
    self:BindHelpBtn(self.BtnHelp, XDataCenter.BiancaTheatreManager.GetHelpKey())
    --self:RegisterClickEvent(self.GameObject, handler(self, self.HideTips))
    --self.GameObject:AddComponent(typeof(CS.UnityEngine.UI.XEmpty4Raycast))
    self:RegisterClickEvent(self.BtnCloseDetail, self.HideTips)
end

--显示详情弹窗
function XUiBiancaTheatreRecruit:ShowTips(adventureRole, isRecruitRole, isShowRankUp, isDecay)
    if isDecay then
        self.XUiPanelRoleDecayDetail:Refresh(adventureRole, isRecruitRole, isShowRankUp, isDecay)
        self.XUiPanelRoleDecayDetail.GameObject:SetActiveEx(true)
    else
        self.XUiPanelRoleDetail:Refresh(adventureRole, isRecruitRole, isShowRankUp, false)
        self.XUiPanelRoleDetail.GameObject:SetActiveEx(true)
    end
end

--隐藏详情弹窗
function XUiBiancaTheatreRecruit:HideTips()
    self.XUiPanelRoleDetail.GameObject:SetActiveEx(false)
    self.XUiPanelRoleDecayDetail.GameObject:SetActiveEx(false)
end

--货币点击方法
function XUiBiancaTheatreRecruit:OnBtnClick(index)
    XLuaUiManager.Open("UiBiancaTheatreTips", XBiancaTheatreConfigs.TheatreOutCoin)
end

function XUiBiancaTheatreRecruit:OnBtnBackClick()
    self:OpenLeaveTips(handler(self, self.Close))
end

function XUiBiancaTheatreRecruit:OnBtnMainUiClick()
    self:OpenLeaveTips(XDataCenter.BiancaTheatreManager.RunMain)
end

function XUiBiancaTheatreRecruit:OpenLeaveTips(sureCallback)
    local desc = CsXTextManagerGetText("TheatreLeaveTipsDesc")
    XLuaUiManager.Open("UiBiancaTheatreEndTips", nil, desc, nil, nil, sureCallback)
end

function XUiBiancaTheatreRecruit:OnBtnRefreshClick()
    self.AdventureChapter:RequestRefreshRoles(function()
        self:UpdateRefreshCount()
        if self.Character3DPanel then
            self.Character3DPanel:UpdateData(true)
        end
    end)
end

--------------------------------------------------------------------------------