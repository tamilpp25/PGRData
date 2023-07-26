--######################## XUiBossGrid ########################
local XUiBossGrid = XClass(nil, "XUiBossGrid")

function XUiBossGrid:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.RootUi = rootUi
    self.Boss = nil
    self.BtnSelf.CallBack = function() self:OnBtnSelfClicked() end
    self.Index = 0
end

-- boss : XSCBoss
function XUiBossGrid:SetData(boss, index)
    self.Boss = boss
    self.Index = index
    self.TxtName.text = boss:GetName()
    self.TxtName2.text = boss:GetName()
    local maxScore = boss:GetMaxScore()
    self.RImgGrade:SetRawImage(boss:GetMaxGradeIcon())
    self.RImgGrade2:SetRawImage(boss:GetMaxGradeIcon())
    self.RImgIcon:SetRawImage(boss:GetFullBodyIcon())
    self.RImgIcon2:SetRawImage(boss:GetFullBodyIcon())
    self.RImgLock:SetRawImage(boss:GetFullBodyIcon())
    local showGradeInfo = self.Boss:GetIsOpen() and maxScore > 0
    self.TxtName.gameObject:SetActiveEx(not showGradeInfo)
    self.TxtName2.gameObject:SetActiveEx(not showGradeInfo)
    --self.TxtMaxCombo.gameObject:SetActiveEx(showGradeInfo)
    --self.TxtMaxCombo2.gameObject:SetActiveEx(showGradeInfo)
    self.TxtMaxScore.gameObject:SetActiveEx(showGradeInfo)
    self.TxtMaxScore2.gameObject:SetActiveEx(showGradeInfo)
    self.RImgGrade.gameObject:SetActiveEx(showGradeInfo)
    self.RImgGrade2.gameObject:SetActiveEx(showGradeInfo)
    if showGradeInfo then
        self.TxtMaxCombo.text = boss:GetMaxCombo()
        self.TxtMaxCombo2.text = boss:GetMaxCombo()
        self.TxtMaxScore.text = maxScore
        self.TxtMaxScore2.text = maxScore
    end
    local isTimeType = boss:IsTimeType()
    self.PanelLabel.gameObject:SetActiveEx(isTimeType)
    self:RefreshStatus()
end

function XUiBossGrid:RefreshStatus()
    local isOpen, desc = self.Boss:GetIsOpen()
    self.PanelLock.gameObject:SetActiveEx(not isOpen)
    if not isOpen then
        self.TxtLockTip.text = desc
    end
end

function XUiBossGrid:OnBtnSelfClicked()
    local isOpen, desc = self.Boss:GetIsOpen()
    if not isOpen then
        XUiManager.TipError(desc)
        return 
    end
    XLuaUiManager.Open("UiSameColorGameBoss", self.Boss)
end

--######################## XUiSameColorGameBossMain ########################
local XUiSameColorGameBossMain = XLuaUiManager.Register(XLuaUi, "UiSameColorGameBossMain")

function XUiSameColorGameBossMain:OnAwake()
    self.SameColorGameManager = XDataCenter.SameColorActivityManager
    self.BossManager = self.SameColorGameManager.GetBossManager()
    self.Bosses = nil
    -- boss列表
    self.BossGridList = {}
    -- 资源栏
    local itemIds = self.SameColorGameManager.GetAssetItemIds()
    XUiHelper.NewPanelActivityAsset(itemIds, self.PanelAsset, nil , function(uiSelf, index)
        local itemId = itemIds[index]
        XLuaUiManager.Open("UiSameColorGameSkillDetails", nil, itemId)
    end)
    self:RegisterUiEvents()
end

function XUiSameColorGameBossMain:OnStart()
    self.TxtTitle.text = self.SameColorGameManager.GetName()
    local endTime = self.SameColorGameManager.GetEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            self.SameColorGameManager.HandleActivityEndTime()
        else
            self:RefreshTimeText()
            for _, grid in pairs(self.BossGridList) do
                grid:RefreshStatus()
            end
        end
    end, nil, 1)
end

function XUiSameColorGameBossMain:OnEnable()
    XUiSameColorGameBossMain.Super.OnEnable(self)
    XRedPointManager.CheckOnceByButton(self.BtnTask, { XRedPointConditions.Types.CONDITION_SAMECOLOR_TASK })
    self:RefreshBossList()
    self.SameColorGameManager.SetMainUiModelInfo(self.UiModel, self.UiModelGo, self.UiSceneInfo)

    self:PlayAnimation("Enable", function()
        self:PlayAnimation("Loop", nil, nil, CS.UnityEngine.Playables.DirectorWrapMode.Loop)
    end)
end

function XUiSameColorGameBossMain:OnDestroy()
    self.SameColorGameManager.ClearMainUiModelInfo()
    XUiSameColorGameBossMain.Super.OnDestroy(self)
end

--######################## 私有方法 ########################

function XUiSameColorGameBossMain:RegisterUiEvents()
    self.BtnBack.CallBack = function() self:Close() end
    self.BtnMainUi.CallBack = function() XLuaUiManager.RunMain() end
    self.BtnTask.CallBack = function() self:OnBtnTaskClicked() end
    self.BtnRank.CallBack = function() self:OnBtnRankClicked() end
    self.BtnStore.CallBack = function() self:OnBtnStoreClicked() end
    self:BindHelpBtn(self.BtnHelp, self.SameColorGameManager.GetHelpId())
end

function XUiSameColorGameBossMain:OnBtnTaskClicked()
    XLuaUiManager.Open("UiSameColorGameTask")
end

function XUiSameColorGameBossMain:OnBtnRankClicked()
    self.SameColorGameManager.RequestRankData(0, function(rankList, myRankInfo)
        XLuaUiManager.Open("UiFubenSameColorGameRank", rankList, myRankInfo)
    end)
end

function XUiSameColorGameBossMain:OnBtnStoreClicked()
    self.SameColorGameManager.OpenShopUi()
end

function XUiSameColorGameBossMain:RefreshTimeText()
    local second = self.SameColorGameManager.GetEndTime() - XTime.GetServerNowTimestamp()
    local day = math.floor(second / (3600 * 24))
    local _, _, _, hours, minutes, seconds = XUiHelper.GetTimeNumber(second)
    local result, desc
    if day >= 1 then
        result = day
        desc = XUiHelper.GetText("Day")
    elseif hours >= 1 then
        result = hours
        desc = XUiHelper.GetText("Hour")
    elseif minutes >= 1 then
        result = minutes
        desc = XUiHelper.GetText("Minute")
    else
        result = seconds
        desc = XUiHelper.GetText("Second")
    end
    self.TxtTime.text = XUiHelper.GetText("SCActivityTimeText", result, desc)
end

function XUiSameColorGameBossMain:RefreshBossList()
    self.Bosses = self.BossManager:GetBosses()

    for i, boss in ipairs(self.Bosses) do
        local bossGrid = self.BossGridList[i]
        if not bossGrid then
            local go = self["GridArchiveNpc" .. i]
            bossGrid = XUiBossGrid.New(go, self)
            self.BossGridList[i] = bossGrid
        end

        bossGrid:SetData(boss, i)
    end
end

return XUiSameColorGameBossMain