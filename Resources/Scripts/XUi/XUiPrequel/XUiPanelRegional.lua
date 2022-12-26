XUiPanelRegional = XClass(nil, "XUiPanelRegional")

function XUiPanelRegional:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self:InitAutoScript()
    self.CurrentPrequelGrid = nil
    self.LastPrequelPrefabName = ""
    self.PrequelGridList = {}
    self.PrequelGridAsset = {}
    self.PlotTab = XUiPanelPlotTab.New(self.PanelPlotTab, self.RootUi, self)
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiPanelRegional:InitAutoScript()
    self:AutoInitUi()
    self:AutoAddListener()
end

function XUiPanelRegional:AutoInitUi()
    self.PanelRegional = self.Transform:Find("PanelRegional")
    self.PanelPrequelStages = self.Transform:Find("PanelRegional/PanelPrequelStages")
    self.TxtMode = self.Transform:Find("PanelRegional/PanelBt/TxtMode"):GetComponent("Text")
    self.TxtProgress = self.Transform:Find("PanelRegional/PanelBt/TxtProgress"):GetComponent("Text")
    self.PanelLeft = self.Transform:Find("PanelRegional/PanelLeft")
    self.PanelPlotTab = self.Transform:Find("PanelRegional/PanelLeft/PanelPlotTab")
    self.BtnSwitch2Fight = self.Transform:Find("PanelRegional/PanelBt/BtnSwitch2Fight"):GetComponent("Button")
    self.ImgLock = self.Transform:Find("PanelRegional/PanelBt/BtnSwitch2Fight/ImgLock/Image"):GetComponent("Image")
    self.PanelBottom = self.Transform:Find("PanelRegional/PanelBottom")
    self.PanelJundu = self.Transform:Find("PanelRegional/PanelBottom/PanelJundu")
    self.ImgJindu = self.Transform:Find("PanelRegional/PanelBottom/PanelJundu/ImgJindu"):GetComponent("Image")
    self.ImgLingqu = self.Transform:Find("PanelRegional/PanelBottom/PanelJundu/ImgLingqu"):GetComponent("Image")
    self.BtnTreasure = self.Transform:Find("PanelRegional/PanelBottom/PanelJundu/BtnTreasure"):GetComponent("Button")
    self.PanelNum = self.Transform:Find("PanelRegional/PanelBottom/PanelNum")
    self.TxtBfrtTaskTotalNum = self.Transform:Find("PanelRegional/PanelBottom/PanelNum/TxtBfrtTaskTotalNum"):GetComponent("Text")
    self.TxtBfrtTaskFinishNum = self.Transform:Find("PanelRegional/PanelBottom/PanelNum/TxtBfrtTaskFinishNum"):GetComponent("Text")
    self.ImgRedProgress = self.Transform:Find("PanelRegional/PanelBottom/PanelNum/ImgRedProgress")
    self.BtnActDesc = self.Transform:Find("PanelRegional/BtnActDesc"):GetComponent("Button")
    self.RImgChapterName = self.Transform:Find("PanelRegional/PanelBt/RImgChapterName"):GetComponent("RawImage")
end

function XUiPanelRegional:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiPanelRegional:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiPanelRegional:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiPanelRegional:AutoAddListener()
    self:RegisterClickEvent(self.BtnSwitch2Fight, self.OnBtnSwitch2FightClick)
    self:RegisterClickEvent(self.BtnTreasure, self.OnBtnTreasureClick)
    self:RegisterClickEvent(self.BtnActDesc, self.OnBtnActDescClick)
end

function XUiPanelRegional:CheckHaveChallengeMode()
    local cStage = self.CurrentCover.CoverVal.ChallengeStage
    self.BtnSwitch2Fight.gameObject:SetActiveEx(cStage ~= nil and #cStage > 0)
end
-- auto

function XUiPanelRegional:OnBtnSwitch2FightClick()
    if not self.CurrentCover then
        return
    end
    local coverVal = self.CurrentCover.CoverVal
    if not coverVal.ChallengeStage or #coverVal.ChallengeStage == 0 then return end
    -- 检查条件
    if coverVal.ChallengeCondition > 0 then
        local rect, desc = XConditionManager.CheckCondition(coverVal.ChallengeCondition)
        if not rect then
            XUiManager.TipMsg(desc)
            return
        end
    end
    local keyX = string.format("%s%d%d", "PrequelLastSwitchPanelType", XPlayer.Id, self.CurrentCover.CoverId)
    local panelType = 2
    CS.UnityEngine.PlayerPrefs.SetInt(keyX, panelType)
    self.RootUi:Switch2Challenge(self.CurrentCover)
end

function XUiPanelRegional:OnBtnTreasureClick()
    if not self.CurrentSelectedChapterId then
        return
    end
    self.RootUi:Switch2RewardList(self.CurrentSelectedChapterId)
end

function XUiPanelRegional:OnBtnActDescClick()
    if self.CurrentCover and self.CurrentSelectIdx then
        local reverseIndex = #self.CurrentCover.CoverVal.ChapterId - self.CurrentSelectIdx + 1
        local chapterId = self.CurrentCover.CoverVal.ChapterId[reverseIndex]
        local chapterInfo = XPrequelConfigs.GetPrequelChapterInfoById(chapterId)
        local description = string.gsub(chapterInfo.ChapterDescription, "\\n", "\n")
        XUiManager.UiFubenDialogTip("", description)
    end
end

function XUiPanelRegional:InitPlotTab()
    self.PlotTab:UpdateTabs(self.CurrentCover)
    local defaultIndex = XDataCenter.PrequelManager.GetSelectableChaperIndex(self.CurrentCover) or 1
    local skipChapter = self.RootUi:GetDefaultChapter()
    local isSkipChapterInActivity = (skipChapter ~= nil) and XDataCenter.PrequelManager.IsChapterInActivity(skipChapter) or false
    
    local skipIndex = XDataCenter.PrequelManager.GetIndexByChapterId(self.CurrentCover, skipChapter)
    self.CurrentSelectIdx = self.CurrentSelectIdx or defaultIndex
    if isSkipChapterInActivity then
        local skipDescription = XDataCenter.PrequelManager.GetChapterUnlockDescription(skipChapter)
        -- 活动内、已解锁
        if skipDescription == nil then
            self.CurrentSelectIdx = skipIndex or self.CurrentSelectIdx
        end
    end
    local index = self.RootUi:GetResumeTabIndex()
    if index then self.CurrentSelectIdx = index end
    self.PlotTab:SelectIndex(self.CurrentSelectIdx, false)
end

function XUiPanelRegional:OnRefresh(coverData)
    self.CurrentCover = coverData
    self:CheckHaveChallengeMode()
    self:InitPlotTab()
end

function XUiPanelRegional:UpdateCurrentTab()
    if self.CurrentSelectIdx then
        self:OnChapterSelected(self.CurrentSelectIdx)
    end
end

function XUiPanelRegional:UpdateRewardView()
    if self.CurrentCover and self.CurrentSelectIdx then
        local reverseIndex = #self.CurrentCover.CoverVal.ChapterId - self.CurrentSelectIdx + 1
        local chapterId = self.CurrentCover.CoverVal.ChapterId[reverseIndex]
        self.ImgRedProgress.gameObject:SetActive(XDataCenter.PrequelManager.CheckRewardAvailable(chapterId))
        local totalNum, finishedNum = self:GetRewardTotalNumAndFinishNum(chapterId)
        self.TxtBfrtTaskTotalNum.text = totalNum
        self.TxtBfrtTaskFinishNum.text = finishedNum
        self.ImgJindu.fillAmount = finishedNum / totalNum * 1.0
    end
end

function XUiPanelRegional:UpdateCover()
    XEventManager.DispatchEvent(XEventId.EVENT_NOTICE_SELECTCOVER_CHANGE, {Cover = self.CurrentCover, Index = self.CurrentSelectIdx})
end

function XUiPanelRegional:OnChapterSelected(index, chapterId)
    self.CurrentSelectIdx = index
    local reverseIndex = #self.CurrentCover.CoverVal.ChapterId - index + 1
    local id = self.RootUi:GetResumeChapterId() --页面恢复时读取缓存的ID项
    if id then chapterId = id end
    if chapterId == nil then chapterId = self.CurrentCover.CoverVal.ChapterId[reverseIndex] end
    self.ChapterDatas = XPrequelConfigs.GetPrequelChapterById(chapterId)
    self.CurrentSelectedChapterId = chapterId
    local prefabName = self.ChapterDatas.PrefabName
    if not prefabName or prefabName == "" then
        XLog.Error("XUiPanelRegional:OnChapterSelected错误 : 没找到预制体 prefabName = " .. tostring(prefabName))
        return
    end
    --local asset = self.PanelRegional:LoadPrefab(prefabName)
    local asset = self.RootUi.PanelFullScreen:LoadPrefab(prefabName)
    if asset == nil or (not asset:Exist()) then
        XLog.Error("当前prefab不存在：" .. tostring(prefabName))
        return
    end
    if self.LastPrequelPrefabName ~= prefabName then
        local grid = XUiPanelPrequelChapter.New(asset, self.RootUi)
        --grid.Transform:SetParent(self.PanelRegional, false)
        self.CurrentPrequelGrid = grid
        self.LastPrequelPrefabName = prefabName
        if not string.IsNilOrEmpty(self.ChapterDatas.UiBgPath) then
            local bg = asset.transform:Find("RImgChapterBg")
            if bg then
                bg:GetComponent("RawImage"):SetRawImage(self.ChapterDatas.UiBgPath)
            end
        end
    end
    self.CurrentPrequelGrid:UpdatePrequelGrid(self.ChapterDatas.StageId)
    self.CurrentPrequelGrid:Show()

    local progressFinishedNum, progressTotalNum = XDataCenter.PrequelManager.GetChapterProgress(chapterId)
    self.TxtProgress.text = CS.XTextManager.GetText("UiPrequelTitleProgressStrFormat", progressFinishedNum, progressTotalNum)
    local totalNum, finishedNum = self:GetRewardTotalNumAndFinishNum(chapterId)
    self.TxtBfrtTaskTotalNum.text = totalNum
    self.TxtBfrtTaskFinishNum.text = finishedNum
    self.ImgRedProgress.gameObject:SetActive(XDataCenter.PrequelManager.CheckRewardAvailable(chapterId))
    self.ImgJindu.fillAmount = finishedNum / totalNum * 1.0
    if self.CurrentCover.CoverVal.ChallengeCondition > 0 then
        local rect = XConditionManager.CheckCondition(self.CurrentCover.CoverVal.ChallengeCondition)
        self.ImgLock.gameObject:SetActive(not rect)
    else
        self.ImgLock.gameObject:SetActive(false)
    end
    if string.IsNilOrEmpty(self.ChapterDatas.RImgChapterNamePath) then
        XLog.Warning("间章标题图片路径为空值！设置失败！chapterId = " .. chapterId .. " 请检查Chapter.tab表")
        self.RImgChapterName.gameObject:SetActiveEx(false)
    else
        self.RImgChapterName:SetRawImage(self.ChapterDatas.RImgChapterNamePath)
        self.RImgChapterName.gameObject:SetActiveEx(true)
    end
end

function XUiPanelRegional:GetRewardTotalNumAndFinishNum(chapterId)
    local totalNum = 0
    local finishNum = 0
    local chapterCfg = XPrequelConfigs.GetPrequelChapterById(chapterId)
    for _, stageId in pairs(chapterCfg and chapterCfg.StageId or {}) do
        local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
        if stageCfg.FirstRewardShow > 0 then
            totalNum = totalNum + 1
            if XDataCenter.PrequelManager.IsRewardStageCollected(stageId) then
                finishNum = finishNum + 1
            end
        end
    end
    return totalNum, finishNum
end

function XUiPanelRegional:SetPanelActive(isActive)
    if self.CurrentPrequelGrid then self.CurrentPrequelGrid.GameObject:SetActiveEx(isActive) end
    self.GameObject:SetActiveEx(isActive)
end

return XUiPanelRegional