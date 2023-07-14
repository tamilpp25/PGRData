local XUiMainPanelRegional = XClass(nil, "XUiMainPanelRegional")

function XUiMainPanelRegional:Ctor(ui, rootUi)
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
function XUiMainPanelRegional:InitAutoScript()
    self:AutoInitUi()
    self:AutoAddListener()
end

function XUiMainPanelRegional:AutoInitUi()
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

    self.PanelPlotTab.gameObject:SetActiveEx(false)
end

function XUiMainPanelRegional:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiMainPanelRegional:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiMainPanelRegional:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiMainPanelRegional:AutoAddListener()
    self:RegisterClickEvent(self.BtnTreasure, self.OnBtnTreasureClick)
    self:RegisterClickEvent(self.BtnActDesc, self.OnBtnActDescClick)
end

function XUiMainPanelRegional:OnBtnTreasureClick()
    self.RootUi:Switch2RewardList(self.ChapterCfg.ChapterId)
end

function XUiMainPanelRegional:OnBtnActDescClick()
    if self.ChapterCfg then
        local chapterId = self.ChapterCfg.ChapterId
        local chapterInfo = XPrequelConfigs.GetPrequelChapterInfoById(chapterId)
        local description = string.gsub(chapterInfo.ChapterDescription, "\\n", "\n")
        XUiManager.UiFubenDialogTip("", description)
    end
end

function XUiMainPanelRegional:OnRefresh(chapterCfg)
    self.ChapterCfg = chapterCfg
    self:RefreshStageList()
    self:UpdateRewardView()
end

function XUiMainPanelRegional:UpdateRewardView()
    if self.ChapterCfg then
        local chapterId = self.ChapterCfg.ChapterId
        self.ImgRedProgress.gameObject:SetActive(XDataCenter.PrequelManager.CheckRewardAvailable(chapterId))
        local totalNum, finishedNum = self:GetRewardTotalNumAndFinishNum(chapterId)
        self.TxtBfrtTaskTotalNum.text = totalNum
        self.TxtBfrtTaskFinishNum.text = finishedNum
        self.ImgJindu.fillAmount = finishedNum / totalNum * 1.0
    end
end

function XUiMainPanelRegional:UpdateCover()
    XEventManager.DispatchEvent(XEventId.EVENT_NOTICE_SELECTCOVER_CHANGE, {Cover = self.ChapterCfg, Index = self.CurrentSelectIdx})
end

function XUiMainPanelRegional:RefreshStageList()
    local prefabName = self.ChapterCfg.PrefabName
    if not prefabName or prefabName == "" then
        XLog.Error("XUiMainPanelRegional:OnChapterSelected错误 : 没找到预制体 prefabName = " .. tostring(prefabName))
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
        if not string.IsNilOrEmpty(self.ChapterCfg.UiBgPath) then
            local bg = asset.transform:Find("RImgChapterBg")
            if bg then
                bg:GetComponent("RawImage"):SetRawImage(self.ChapterCfg.UiBgPath)
            end
        end
    end
    self.CurrentPrequelGrid:UpdatePrequelGrid(self.ChapterCfg.StageId)
    self.CurrentPrequelGrid:Show()

    local chapterId = self.ChapterCfg.ChapterId
    local progressFinishedNum, progressTotalNum = XDataCenter.PrequelManager.GetChapterProgress(chapterId)
    self.TxtProgress.text = CS.XTextManager.GetText("UiPrequelTitleProgressStrFormat", progressFinishedNum, progressTotalNum)
    local totalNum, finishedNum = self:GetRewardTotalNumAndFinishNum(chapterId)
    self.TxtBfrtTaskTotalNum.text = totalNum
    self.TxtBfrtTaskFinishNum.text = finishedNum
    self.ImgRedProgress.gameObject:SetActive(XDataCenter.PrequelManager.CheckRewardAvailable(chapterId))
    self.ImgJindu.fillAmount = finishedNum / totalNum * 1.0
    
    -- local rect = XConditionManager.CheckCondition(self.ChapterCfg.ChallengeCondition)
    -- self.ImgLock.gameObject:SetActive(not rect)
    -- if true then
    -- else
    --     self.ImgLock.gameObject:SetActive(false)
    -- end
    if string.IsNilOrEmpty(self.ChapterCfg.RImgChapterNamePath) then
        XLog.Warning("间章标题图片路径为空值！设置失败！chapterId = " .. chapterId .. " 请检查Chapter.tab表")
        self.RImgChapterName.gameObject:SetActiveEx(false)
    else
        self.RImgChapterName:SetRawImage(self.ChapterCfg.RImgChapterNamePath)
        self.RImgChapterName.gameObject:SetActiveEx(true)
    end
end

function XUiMainPanelRegional:GetRewardTotalNumAndFinishNum(chapterId)
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

function XUiMainPanelRegional:SetPanelActive(isActive)
    if self.CurrentPrequelGrid then self.CurrentPrequelGrid.GameObject:SetActiveEx(isActive) end
    self.GameObject:SetActiveEx(isActive)
end

return XUiMainPanelRegional