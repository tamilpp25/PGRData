--主线章节 关卡选择界面
local XUiBrilliantWalkChapterBoss = XLuaUiManager.Register(XLuaUi, "UiBrilliantWalkChapterBoss")
local XUIBrilliantWalkMiniTaskPanel = require("XUi/XUiBrilliantWalk/ModuleSubPanel/XUIBrilliantWalkMiniTaskPanel")--任务miniUI
local XUIBrilliantWalkBossStageGrid = require("XUi/XUiBrilliantWalk/XUIGrid/XUIBrilliantWalkBossStageGrid")

local XUguiDragProxy = CS.XUguiDragProxy


function XUiBrilliantWalkChapterBoss:OnAwake()
    --关卡方格列表
    self.GridStageItemList = {} --地图中的空格Gameobject
    self.StageItemList = {} --每个空格单元中读取perfab的实例
    --界面右边普通模块界面
    self.UiTaskPanel = XUIBrilliantWalkMiniTaskPanel.New(self.BtnTask,self)
    --按钮事件
    self.BtnMainUi.CallBack =  function()
        self:OnBtnMainUiClick()
    end
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    self.BtnSwitchHard.CallBack = function()
        self:OnBtnSwitchHardClick()
    end
    self.BtnSwitchNormal.CallBack = function()
        self:OnBtnSwitchNormalClick()
    end
    self.BtnHelp.CallBack = function()
        self:OnBtnHelpClick()
    end
end
function XUiBrilliantWalkChapterBoss:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_BRILLIANT_WALK_UPDATE_STAGE_VIEW, self.UpdateView, self)
    self.UiTaskPanel:OnEnable()
    self:UpdateView()
    self.ParentUi:SwitchSceneCamera(XBrilliantWalkCameraType.Chapter)
end
function XUiBrilliantWalkChapterBoss:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_BRILLIANT_WALK_UPDATE_STAGE_VIEW, self.UpdateView, self)
    self.UiTaskPanel:OnDisable()
end

--切换普通/挑战界面
function XUiBrilliantWalkChapterBoss:SwitchDifficult(difficult)
    if difficult == XBrilliantWalkBossChapterDifficult.Normal then
        XDataCenter.BrilliantWalkManager.SetDifficultCache(difficult)
        self:UpdateView()
    elseif difficult == XBrilliantWalkBossChapterDifficult.Hard then
        XDataCenter.BrilliantWalkManager.SetDifficultCache(difficult)
        self:UpdateView()
    end
end
--关闭详情界面
function XUiBrilliantWalkChapterBoss:CloseStageDetial()
    if self.OpenUiFubenBrilliantWalkDetail then
        self.ParentUi:CloseMiniSubUI("UiFubenBrilliantWalkBossDetail")
        self.OpenUiFubenBrilliantWalkDetail = false
        self:CancelItemSelect()
        self.ScrollRect.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
        return true
    end
    return false
end
--取消选中关卡高亮
function XUiBrilliantWalkChapterBoss:CancelItemSelect()
    if self.SelectItem then
        self.SelectItem:SetSelect(false)
        self.SelectItem = nil
    end
end
--刷新界面
function XUiBrilliantWalkChapterBoss:UpdateView()
    local difficult = XDataCenter.BrilliantWalkManager.GetDifficultCache()
    --按钮样式
    if difficult == XBrilliantWalkBossChapterDifficult.Normal then
        self.BtnSwitchHard.gameObject:SetActiveEx(true)
        self.BtnSwitchNormal.gameObject:SetActiveEx(false)
    elseif difficult == XBrilliantWalkBossChapterDifficult.Hard then
        self.BtnSwitchHard.gameObject:SetActiveEx(false)
        self.BtnSwitchNormal.gameObject:SetActiveEx(true)
    end
    --读取Perfab 创建关卡滑动图并初始化
    local UiData = XDataCenter.BrilliantWalkManager.GetUiDataBossStageSelect()
    local chapterConfig = UiData.ChapterConfig
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
    --读取关卡信息 加载关卡格子 如果配置关卡数大于滑动图关卡数，则多出关卡不予显示。
    local stageIds = chapterConfig.MainStageIds
    if difficult == XBrilliantWalkBossChapterDifficult.Hard then
        stageIds = chapterConfig.SideStageIds
    end
    self.GridStageItemList = {}
    local index = 1
    local grid = self.PanelStageContent.transform:Find("Stage1")
    while grid do --遍历滑动图的关卡格子
        table.insert(self.GridStageItemList,grid)
        local stageId = stageIds[index] --读取章节配置里的关卡信息
        if stageId then
            --创建关卡格子
            local stageConfig =XBrilliantWalkConfigs.GetStageConfig(stageId)
            local itemPerfab = self.GridStageItemList[index]:LoadPrefab(CS.XGame.ClientConfig:GetString(stageConfig.PerfabType))
            local item = XUIBrilliantWalkBossStageGrid.New(itemPerfab,self)
            item:Refresh(stageId,self.ChapterId)
            table.insert(self.StageItemList,item)
            self.GridStageItemList[index].gameObject:SetActiveEx(true)

            local line = self.PanelStageContent.transform:Find("Line" .. (index-1))
            if line then
                line.gameObject:SetActiveEx(true)
            end
        else
            --无数据关卡不显示路线 线条
            local line = self.PanelStageContent.transform:Find("Line" .. (index-1))
            if line then
                line.gameObject:SetActiveEx(false)
            end
            self.GridStageItemList[index].gameObject:SetActiveEx(false)
        end
        index = index + 1
        grid = self.PanelStageContent .transform:Find("Stage" .. index)
    end

    --任务miniUI视图
    self.UiTaskPanel:UpdateView()
end
--滑动界面拖动时回调
function XUiBrilliantWalkChapterBoss:OnDragProxy()
    self:CloseStageDetial()
end
--滑动到某个Grid
function XUiBrilliantWalkChapterBoss:PlayScrollViewMove(grid)
    self.ScrollRect.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted
    local gridTfPosX = grid:GetParentLocalPosX()
    local diffX = gridTfPosX + self.PanelStageContent.localPosition.x
    if diffX < XDataCenter.BrilliantWalkManager.UiGridBossChapterMoveMinX or diffX > XDataCenter.BrilliantWalkManager.UiGridBossChapterMoveMaxX then
        local tarPosX = XDataCenter.BrilliantWalkManager.UiGridBossChapterMoveTargetX - gridTfPosX
        local tarPos = self.PanelStageContent.localPosition
        tarPos.x = tarPosX
        XLuaUiManager.SetMask(true)
        -- 动画
        XUiHelper.DoMove(self.PanelStageContent, tarPos, XDataCenter.BrilliantWalkManager.UiGridBossChapterMoveDuration, XUiHelper.EaseType.Sin, function()
            XLuaUiManager.SetMask(false)
        end)
    end
end
--点击关卡滑块
function XUiBrilliantWalkChapterBoss:OnStageGridClick(grid, stageId)
    self:CancelItemSelect()
    grid:SetSelect(true)
    self.SelectItem = grid
    self:OnBtnStageClick(stageId)
    self:PlayScrollViewMove(grid)
end
--点击返回按钮
function XUiBrilliantWalkChapterBoss:OnBtnBackClick()
    if self:CloseStageDetial() then
        return
    end
    self.ParentUi:CloseStackTopUi()
end
--点击主界面按钮
function XUiBrilliantWalkChapterBoss:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end
--点击感叹号按钮
function XUiBrilliantWalkChapterBoss:OnBtnHelpClick()
    self:CloseStageDetial()
    XUiManager.ShowHelpTip("BrilliantWalk")
end
--点击挑战按钮
function XUiBrilliantWalkChapterBoss:OnBtnSwitchHardClick()
    self:SwitchDifficult(XBrilliantWalkBossChapterDifficult.Hard)
    self:PlayAnimationWithMask("QieHuan")
end
--点击普通按钮
function XUiBrilliantWalkChapterBoss:OnBtnSwitchNormalClick()
    self:SwitchDifficult(XBrilliantWalkBossChapterDifficult.Normal)
    self:PlayAnimationWithMask("QieHuan")
end
--点击关卡按钮
function XUiBrilliantWalkChapterBoss:OnBtnStageClick(stageId)
    self.OpenUiFubenBrilliantWalkDetail = true
    self.ParentUi:OpenMiniSubUI(
        "UiFubenBrilliantWalkBossDetail",{
            StageId = stageId,
            StageEnterCallback = function(stageId)
                self:OnBtnEnterClick(stageId)
            end,
            PluginSkipCallback = function(pluginId)
                self:OnBtnPluginSkipClick(pluginId)
            end,
            AttentionCallback = function()
                self:CloseStageDetial()
                self.ParentUi:OpenMiniSubUI("UiBrilliantWalkAttention",{StageId = stageId})
            end,
            CloseCallback = function()
                self:CloseStageDetial()
            end
        }
    )
end
--点击开始战斗
function XUiBrilliantWalkChapterBoss:OnBtnEnterClick(stageId)
    self:CloseStageDetial()
    self.ParentUi:OpenStackSubUi("UiBrilliantWalkEquipment",{StageId = stageId})
end
--点击任务按钮
function XUiBrilliantWalkChapterBoss:OnBtnTaskClick()
    self:CloseStageDetial()
    self.ParentUi:OpenStackSubUi("UiBrilliantWalkTask")
end
--点击插件跳转
function XUiBrilliantWalkChapterBoss:OnBtnPluginSkipClick(pluginId)
    self:CloseStageDetial()
    XDataCenter.BrilliantWalkManager.SkipToPluginUi(pluginId)
end 