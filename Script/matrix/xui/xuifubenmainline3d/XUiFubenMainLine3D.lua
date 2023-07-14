local XUiFubenMainLine3D = XLuaUiManager.Register(XLuaUi,"UiFubenMainLine3D")
local XUiGridFubenMainLineStage = require("XUi/XUiFubenMainLine3D/XUiGridFubenMainLineStage")
local XUiGridFubenMainLineTheme = require("XUi/XUiFubenMainLine3D/XUiGridFubenMainLineTheme")
local XUiPanelStoryJump = require("XUi/XUiFubenMainLineChapter/XUiPanelStoryJump")
function XUiFubenMainLine3D:OnStart(chapterIndex,stageIndex,stageId)
    self:InitStageCfg()
    self:RegisterButton()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.GridTreasureList = {}
    self.GridMultipleWeeksTaskList = {}
    self.IsInChapter = false
    self.SelectChapter = nil
    self:InitScene()
    self.IsOnZhouMu = false
    self.BtnHelp.gameObject:SetActiveEx(false)
    self.RedPointId = XRedPointManager.AddRedPointEvent(self.ImgRedProgress, self.OnCheckRewards, self, { XRedPointConditions.Types.CONDITION_MAINLINE_TREASURE }, self.ChapterMainCfg.ChapterId[1], false)
    self:InitPanelStoryJump()
    if chapterIndex then
        self:OnSelectChapter(chapterIndex,function()
            if chapterIndex and stageIndex and stageId then
                self:OnSelectStage(chapterIndex, stageIndex, stageId)
            end
        end)
    end
    
    local record = XDataCenter.FubenMainLineManager.GetMainlineStageRecord()
    if record then
        self:OnSelectChapter(record.ChapterIndex)
    end
end

function XUiFubenMainLine3D:OnGetEvents()
    return { XEventId.EVENT_FUBEN_ENTERFIGHT }
end

--事件监听
function XUiFubenMainLine3D:OnNotify(evt, ...)
    if evt == XEventId.EVENT_FUBEN_ENTERFIGHT then
        self:EnterFight(...)
    end
end

function XUiFubenMainLine3D:OnEnable()
    self:RefreshTaskGuidePanel()
    self:UpdateChapterStars()
    self:PanelStoryJumpRefresh()
    XEventManager.AddEventListener(XEventId.EVENT_MAINLINE_SELECT_STAGE, self.OnSelectStage, self)
    XEventManager.AddEventListener(XEventId.EVENT_MAINLINE_SELECT_CHAPTER, self.OnSelectChapter, self)
    XEventManager.AddEventListener(XEventId.EVENT_FUBEN_CLOSE_FUBENSTAGEDETAIL,self.OnDetailClose,self)
end

function XUiFubenMainLine3D:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_MAINLINE_SELECT_STAGE, self.OnSelectStage, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_MAINLINE_SELECT_CHAPTER, self.OnSelectChapter, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FUBEN_CLOSE_FUBENSTAGEDETAIL,self.OnDetailClose,self)
end

function XUiFubenMainLine3D:OnDestroy()
    self.SceneStageCamera = {}
    self.SceneChapterCam = {}
    self.UiStageParent = {}
    self.UiStageCamera = {}
    self.UiChapterCamera  = {}
    self.UiChapterParent = {}
    self.UiChapterInfoParent = {}
    self.DragArea = {}
    self.GridStageDic = {}
    self.GridStage = {}
    self.GridChapterDic = {}
    self.GridTheme = {}
    self.GridTreasureList = {}
    self.GridMultipleWeeksTaskList = {}
    self.LineDic = {}
end

function XUiFubenMainLine3D:InitStageCfg()
    self.ChapterMainCfg = XDataCenter.FubenMainLineManager.GetChapterMainTemplate(XDataCenter.FubenMainLineManager.MainLine3DId)
    self.TxtName.text = self.ChapterMainCfg.ChapterName
    self.TxtEnglish.text = self.ChapterMainCfg.ChapterEn
    self.StageDic = {}
    for _,chapterId in pairs(self.ChapterMainCfg.SubChapter) do
        local chapterConfig = XFubenMainLineConfigs.GetSubChapterCfg(chapterId)
        self.StageDic[chapterId] = {}
        for _, stageId in pairs(chapterConfig.StageId) do
            table.insert(self.StageDic[chapterId], stageId)
        end
    end
end

function XUiFubenMainLine3D:InitScene()
    ---@type UnityEngine.Transform
    local root = self.UiModelGo.transform
    self.SceneStageCamera = {}
    self.SceneChapterCam = {}
    self.UiStageCamera = {}
    self.UiChapterCamera = {}
    self.DragArea = {}
    self.ChapterCameraOriginPos = {}
    self.LineDic = {}
    for i = 1, #self.ChapterMainCfg.SubChapter do
        local sceneChapterCamera = root:FindTransform("UiCamNearGrid" .. self:NumberFormat(i))
        local uiChapterCamera = root:FindTransform("UiCamGrid" .. self:NumberFormat(i))
        self.SceneChapterCam[i] = sceneChapterCamera
        self.UiChapterCamera[i] = uiChapterCamera
        self.ChapterCameraOriginPos[i] = sceneChapterCamera.localPosition
    end

    for index = 1, #self.ChapterMainCfg.SubChapter do
        local chapter = XFubenMainLineConfigs.GetSubChapterCfg(self.ChapterMainCfg.SubChapter[index])
        self.SceneStageCamera[index] = {}
        self.UiStageCamera[index] = {}
        for stageIndex = 1, #chapter.StageId do
            local sceneStageCamera = root:FindTransform("UiCamNearGrid" .. self:NumberFormat(index) .. "_" .. stageIndex)
            local uiStageCamera = root:FindTransform("UiCamGrid" .. self:NumberFormat(index) .. "_" .. stageIndex)
            self.SceneStageCamera[index][stageIndex] = sceneStageCamera
            self.UiStageCamera[index][stageIndex] = uiStageCamera
        end
    end
    self.GridStage = root:FindTransform("GridStage")
    self.GridTheme = root:FindTransform("GridTheme")
    self.PanelChapterParent = root:FindTransform("PanelChapterParent")
    self.UiStageParent = {}
    self.UiChapterInfoParent = {}
    self.GridChapterDic = {}
    self.GridStageDic = {}
    self.UiChapterParent = {}
    for chapterIndex = 1, #self.ChapterMainCfg.SubChapter do
        self.UiChapterParent[chapterIndex] = self.PanelChapterParent:FindTransform("Chapter" .. self:NumberFormat(chapterIndex))
        local stageParent = self.UiChapterParent[chapterIndex]:FindTransform("PanelStageParent")
        self.DragArea[chapterIndex] = self.UiChapterParent[chapterIndex]:FindTransform("DragArea" .. chapterIndex)
        self.UiChapterInfoParent[chapterIndex] = self.UiChapterParent[chapterIndex]:FindTransform("PanelInfoParent")
        local chapterCfg = XFubenMainLineConfigs.GetSubChapterCfg(self.ChapterMainCfg.SubChapter[chapterIndex])
        self.UiStageParent[chapterIndex] = {}
        ---@type UnityEngine.GameObject
        local themeObj = CS.UnityEngine.GameObject.Instantiate(self.GridTheme)
        themeObj.transform:SetParent(self.UiChapterInfoParent[chapterIndex]) 
        themeObj.transform.localPosition = CS.UnityEngine.Vector3.zero
        themeObj.transform.localScale = CS.UnityEngine.Vector3(0.2, 0.2, 0.2)
        themeObj.transform.localEulerAngles = CS.UnityEngine.Vector3.zero
        self.GridChapterDic[chapterIndex] = XUiGridFubenMainLineTheme.New(themeObj)
        self.GridChapterDic[chapterIndex]:Refresh(chapterCfg,chapterIndex)
        self.GridStageDic[chapterIndex] = {}
        self.LineDic[chapterIndex] = {}
        for stageIndex = 1, #chapterCfg.StageId do
            self.UiStageParent[chapterIndex][stageIndex] = stageParent:FindTransform("Stage" .. self:NumberFormat(stageIndex))
            self.LineDic[chapterIndex][stageIndex] = self.UiStageParent[chapterIndex][stageIndex]:FindTransform("LinePanel")
            ---@type UnityEngine.GameObject
            if self.UiStageParent[chapterIndex][stageIndex] then
                local stageObj = CS.UnityEngine.GameObject.Instantiate(self.GridStage)
                stageObj.transform:SetParent(self.UiStageParent[chapterIndex][stageIndex])
                stageObj.transform.localPosition = CS.UnityEngine.Vector3.zero
                stageObj.transform.localScale = CS.UnityEngine.Vector3(3.764705, 3.764705, 3.764705)
                stageObj.transform.localEulerAngles = CS.UnityEngine.Vector3(-90, 0, 0)
                self.GridStageDic[chapterIndex][stageIndex] = XUiGridFubenMainLineStage.New(stageObj)
                self.GridStageDic[chapterIndex][stageIndex]:Refresh(chapterIndex,stageIndex,chapterCfg.StageId[stageIndex])
            end
        end
    end
    self.AnimationDic = {}
    local animations = root:GetComponentsInChildren(typeof(CS.UnityEngine.Playables.PlayableDirector),true)
    XTool.LoopArray(animations,function(component)
        self.AnimationDic[component.gameObject.name] = component.gameObject
    end)
    
    self.GridTheme.gameObject:SetActiveEx(false)
    self.GridStage.gameObject:SetActiveEx(false)
end

function XUiFubenMainLine3D:RegisterButton()
    self.BtnMainUi.CallBack = function()
        XDataCenter.FubenMainLineManager.SetMainlineStageRecord()
        XLuaUiManager.RunMain()
    end
    self.BtnBack.CallBack = function()
        XDataCenter.FubenMainLineManager.SetMainlineStageRecord()
        if not self.IsInChapter then
            self:Close()
            return
        end
        self.IsInChapter = false
        self:ResetCamera()
        self:PanelStoryJumpRefresh()
    end
    self.BtnReceive.CallBack = function() 
        self:OnClickStageSkipBtn()
    end
    self.Mask.CallBack = function() 
        self:OnClickBtnMask()
    end
    self.BtnMap.CallBack = function() 
        self:OnClickBtnMap()
    end
    self.BtnTanchuangClose.CallBack = function() 
        self:OnBtnTreasureBgClick()
    end
    self:RegisterClickEvent(self.BtnTreasure, self.OnBtnTreasureClick)
    self:RegisterClickEvent(self.BtnTreasureBg, self.OnBtnTreasureBgClick)

end

function XUiFubenMainLine3D:ResetCamera(cb)
    for i, sceneChapterCam in pairs(self.SceneChapterCam) do
        sceneChapterCam.gameObject:SetActiveEx(false)
        sceneChapterCam.gameObject.transform.localPosition = self.ChapterCameraOriginPos[i]
    end
    for i, uiChapterCam in pairs(self.UiChapterCamera) do
        uiChapterCam.gameObject:SetActiveEx(false)
        uiChapterCam.gameObject.transform.localPosition = self.ChapterCameraOriginPos[i]
    end
    for _, chapterStageRoot in pairs(self.SceneStageCamera) do
        for _, sceneStageCam in pairs(chapterStageRoot) do
            sceneStageCam.gameObject:SetActiveEx(false)
        end
    end
    for _, chapterStageRoot in pairs(self.UiStageCamera) do
        for _, uiStageCam in pairs(chapterStageRoot) do
            uiStageCam.gameObject:SetActiveEx(false)
        end
    end

    for _, dragArea in pairs(self.DragArea) do
        dragArea.gameObject:SetActiveEx(false)
    end

    for _, uiChapterParent in pairs(self.UiChapterParent) do
        local stageParent = uiChapterParent:FindTransform("PanelStageParent")
        stageParent.gameObject:SetActiveEx(false)
    end
    self:CloseStageDetail()
    self.PanelBottom.gameObject:SetActiveEx(true)
    self.PanelStageSelect.gameObject:SetActiveEx(false)
    self:PlayAnimation("PanelStageMainEnable")
    if self.SelectChapter then
        local animationName = "Main" .. self:NumberFormat(self.SelectChapter) .. "Enable"
        self:PlaySceneAnimation(animationName,cb)
    end
end

function XUiFubenMainLine3D:RefreshStage()
    if not self.SelectChapter then
        return
    end
    local parent = self.UiChapterParent[self.SelectChapter]:FindTransform("PanelStageParent")
    parent.gameObject:SetActiveEx(true)
    for index,obj in pairs(self.UiStageParent[self.SelectChapter]) do
        local chapterId = self.ChapterMainCfg.SubChapter[self.SelectChapter]
        local chapterConfig = XFubenMainLineConfigs.GetSubChapterCfg(chapterId)
        local stageId = chapterConfig.StageId[index]
        local isUnlock = XDataCenter.FubenManager.CheckStageIsUnlock(stageId)
        self.GridStageDic[self.SelectChapter][index]:Refresh(self.SelectChapter, index, stageId)
        obj.gameObject:SetActiveEx(isUnlock)
    end
    for index,line in pairs(self.LineDic[self.SelectChapter]) do
        line.gameObject:SetActiveEx(true)
    end
end

function XUiFubenMainLine3D:RefreshChapter()
    for chapterIndex = 1, #self.ChapterMainCfg.SubChapter do
        local chapterCfg = XFubenMainLineConfigs.GetSubChapterCfg(self.ChapterMainCfg.SubChapter[chapterIndex])
        self.GridChapterDic[chapterIndex]:Refresh(chapterCfg,chapterIndex)
    end
end

function XUiFubenMainLine3D:RefreshTaskGuidePanel()
    self.TxtContent.text = ""
    self.TvtGuideTitle.text = CS.XTextManager.GetText("MainLine3DTaskGuideComplete")
    self.BtnReceive.gameObject:SetActiveEx(false)
    local chapterMainCfg = XDataCenter.FubenMainLineManager.GetChapterMainTemplate(XDataCenter.FubenMainLineManager.MainLine3DId)
    for chapterIndex,chapterId in pairs(chapterMainCfg.SubChapter) do
        for stageIndex, stageId in pairs(self.StageDic[chapterId]) do
            local isPass = XDataCenter.FubenManager.CheckStageIsPass(stageId)
            if not isPass then
                self.TvtGuideTitle.text = CS.XTextManager.GetText("MainLine3DTaskGuideTitle")
                local chapterCfg = XFubenMainLineConfigs.GetSubChapterCfg(chapterId)
                local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
                self.TxtContent.text = CS.XTextManager.GetText("MainLine3DTaskGuide", chapterCfg.OrderId, stageCfg.OrderId)
                self.SkipChapter = chapterIndex
                self.SkipStage = stageIndex
                self.SkipStageId = self.StageDic[chapterId][self.SkipStage]
                self.BtnReceive.gameObject:SetActiveEx(true)
                return
            end
        end
    end
end

function XUiFubenMainLine3D:OnClickStageSkipBtn()
    if not self.SkipChapter then
        return
    end
    if self.SkipChapter ~= self.SelectChapter then
        self:ResetCamera(function()
            self:OnSelectChapter(self.SkipChapter,function()
                self:OnSelectStage(self.SkipChapter,self.SkipStage,self.SkipStageId)
            end)
        end)
    else
        self:OnSelectStage(self.SkipChapter,self.SkipStage,self.SkipStageId)
    end
end

function XUiFubenMainLine3D:OnClickBtnMask()
    self.Mask.gameObject:SetActiveEx(false)
    self.UiStageCamera[self.SelectChapter][self.SelectStage].gameObject:SetActiveEx(false)
    self.SceneStageCamera[self.SelectChapter][self.SelectStage].gameObject:SetActiveEx(false)
    self:CloseStageDetail()
end

function XUiFubenMainLine3D:OnClickBtnMap()
    if not self.IsInChapter then
        return
    end
    self.IsInChapter = false
    self:ResetCamera()
    self:PanelStoryJumpRefresh()
end

function XUiFubenMainLine3D:OnSelectStage(chapterIndex,stageIndex,stageId)
    self.SelectStage = stageIndex
    self.Mask.gameObject:SetActiveEx(true)
    self.UiStageCamera[chapterIndex][stageIndex].gameObject:SetActiveEx(true)
    self.SceneStageCamera[chapterIndex][stageIndex].gameObject:SetActiveEx(true)
    self.PanelAsset.gameObject:SetActiveEx(false)
    for index,stage in pairs(self.UiStageParent[chapterIndex]) do
        if index ~= stageIndex then
            stage.gameObject:SetActiveEx(false)
        end
    end
    for index,line in pairs(self.LineDic[chapterIndex]) do
        line.gameObject:SetActiveEx(false)
    end
    XDataCenter.FubenMainLineManager.SetMainlineStageRecord({
        ChapterIndex = chapterIndex,
        StageIndex = stageIndex,
        StageId = stageId
    })
    local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
    if stageCfg.StageType == XFubenConfigs.STAGETYPE_STORY or stageCfg.StageType == XFubenConfigs.STAGETYPE_STORYEGG then
        self:OpenChildUi("UiMainLine3DStoryDetail",stageId)
    else
        self:OpenChildUi("UiMainLine3DFightDetail",stageId)
    end
end

function XUiFubenMainLine3D:OnSelectChapter(chapterIndex,cb)
    self.IsInChapter = true
    self.SceneChapterCam[chapterIndex].gameObject:SetActiveEx(true)
    self.UiChapterCamera[chapterIndex].gameObject:SetActiveEx(true)
    local animationName = "Chapter"..self:NumberFormat(chapterIndex).."Enable"
    self:PlaySceneAnimation(animationName,cb)
    self.DragArea[chapterIndex].gameObject:SetActiveEx(true)
    self.SelectChapter = chapterIndex
    local chapterId = self.ChapterMainCfg.SubChapter[self.SelectChapter]
    local chapterConfig = XFubenMainLineConfigs.GetSubChapterCfg(chapterId)
    self.TxtChapterName.text = chapterConfig.ChapterName
    self.TxtChapterEng.text = chapterConfig.ChapterEn
    self.PanelBottom.gameObject:SetActiveEx(false)
    self.PanelStageSelect.gameObject:SetActiveEx(true)
    self:PlayAnimationWithMask("PanelStageSelectEnable")
    self:RefreshStage()
    self:PanelStoryJumpRefresh()
end

function XUiFubenMainLine3D:OnDetailClose()
    if not (self.SelectStage and self.SelectChapter) then
        return
    end
    self:CloseStageDetail()
    for _,grid in pairs(self.GridStageDic[self.SelectChapter]) do
        grid:SetSelectState(false)
    end
    self:RefreshStage()
    self:RefreshTaskGuidePanel()
    self:RefreshChapter()
    self.Mask.gameObject:SetActiveEx(false)
    self.UiStageCamera[self.SelectChapter][self.SelectStage].gameObject:SetActiveEx(false)
    self.SceneStageCamera[self.SelectChapter][self.SelectStage].gameObject:SetActiveEx(false)
    self.PanelAsset.gameObject:SetActiveEx(true)
end

function XUiFubenMainLine3D:NumberFormat(number)
    return string.format("%02d", number)
end

function XUiFubenMainLine3D:PlaySceneAnimation(name,finishCb,startCb)
    ---@type UnityEngine.GameObject
    local gameObject = self.AnimationDic[name]
    if not gameObject then
        XLog.Error("XUiFubenMainLine3D:PlaySceneAnimation Error: Name:", name)
        return
    end
    gameObject:PlayTimelineAnimation(finishCb,startCb)
end

function XUiFubenMainLine3D:InitTreasureGrade()
    local baseItem = self.IsOnZhouMu and self.GridMultipleWeeksTask or self.GridTreasureGrade
    self.GridMultipleWeeksTask.gameObject:SetActiveEx(false)
    self.GridTreasureGrade.gameObject:SetActiveEx(false)

    -- 先把所有的格子隐藏
    for j = 1, #self.GridTreasureList do
        self.GridTreasureList[j].GameObject:SetActiveEx(false)
    end
    for j = 1, #self.GridMultipleWeeksTaskList do
        self.GridMultipleWeeksTaskList[j].GameObject:SetActiveEx(false)
    end

    local targetList = {}
    if self.IsOnZhouMu then
        targetList = XFubenZhouMuConfigs.GetZhouMuTasks(self.ZhouMuId)
    else
        local chapterCfg = XDataCenter.FubenMainLineManager.GetChapterCfg(self.ChapterMainCfg.ChapterId[1])
        targetList = chapterCfg.TreasureId
    end
    if not targetList then
        return
    end

    local offsetValue = 260
    local gridCount = #targetList

    for i = 1, gridCount do
        local offerY = (1 - i) * offsetValue
        local grid
        if self.IsOnZhouMu then
            grid = self.GridMultipleWeeksTaskList[i]
        else
            grid = self.GridTreasureList[i]
        end

        if not grid then
            local item = CS.UnityEngine.Object.Instantiate(baseItem)  -- 复制一个item
            grid = XUiGridTreasureGrade.New(self, item)
            grid.Transform:SetParent(self.PanelGradeContent, false)
            grid.Transform.localPosition = CS.UnityEngine.Vector3(item.transform.localPosition.x, item.transform.localPosition.y + offerY, item.transform.localPosition.z)
            if self.IsOnZhouMu then
                self.GridMultipleWeeksTaskList[i] = grid
            else
                self.GridTreasureList[i] = grid
            end

        end

        if self.IsOnZhouMu then
            grid:UpdateGradeGridTask(targetList[i])
        else
            local treasureCfg = XDataCenter.FubenMainLineManager.GetTreasureCfg(targetList[i])
            local chapterInfo = XDataCenter.FubenMainLineManager.GetChapterInfo(self.ChapterMainCfg.ChapterId[1])
            grid:UpdateGradeGrid(chapterInfo.Stars, treasureCfg, self.ChapterMainCfg.ChapterId[1])
        end

        grid:InitTreasureList()
        grid.GameObject:SetActiveEx(true)
    end
end

function XUiFubenMainLine3D:OnBtnTreasureClick()
    if self:CloseStageDetail() then
        return
    end
    self:InitTreasureGrade()
    self.PanelTreasure.gameObject:SetActiveEx(true)
    self.PanelTop.gameObject:SetActiveEx(false)
    self.PanelBottom.gameObject:SetActiveEx(false)
    self.PanelAsset.gameObject:SetActiveEx(false)
    self.BtnHelp.gameObject:SetActiveEx(false)
    self:PlayAnimation("TreasureEnable")
end

function XUiFubenMainLine3D:CloseStageDetail()
    if self:FindChildUiObj("UiMainLine3DStoryDetail") then
        self:CloseChildUi("UiMainLine3DStoryDetail")
    end
    if self:FindChildUiObj("UiMainLine3DFightDetail") then
        self:CloseChildUi("UiMainLine3DFightDetail")
    end
end

function XUiFubenMainLine3D:OnBtnTreasureBgClick()
    self.PanelTreasure.gameObject:SetActiveEx(false)
    self.PanelTop.gameObject:SetActiveEx(true)
    self.PanelBottom.gameObject:SetActiveEx(true)
    self.PanelAsset.gameObject:SetActiveEx(true)
end

-- 是否显示红点
function XUiFubenMainLine3D:OnCheckRewards(count, chapterId)
    if self.IsOnZhouMu then
        if self.ImgRedProgress and chapterId == self.ZhouMuId then
            self.ImgRedProgress.gameObject:SetActiveEx(count >= 0)
        end
    else
        if self.ImgRedProgress and chapterId == self.ChapterMainCfg.ChapterId[1] then
            self.ImgRedProgress.gameObject:SetActiveEx(count >= 0)
        end
    end
end

function XUiFubenMainLine3D:UpdateChapterStars()
    local curStars
    local totalStars
    local received = true

    self.PanelDesc.gameObject:SetActiveEx(true)

    if self.IsOnZhouMu then
        -- 周目奖励
        self.MultipleWeeksTxet.gameObject:SetActiveEx(true)
        self.TxtDesc.gameObject:SetActiveEx(false)
        self.ImgStarIcon.gameObject:SetActiveEx(false)

        curStars, totalStars = XDataCenter.FubenZhouMuManager.GetZhouMuTaskProgress(self.ZhouMuId)
        received = XDataCenter.FubenZhouMuManager.ZhouMuTaskIsAllFinish(self.ZhouMuId)

    else
        -- 主线收集奖励
        curStars, totalStars = XDataCenter.FubenMainLineManager.GetChapterStars(self.ChapterMainCfg.ChapterId[1])
        local chapterTemplate = XDataCenter.FubenMainLineManager.GetChapterCfg(self.ChapterMainCfg.ChapterId[1])

        for _, v in pairs(chapterTemplate.TreasureId) do
            if not XDataCenter.FubenMainLineManager.IsTreasureGet(v) then
                received = false
                break
            end
        end

        self.MultipleWeeksTxet.gameObject:SetActiveEx(false)
        self.TxtDesc.gameObject:SetActiveEx(true)
        self.ImgStarIcon.gameObject:SetActiveEx(true)

        XRedPointManager.Check(self.RedPointId, self.ChapterMainCfg.ChapterId[1])
    end

    self.ImgJindu.fillAmount = totalStars > 0 and curStars / totalStars or 0
    self.ImgJindu.gameObject:SetActiveEx(true)
    self.TxtStarNum.text = CS.XTextManager.GetText("Fract", curStars, totalStars)
    self.ImgLingqu.gameObject:SetActiveEx(received)
end

function XUiFubenMainLine3D:EnterFight(stage)
    if not XDataCenter.FubenManager.CheckPreFight(stage) then
        return
    end
    self:CloseStageDetail()
    self:OnDetailClose()
    if XDataCenter.BfrtManager.CheckStageTypeIsBfrt(stage.StageId) then
        --据点战副本类型先跳转到作战部署界面
        local groupId = XDataCenter.BfrtManager.GetGroupIdByBaseStage(stage.StageId)
        XLuaUiManager.Open("UiBfrtDeploy", groupId)
    else
        XLuaUiManager.Open("UiNewRoomSingle", stage.StageId)
    end

end

function XUiFubenMainLine3D:InitPanelStoryJump()
    ---@type XUiPanelStoryJump
    self.PanelStoryJump = XUiPanelStoryJump.New(self.PanelStoryJumpBottom, self)
end

function XUiFubenMainLine3D:PanelStoryJumpRefresh()
    if not self.IsInChapter then
        self.PanelStoryJump:Refresh(XDataCenter.FubenMainLineManager.MainLine3DId, XFubenConfigs.ChapterType.MainLine)
    else
        self.PanelStoryJump.GameObject:SetActiveEx(false)
    end
end

return XUiFubenMainLine3D