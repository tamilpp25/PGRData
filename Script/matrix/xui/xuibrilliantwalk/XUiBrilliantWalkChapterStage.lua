--主线章节 关卡选择界面
local XUiBrilliantWalkChapterStage = XLuaUiManager.Register(XLuaUi, "UiBrilliantWalkChapterStage")
local XUIBrilliantWalkMiniTaskPanel = require("XUi/XUiBrilliantWalk/ModuleSubPanel/XUIBrilliantWalkMiniTaskPanel")--任务miniUI
local XUIBrilliantWalkStageGrid = require("XUi/XUiBrilliantWalk/XUIGrid/XUIBrilliantWalkStageGrid")
 
local XUguiDragProxy = CS.XUguiDragProxy

function XUiBrilliantWalkChapterStage:OnAwake()
    --关卡方格列表
    self.GridStageItemList = {} --地图中的空格Gameobject
    self.StageItemList = {} --每个空格单元中读取perfab的实例
    --支线关卡方格列表
    self.GridSubStageItemList = {} --地图中支线关卡空格Gameobject
    self.SubStageItemList = {} --每个支线关卡空格单元中读取perfab的实例
    --界面右边普通模块界面
    self.UiTaskPanel = XUIBrilliantWalkMiniTaskPanel.New(self.BtnTask,self)
    
    self.BtnMainUi.CallBack =  function()
        self:OnBtnMainUiClick()
    end
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    self.BtnHelp.CallBack = function()
        self:OnBtnHelpClick()
    end
end
function XUiBrilliantWalkChapterStage:OnEnable(openUIData)
    XEventManager.AddEventListener(XEventId.EVENT_BRILLIANT_WALK_UPDATE_STAGE_VIEW, self.UpdateView, self)
    self.UiTaskPanel:OnEnable()
    self.ChapterId = openUIData.ChapterID
    self:UpdateView()
    self.ParentUi:SwitchSceneCamera(XBrilliantWalkCameraType.Chapter)
end
function XUiBrilliantWalkChapterStage:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_BRILLIANT_WALK_UPDATE_STAGE_VIEW, self.UpdateView, self)
    self.UiTaskPanel:OnDisable()
end
--关闭详情界面
function XUiBrilliantWalkChapterStage:CloseStageDetial()
    if self.OpenUiFubenBrilliantWalkDetail then
        self.ParentUi:CloseMiniSubUI("UiFubenBrilliantWalkDetail")
        self.ParentUi:CloseMiniSubUI("UiFubenBrilliantWalkStoryDetail")
        self.OpenUiFubenBrilliantWalkDetail = false
        self:CancelItemSelect()
        self.ScrollRect.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
        return true
    end
    return false
end
--取消选中关卡高亮
function XUiBrilliantWalkChapterStage:CancelItemSelect()
    if self.SelectItem then
        self.SelectItem:SetSelect(false)
        self.SelectItem = nil
    end
end
--刷新界面
function XUiBrilliantWalkChapterStage:UpdateView()
    local uiData = XDataCenter.BrilliantWalkManager.GetUiDataStageSelect(self.ChapterId)
    local chapterConfig = uiData.ChapterConfig
    self.TextName.text = chapterConfig.Name
    if not (self.ChapterId == self.ViewChapterId) then
        --读取Perfab 创建关卡滑动图并初始化
        local chapterPerfab = self.ContentChapter:LoadPrefab(chapterConfig.PrefabName)
        local chapterObject = {}
        XTool.InitUiObjectByUi(chapterObject,chapterPerfab)
        self.ScrollRect = chapterObject.PaneStageList:GetComponent("ScrollRect")
        --获取滑动图 拖动组件 注册拖动事件
        self.PanelStageContent = chapterObject.PanelStageContent
        local dragProxy = chapterObject.PaneStageList:GetComponent(typeof(XUguiDragProxy))
        if not dragProxy then
            dragProxy = chapterObject.PaneStageList.gameObject:AddComponent(typeof(XUguiDragProxy))
        end
        dragProxy:RegisterHandler(handler(self, self.OnDragProxy))
        self.ViewChapterId = self.ChapterId --记录显示的章节信息 以免重复加载
    end
    --读取关卡信息 加载关卡格子 如果配置关卡数大于滑动图关卡数，则多出关卡不予显示。
    self.GridStageItemList = {}
    local stageConfigs = {}
    local index = 1
    local grid = self.PanelStageContent.transform:Find("Stage1")
    while grid do --遍历滑动图的关卡格子
        table.insert(self.GridStageItemList,grid)
        local stageId = chapterConfig.MainStageIds[index] --读取章节配置里的关卡信息
        --如果存在配置 并且 关卡已解锁
        if stageId and XDataCenter.BrilliantWalkManager.GetStageUnlockData(stageId) then
            --创建关卡格子
            stageConfigs[index] =XBrilliantWalkConfigs.GetStageConfig(stageId)
            local itemPerfab = self.GridStageItemList[index]:LoadPrefab(CS.XGame.ClientConfig:GetString(stageConfigs[index].PerfabType))
            local item = XUIBrilliantWalkStageGrid.New(itemPerfab,self)
            item:Refresh(stageId,self.ChapterId)
            table.insert(self.StageItemList,item)
            self.GridStageItemList[index].gameObject:SetActiveEx(true)

            local line = self.PanelStageContent.transform:Find("Line" .. (index-1))
            if line then
                line.gameObject:SetActiveEx(true)
            end
        else
            --没配置的关卡也不出现连线
            local line = self.PanelStageContent.transform:Find("Line" .. (index-1))
            if line then
                line.gameObject:SetActiveEx(false)
            end
            self.GridStageItemList[index].gameObject:SetActiveEx(false)
        end
        index = index + 1
        grid = self.PanelStageContent.transform:Find("Stage" .. index)
    end
    --支线关卡
    self.GridSubStageItemList = {}
    index = 1
    grid = self.PanelStageContent.transform:Find("Skip1")
    while grid do --遍历滑动图的支线关卡格子
        table.insert(self.GridSubStageItemList,grid)
        local stageId = chapterConfig.SideStageIds[index] --读取章节配置里的关卡信息
        --如果存在配置 并且 关卡已解锁
        if stageId and XDataCenter.BrilliantWalkManager.GetStageUnlockData(stageId) then
            --创建关卡格子
            stageConfigs[index] = XBrilliantWalkConfigs.GetStageConfig(stageId)
            local itemPerfab = self.GridSubStageItemList[index]:LoadPrefab(CS.XGame.ClientConfig:GetString(stageConfigs[index].PerfabType))
            local item = XUIBrilliantWalkStageGrid.New(itemPerfab,self,function(item)
                self:OnBtnStageClick(stageId)
                item:SetSelect(true)
                self.SelectItem = item
            end)
            item:Refresh(stageId,self.ChapterId)
            table.insert(self.SubStageItemList,item)
            self.GridSubStageItemList[index].gameObject:SetActiveEx(true)
        else
            self.GridSubStageItemList[index].gameObject:SetActiveEx(false)
        end
        index = index + 1
        grid = self.PanelStageContent.transform:Find("Skip" .. index)
    end

    --任务miniUI视图
    self.UiTaskPanel:UpdateView()
end
--滑动界面拖动时回调
function XUiBrilliantWalkChapterStage:OnDragProxy()
    self:CloseStageDetial()
end
--滑动到某个Grid
function XUiBrilliantWalkChapterStage:PlayScrollViewMove(grid)
    self.ScrollRect.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted
    local gridTfPosX = grid:GetParentLocalPosX()
    local diffX = gridTfPosX + self.PanelStageContent.localPosition.x
    if diffX < XDataCenter.BrilliantWalkManager.UiGridChapterMoveMinX or diffX > XDataCenter.BrilliantWalkManager.UiGridChapterMoveMaxX then
        local tarPosX = XDataCenter.BrilliantWalkManager.UiGridChapterMoveTargetX - gridTfPosX
        local tarPos = self.PanelStageContent.localPosition
        tarPos.x = tarPosX
        XLuaUiManager.SetMask(true)
        -- 动画
        XUiHelper.DoMove(self.PanelStageContent, tarPos, XDataCenter.BrilliantWalkManager.UiGridChapterMoveDuration, XUiHelper.EaseType.Sin, function()
            XLuaUiManager.SetMask(false)
        end)
    end
end
--关闭关卡详情时 滚动界面回滚(未实现)
function XUiBrilliantWalkChapterStage:ScrollRectRollBack()
    -- 滚动容器回弹
    local width = self.RectTransform.rect.width
    local innerWidth = self.PanelStageContent.rect.width
    innerWidth = innerWidth < width and width or innerWidth
    local diff = innerWidth - width
    local tarPosX
    if self.PanelStageContent.localPosition.x < -width / 2 - diff then
        tarPosX = -width / 2 - diff
    elseif self.PanelStageContent.localPosition.x > -width / 2 then
        tarPosX = -width / 2
    else
        -- self.ScrollRect.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted
        self.ScrollRect.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
        return false
    end

    self:PlayScrollViewMoveBack(tarPosX)
    return true
end
--点击关卡详情时 滚动到具体关卡(未实现)
function XUiBrilliantWalkChapterStage:PlayScrollViewMoveBack(tarPosX)
    local tarPos = self.PanelStageContent.localPosition
    tarPos.x = tarPosX
    XLuaUiManager.SetMask(true)

    XUiHelper.DoMove(self.PanelStageContent, tarPos, XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration, XUiHelper.EaseType.Sin, function()
        -- self.ScrollRect.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted
        self.ScrollRect.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
        XLuaUiManager.SetMask(false)
    end)
end
--点击关卡滑块
function XUiBrilliantWalkChapterStage:OnStageGridClick(grid, stageId)
    self:CancelItemSelect()
    grid:SetSelect(true)
    self.SelectItem = grid
    self:OnBtnStageClick(stageId)
    self:PlayScrollViewMove(grid)
end
--点击返回按钮
function XUiBrilliantWalkChapterStage:OnBtnBackClick()
    if self:CloseStageDetial() then
        return
    end
    self.ParentUi:CloseStackTopUi()
end
--点击主界面按钮
function XUiBrilliantWalkChapterStage:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end
--点击感叹号按钮
function XUiBrilliantWalkChapterStage:OnBtnHelpClick()
    self:CloseStageDetial()
    XUiManager.ShowHelpTip("BrilliantWalk")
end
--点击关卡按钮
function XUiBrilliantWalkChapterStage:OnBtnStageClick(stageId)
    self.OpenUiFubenBrilliantWalkDetail = true
    if XDataCenter.BrilliantWalkManager.CheckStageIsMovieStage(stageId) then
        self.ParentUi:OpenMiniSubUI("UiFubenBrilliantWalkStoryDetail",{
            StageId = stageId,
            StageEnterCallback = function(stageId)
                self:OnBtnEnterClick(stageId)
            end,
            CloseCallback = function()
                self:CloseStageDetial()
            end
        })
    else
        self.ParentUi:OpenMiniSubUI("UiFubenBrilliantWalkDetail",{
            StageId = stageId,
            StageEnterCallback = function(stageId)
                self:OnBtnEnterClick(stageId)
            end,
            PluginSkipCallback = function(pluginId)
                self:OnBtnPluginSkipClick(pluginId)
            end,
            CloseCallback = function()
                self:CloseStageDetial()
            end
        }) 
    end
end
--点击开始战斗
function XUiBrilliantWalkChapterStage:OnBtnEnterClick(stageId)
    self:CloseStageDetial()
    if XDataCenter.BrilliantWalkManager.CheckStageIsMovieStage(stageId) then
        XDataCenter.BrilliantWalkManager.EnterStage(stageId)
    else
        self.ParentUi:OpenStackSubUi("UiBrilliantWalkEquipment",{StageId = stageId})
    end
end
--点击任务按钮
function XUiBrilliantWalkChapterStage:OnBtnTaskClick()
    self:CloseStageDetial()
    self.ParentUi:OpenStackSubUi("UiBrilliantWalkTask")
end
--点击插件跳转
function XUiBrilliantWalkChapterStage:OnBtnPluginSkipClick(pluginId)
    self:CloseStageDetial()
    XDataCenter.BrilliantWalkManager.SkipToPluginUi(pluginId)
end 