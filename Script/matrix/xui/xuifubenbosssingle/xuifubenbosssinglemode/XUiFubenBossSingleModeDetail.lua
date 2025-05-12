local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiFubenBossSingleModeDetailGridBuff = require(
    "XUi/XUiFubenBossSingle/XUiFubenBossSingleMode/XUiFubenBossSingleModeDetailGridBuff")
local XUiGridBossRankReward = require("XUi/XUiFubenBossSingle/XUiGridBossRankReward")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local XUiModelUtility = require("XUi/XUiCharacter/XUiModelUtility")

---@class XUiFubenBossSingleModeDetail : XLuaUi
---@field BtnHelp XUiComponent.XUiButton
---@field PanelAsset UnityEngine.RectTransform
---@field BtnBack XUiComponent.XUiButton
---@field BtnMainUi XUiComponent.XUiButton
---@field TxtValue UnityEngine.UI.Text
---@field PanelRankEmpty UnityEngine.RectTransform
---@field PanelRankInfo UnityEngine.RectTransform
---@field BtnRank XUiComponent.XUiButton
---@field TxtNoneRank UnityEngine.UI.Text
---@field TxtRankEmpty UnityEngine.UI.Text
---@field TxtRank UnityEngine.UI.Text
---@field GridBossRankReward UnityEngine.UI.Button
---@field GridBuff UnityEngine.RectTransform
---@field PanelRight UnityEngine.RectTransform
---@field PanelLeft UnityEngine.RectTransform
---@field BtnTitle XUiComponent.XUiButton
---@field ImgTitleIcon UnityEngine.UI.RawImage
---@field _Control XFubenBossSingleControl
local XUiFubenBossSingleModeDetail = XLuaUiManager.Register(XLuaUi, "UiFubenBossSingleModeDetail")

-- region 生命周期

function XUiFubenBossSingleModeDetail:OnAwake()
    local root = self.UiModelGo.transform

    ---@type XUiFubenBossSingleModeDetailGridBuff[]
    self._GridBuffUiList = {}
    ---@type XUiPanelRoleModel
    self._RoleModelPanelUi = XUiPanelRoleModel.New(root:FindTransform("PanelRoleModel"), self.Name, nil, true)
    self._ChallengeData = self._Control:GetBossSingleChallengeData()
    self._IsNeedResetAnimation = false
    self._IsSelecting = false
    self._IsBuffPlaying = false
    self._RankRewardUi = XUiGridBossRankReward.New(self.GridBossRankReward, self, self)
    self._RankRewardUi:Close()
    self:_RegisterButtonClicks()
end

function XUiFubenBossSingleModeDetail:OnStart()
    self:_InitUi()
    self:_InitCamera()
end

function XUiFubenBossSingleModeDetail:OnEnable()
    self:_RefreshModel()
    self:_RefreshBuffGrid()
    self:_RefreshRankInfo()
    self:_RefreshRankReward()
    self:_RegisterEventListener()
    if self._IsNeedResetAnimation then
        self:ChangeCamera(false, nil, true)
        self:SetIsNeedResetAnimation(false)
    end
end

function XUiFubenBossSingleModeDetail:OnDisable()
    self:_RemoveEventListener()
end

-- endregion

function XUiFubenBossSingleModeDetail:SetIsBuffPlaying(isPlaying)
    self._IsBuffPlaying = isPlaying
end

function XUiFubenBossSingleModeDetail:SetIsNeedResetAnimation(isReset)
    self._IsNeedResetAnimation = isReset
end

function XUiFubenBossSingleModeDetail:ChangeBuffGrid(index)
    if not self._IsBuffPlaying then
        self:ChangeCamera(index ~= nil, index)
    end
end

function XUiFubenBossSingleModeDetail:ChangeCamera(isSelecting, selectIndex, isForce)
    if self._IsBuffPlaying then
        return
    end
    if self._NearCamera then
        self._NearCamera.gameObject:SetActiveEx(not isSelecting)
    end
    if self._FarCamera then
        self._FarCamera.gameObject:SetActiveEx(not isSelecting)
    end
    if self._NearCameraChange then
        self._NearCameraChange.gameObject:SetActiveEx(isSelecting)
    end
    if self._FarCameraChange then
        self._FarCameraChange.gameObject:SetActiveEx(isSelecting)
    end
    if self.PanelLeft then
        self.PanelLeft.gameObject:SetActiveEx(not isSelecting)
    end
    self:_PlayAllBuffAnimation(isSelecting, selectIndex, isForce)
    self._IsSelecting = isSelecting
end

function XUiFubenBossSingleModeDetail:GetBossId()
    if self._ChallengeData then
        return self._ChallengeData:GetBossId()
    end

    return 0
end

-- region 按钮事件

function XUiFubenBossSingleModeDetail:OnBtnRankClick()
    self._Control:OpenChallengeRankUi()
end

function XUiFubenBossSingleModeDetail:OnBtnTitleClick()
    local levelType = self._Control:GetBossSingleData():GetBossSingleChallengeLevelType()

    self._Control:OpenChallengeBossViewUi(levelType)
end

function XUiFubenBossSingleModeDetail:OnBtnTanchuangCloseBigClick()
    if self._IsSelecting and not self._IsBuffPlaying then
        self:ChangeBuffGrid()
    end
end

function XUiFubenBossSingleModeDetail:OnActivityEnd()
    self._Control:OnActivityEnd()
end

function XUiFubenBossSingleModeDetail:Close()
    if not self._IsSelecting then
        self.Super.Close(self)
    else
        self:ChangeBuffGrid()
    end
end

-- endregion

-- region 私有方法

function XUiFubenBossSingleModeDetail:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self:BindExitBtns(self.BtnBack, self.BtnMainUi)
    self:BindHelpBtn(self.BtnHelp, "BossSingle")
    self:RegisterClickEvent(self.BtnRank, self.OnBtnRankClick, true)
    self:RegisterClickEvent(self.BtnTitle, self.OnBtnTitleClick, true)
    self:RegisterClickEvent(self.BtnTanchuangCloseBig, self.OnBtnTanchuangCloseBigClick, true)
end

function XUiFubenBossSingleModeDetail:_RegisterEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_FUBEN_SINGLE_BOSS_RANK_SYNC, self._RefreshRankInfo, self)
    XEventManager.AddEventListener(XEventId.EVENT_FUBEN_SINGLE_BOSS_RESET, self.OnActivityEnd, self)
end

function XUiFubenBossSingleModeDetail:_RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_FUBEN_SINGLE_BOSS_RANK_SYNC, self._RefreshRankInfo, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FUBEN_SINGLE_BOSS_RESET, self.OnActivityEnd, self)
end

function XUiFubenBossSingleModeDetail:_RefreshBuffGrid()
    local count = self._ChallengeData:GetFeatureCount()

    for i = 1, count do
        local gridBuff = self._GridBuffUiList[i]
        local feature = self._ChallengeData:GetFeatureByIndex(i)

        if not gridBuff then
            local grid = XUiHelper.Instantiate(self.GridBuff, self.PanelRight)

            gridBuff = XUiFubenBossSingleModeDetailGridBuff.New(grid, self)
            self._GridBuffUiList[i] = gridBuff
        end

        gridBuff:Open()
        gridBuff:Refresh(feature, i)
        gridBuff:SetDetailActive(false)
    end
    for i = count + 1, #self._GridBuffUiList do
        self._GridBuffUiList[i]:Close()
    end
end

function XUiFubenBossSingleModeDetail:_RefreshRankInfo()
    local rank = self._ChallengeData:GetSelfRank()
    local totalRank = self._ChallengeData:GetTotalRank()
    local maxCount = self._Control:GetMaxRankCount()
    local singleData = self._Control:GetBossSingleData()
    local totalScore = singleData:GetBossSingleChallengeTotalScore()

    self.TxtValue.text = totalScore
    if self._ChallengeData:IsSelfRankInfoEmpty() then
        self.TxtRank.gameObject:SetActiveEx(false)
        self.TxtNoneRank.gameObject:SetActiveEx(true)
    else
        if rank <= maxCount and rank > 0 then
            self.TxtRank.text = math.floor(rank)
            self.TxtRank.gameObject:SetActiveEx(true)
            self.TxtNoneRank.gameObject:SetActiveEx(false)
        else
            if not totalRank or totalRank <= 0 or rank <= 0 then
                self.TxtRank.gameObject:SetActiveEx(false)
                self.TxtNoneRank.gameObject:SetActiveEx(true)
            else
                local number = math.floor(rank / totalRank * 100)

                self.TxtRank.gameObject:SetActiveEx(true)
                self.TxtNoneRank.gameObject:SetActiveEx(false)

                if number < 1 then
                    number = 1
                end

                self.TxtRank.text = XUiHelper.GetText("BossSinglePercentDesc", number)
            end
        end
    end
end

function XUiFubenBossSingleModeDetail:_RefreshRankReward()
    local levelType = self._Control:GetBossSingleData():GetBossSingleChallengeLevelType()

    self._RankRewardUi:Close()
    XMVCA.XFubenBossSingle:RequestChallengeRankData(function(rankData)
        if not rankData then
            return
        end

        local config = nil
        local configs = self._Control:GetRankRewardConfig(levelType)

        for i = 1, #configs do
            if self._Control:CheckCurrentRank(levelType, configs[i], rankData) then
                config = configs[i]
            end
        end

        config = config or configs[#configs]

        if not config then
            return
        end

        self._RankRewardUi:Open()
        self._RankRewardUi:Refresh(config, false)
    end)
end

function XUiFubenBossSingleModeDetail:_RefreshModel()
    local modelId = self._ChallengeData:GetBossModelId()

    XUiModelUtility.UpdateMonsterBossModel(self._RoleModelPanelUi, modelId, XModelManager.MODEL_UINAME.XUiBossSingle)
end

function XUiFubenBossSingleModeDetail:_InitUi()
    local bossSingle = self._Control:GetBossSingleData()
    local levelType = bossSingle:GetBossSingleChallengeLevelType()

    XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem,
        XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.ImgTitleIcon:SetRawImage(self._Control:GetChallengeRankLevelIconByType(levelType))
    self.GridBuff.gameObject:SetActiveEx(false)
end

function XUiFubenBossSingleModeDetail:_InitCamera()
    local root = self.UiModelGo.transform
    local imgEffect = root:FindTransform("ImgEffectHuanren")
    local imgEffectHide = root:FindTransform("ImgEffectHuanren1")
    local detialNearCamera = root:FindTransform("UiDetailCamNear")
    local detialFarCamera = root:FindTransform("UiDetailCamFar")

    if imgEffect then
        imgEffect.gameObject:SetActiveEx(false)
    end
    if imgEffectHide then
        imgEffectHide.gameObject:SetActiveEx(false)
    end
    if detialNearCamera then
        detialNearCamera.gameObject:SetActiveEx(false)
    end
    if detialFarCamera then
        detialFarCamera.gameObject:SetActiveEx(false)
    end

    self._NearCamera = root:FindTransform("UiModeCamNear01")
    self._NearCameraChange = root:FindTransform("UiModeCamNear02")
    self._FarCamera = root:FindTransform("UiModeCamFar01")
    self._FarCameraChange = root:FindTransform("UiModeCamFar02")

    if self._NearCamera then
        self._NearCamera.gameObject:SetActiveEx(true)
    end
    if self._FarCamera then
        self._FarCamera.gameObject:SetActiveEx(true)
    end
end

function XUiFubenBossSingleModeDetail:_PlayAllBuffAnimation(isOpen, selectIndex, isForce)
    self:SetIsBuffPlaying(true)
    if self._IsSelecting ~= isOpen or isForce then
        for i, buffGrid in pairs(self._GridBuffUiList) do
            buffGrid:PlayBuffAnimation(isOpen, i == selectIndex)
        end
    else
        for i, buffGrid in pairs(self._GridBuffUiList) do
            buffGrid:SetDetailActive(i == selectIndex)
        end
    end
end

-- endregion

return XUiFubenBossSingleModeDetail
