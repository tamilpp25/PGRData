local XUiPrequelFragment = XLuaUiManager.Register(XLuaUi, "UiPrequelFragment")
local ChallengeChapterTimer = nil
local ChallengeChapterInterval = 1000

function XUiPrequelFragment:OnAwake()
    self:InitButton()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.OnRefreshTimeChanged = function() self:UpdateRefreshTime() end
    self.OnUnlockChallengeStageChanged = function() self:UpdateChallengeStage() end
    self.OnPrequelDetailClosed = function() self:OnDetailClosed() end
end

function XUiPrequelFragment:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, function() XLuaUiManager.RunMain() end)
    XUiHelper.RegisterClickEvent(self, self.BtnActDesc, self.OnBtnActDescClick)
end

function XUiPrequelFragment:OnStart(fragmentCfg, coverCfg)
    self.FragmentCfg = fragmentCfg
    self.CoverCfg = coverCfg
end

function XUiPrequelFragment:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_NOTICE_CHALLENGESTAGES_CHANGE, self.OnRefreshTimeChanged)
    XEventManager.AddEventListener(XEventId.EVENT_NOTICE_REFRESHTIME_CHANGE, self.OnUnlockChallengeStageChanged)
    XEventManager.AddEventListener(XEventId.EVENT_NOTICE_PREQUELDETAIL_CLOSE, self.OnPrequelDetailClosed)

    self:OnRefresh()
end

function XUiPrequelFragment:OnRefresh()
    self:PlayAnimation("AniChallengeModeBegin", function()
        -- self:SetChallengeAnimBegin(false)
    end,
    function()
        -- self:SetChallengeAnimBegin(true)
        self:UpdateChallengeStages()
        self:AddChallengeTimer()
        self:ResetBgFx(self.CoverCfg.ChallengeFx)
        local coverDatas = XPrequelConfigs.GetPrequelCoverInfoById(self.CoverCfg.CoverId)
        self:ResetBackground(coverDatas.ChallengeBg)

        -- 默认打开战斗详情
        self:OpenOneChildUi("UiPrequelLineDetail")
        self:FindChildUiObj("UiPrequelLineDetail"):Refresh(self.FragmentCfg.StageId)
        self:SetPanelAssetActive(false)
    end)

    self:AddTimer()
end

function XUiPrequelFragment:UpdateChallengeStages()
    if not self.CoverCfg then return end
    self.TxtChapterName.text = self.CoverCfg.CoverName

    local prefabName = self.CoverCfg.ChallengePrefabName
    if not prefabName or prefabName == "" then
        XLog.Error("XUiPrequelFragment:UpdateChallengeStages error : prefabName not found " .. tostring(prefabName))
        return
    end

    self.ChallengeStageDatas = {}
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(self.FragmentCfg.StageId)
    table.insert(self.ChallengeStageDatas, {
        CoverId = self.CoverCfg.CoverId,
        ChallengeStage = self.FragmentCfg.StageId,
        ChallengeConsumeItem = XDataCenter.FubenManager.GetRequireActionPoint(self.FragmentCfg.StageId),
        ChallengeConsumeCount = stageCfg.MaxChallengeNums,
        ChallengeIndex = 1,
    })

    local asset = self.PanelPrequelStages:LoadPrefab(prefabName)
    if asset == nil or (not asset:Exist()) then
        XLog.Error("当前prefab不存在：" .. tostring(prefabName))
        return
    end
    local grid = XUiPanelChallengeChapter.New(asset, self)
    grid.Transform:SetParent(self.PanelPrequelStages, false)
    grid:UpdateChallengeGrid(self.ChallengeStageDatas)
    grid:Show()
    self.CurrentChallengeGrid = grid
end

-- [切换背景]
function XUiPrequelFragment:ResetBackground(rawBg)
    local bgNil = string.IsNilOrEmpty(rawBg)
    if bgNil then
        self.RImgBg:SetRawImage("Assets/Product/Texture/Image/UiFubenMainMapTab/ChapterBg01B.png")
        return
    end
    if self.bgName and self.bgName == rawBg then return end
    self.bgName = rawBg
    self.RImgBg:SetRawImage(rawBg)
end

-- [切换背景特效]
function XUiPrequelFragment:ResetBgFx(fxPath)
    local disable = string.IsNilOrEmpty(fxPath)
    self.PanelEffect.gameObject:SetActiveEx(not disable)
    if disable then return end
    if self.fxName and self.fxName == fxPath then return end
    self.fxName = fxPath
    self.PanelEffect.gameObject:LoadUiEffect(fxPath)
end

-- 关闭关卡详情
function XUiPrequelFragment:OnDetailClosed()
    if self.CurrentChallengeGrid then
        self.CurrentChallengeGrid:OnPrequelDetailClosed()
    end
    self:SetPanelAssetActive(true)
end

function XUiPrequelFragment:OnClosePrequelDetail()
end

-- [刷新挑战关卡]
function XUiPrequelFragment:UpdateChallengeStage()
    self:UpdateChallengeStages()
    self:AddTimer()
    if XLuaUiManager.IsUiShow("UiPrequelLineDetail") then
        self.ChildUiPrequelLineDetail:Refresh(self.FragmentCfg.StageId)
    end
end

function XUiPrequelFragment:AddTimer()
    local checkpointTime = XDataCenter.PrequelManager.GetNextCheckPointTime()
    local remainTime = checkpointTime - XTime.GetServerNowTimestamp()
    if remainTime > 0 then
        XCountDown.CreateTimer(self.GameObject.name, remainTime)
        XCountDown.BindTimer(self.GameObject, self.GameObject.name, function(v)
            self.TxtResetTime.text = XUiHelper.GetTime(v, XUiHelper.TimeFormatType.SHOP)
            if v == 0 then XCountDown.RemoveTimer(self.GameObject.name) end
        end)
    end
end

function XUiPrequelFragment:AddChallengeTimer()
    self:RemoveChallengeTimer()
    ChallengeChapterTimer = XScheduleManager.ScheduleForever(function()
        self:UpdateChapterItems()
    end, ChallengeChapterInterval)
end

function XUiPrequelFragment:RemoveChallengeTimer()
    if ChallengeChapterTimer then
        XScheduleManager.UnSchedule(ChallengeChapterTimer)
        ChallengeChapterTimer = nil
    end
end

function XUiPrequelFragment:UpdateChapterItems()
    if self.CurrentChallengeGrid then
        self.CurrentChallengeGrid:UpdateItems()
    end
end

function XUiPrequelFragment:UpdateRefreshTime()
end

function XUiPrequelFragment:SetPanelAssetActive(isActive)
    if XTool.UObjIsNil(self.AssetPanel.GameObject) then
        return
    end
    if isActive then
        self.AssetPanel:Open()
    else
        self.AssetPanel:Close()
    end
end

-- 按钮事件
function XUiPrequelFragment:OnBtnActDescClick()
    local coverInfo = XPrequelConfigs.GetPrequelCoverInfoById(self.CoverCfg.CoverId)
    local description = string.gsub(coverInfo.CoverDescription, "\\n", "\n")
    XUiManager.UiFubenDialogTip("", description)
end

function XUiPrequelFragment:OnDisable()
    -- 关闭界面也检查计时器是否还没清除
    self:RemoveChallengeTimer()
    XCountDown.RemoveTimer(self.GameObject.name)

    XEventManager.RemoveEventListener(XEventId.EVENT_NOTICE_CHALLENGESTAGES_CHANGE, self.OnRefreshTimeChanged)
    XEventManager.RemoveEventListener(XEventId.EVENT_NOTICE_REFRESHTIME_CHANGE, self.OnUnlockChallengeStageChanged)
    XEventManager.RemoveEventListener(XEventId.EVENT_NOTICE_PREQUELDETAIL_CLOSE, self.OnPrequelDetailClosed)
end

function XUiPrequelFragment:OnDestroy()
end