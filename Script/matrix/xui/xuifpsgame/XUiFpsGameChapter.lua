---@class XUiFpsGameChapter : XLuaUi 活动关卡界面
---@field _Control XFpsGameControl
local XUiFpsGameChapter = XLuaUiManager.Register(XLuaUi, "UiFpsGameChapter")

local ColorNormal = CS.UnityEngine.Color(0, 252 / 255, 1, 1)
local ColorHard = CS.UnityEngine.Color(1, 86 / 255, 102 / 255, 1)

function XUiFpsGameChapter:OnAwake()
    self._Offset = Vector3.zero
    self._MaxStageNodeCount = tonumber(self._Control:GetClientConfigById("MaxStageNodeCount"))
    self._MaxCallNodeCount = tonumber(self._Control:GetClientConfigById("MaxCallNodeCount"))
    self.BtnTeach.CallBack = handler(self, self.OnBtnTeachClick)
end

function XUiFpsGameChapter:OnStart(chapter)
    local endTime = self._Control:GetActivityGameEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        end
    end)

    self._ChapterId = chapter
    self.TeachStageId = self._Control:GetTeachStageId()
    self._IsStory = self._ChapterId == XEnumConst.FpsGame.Story

    if self._ChapterId == XEnumConst.FpsGame.Story then
        self:BindHelpBtn(self.BtnHelp, "FpsGameStoryHelp")
    else
        self:BindHelpBtn(self.BtnHelp, "FpsGameChallengeHelp")
    end
    XUiHelper.NewPanelTopControl(self, self.TopControlVariable)
    self.TxtNum.text = self._Control:GetClientConfigById("Version")
    self.TxtStory.gameObject:SetActiveEx(chapter == XEnumConst.FpsGame.Story)
    self.TxtChallenge.gameObject:SetActiveEx(chapter == XEnumConst.FpsGame.Challenge)
    self.BtnTeach.gameObject:SetActiveEx(chapter == XEnumConst.FpsGame.Story and XTool.IsNumberValid(self.TeachStageId))

    self:InitScene()
    self:InitNode()
    self:SetPositions()
    self:RefreshChapterNodePos()
end

function XUiFpsGameChapter:OnEnable()
    self.Super.OnEnable(self)
    self:RefreshReward()
    self:RefreshChapter()
    self:RefreshCallNodeRedPoint()
    self:PlayCameraAnim()
    --self:ScrollTo()
end

function XUiFpsGameChapter:OnDisable()
    self.Super.OnDisable(self)
end

function XUiFpsGameChapter:OnDestroy()
    self._UiSceneObjs.Colider:RemoveAllListeners()
    for _, goInput in pairs(self._GoInputs) do
        goInput:RemoveAllListeners()
    end

    if self._NodePosTimer then
        XScheduleManager.UnSchedule(self._NodePosTimer)
        self._NodePosTimer = nil
    end

    if self._RewardTimer then
        XScheduleManager.UnSchedule(self._RewardTimer)
        self._RewardTimer = nil
    end
end

function XUiFpsGameChapter:InitScene()
    local sceneUrl = self._Control:GetClientConfigById("SceneUrl", self._ChapterId)
    local modelUrl = self._Control:GetClientConfigById("ModelUrl")
    self:LoadUiScene(sceneUrl, modelUrl)
    self._UiSceneObjs = {}
    XUiHelper.InitUiClass(self._UiSceneObjs, self.UiSceneInfo.Transform)
    self._UiModelObjs = {}
    XUiHelper.InitUiClass(self._UiModelObjs, self.UiModelGo.transform)
    -- 拖拽摄像机
    --self._UiSceneObjs.Colider:AddDragListener(function(eventData)
    --    self._UiModelObjs.PanelDrag:OnDrag(eventData)
    --end)

    if self._Control:GetTriggerEnableCameraAnim() then
        self._UiModelObjs.Enable:Play()
    end
end

--region 节点

function XUiFpsGameChapter:InitNode()
    ---@type XUiGridFpsGameChapter[]
    self._Stages = {}
    ---@type XUiGridFpsGameCall[]
    self._Calls = {}
    ---@type XGoInputHandler[]
    self._GoInputs = {}
    ---@type XTableFpsGameStage[]
    self._CallDatas = {}

    self:InitStageNode()
    self:InitCallNode()
end

function XUiFpsGameChapter:InitStageNode()
    local stages = self._Control:GetStagesByChapter(self._ChapterId)
    local stageCount = #stages
    -- 关卡节点
    XUiHelper.RefreshCustomizedList(self.GridChapter.parent, self.GridChapter, stageCount, function(index, go)
        local stage = stages[index]
        ---@type XUiGridFpsGameChapter
        local grid = require("XUi/XUiFpsGame/XUiGridFpsGameChapter").New(go, self, stage, index)
        grid:BindNode(self:GetStageNode(index)) -- 剧情关和挑战关用的是同一个模型
        self._Stages[index] = grid
        if XTool.IsNumberValid(stage.CallId) then
            table.insert(self._CallDatas, stage)
        end
    end)
    -- 隐藏额外的关卡节点
    for i = stageCount + 1, self._MaxStageNodeCount do
        self:SetNodeColliderEnable(i, false)
    end
end

function XUiFpsGameChapter:InitCallNode()
    -- 通讯节点
    local callNodeCount = #self._CallDatas
    XUiHelper.RefreshCustomizedList(self.GridCall.parent, self.GridCall, callNodeCount, function(index, go)
        local data = self._CallDatas[index]
        ---@type XUiGridFpsGameCall
        local grid = require("XUi/XUiFpsGame/XUiGridFpsGameCall").New(go, self, data.StageId, data.CallId)
        grid:BindNode(self:GetCallNode(index))
        self._Calls[index] = grid
    end, true)
    -- 隐藏额外的通讯节点
    for i = callNodeCount + 1, self._MaxCallNodeCount do
        local callNode = self:GetCallNode(i)
        if callNode then
            callNode.gameObject:SetActiveEx(false)
        end
    end
end

function XUiFpsGameChapter:RefreshChapter()
    for _, goInput in pairs(self._GoInputs) do
        goInput:RemoveAllListeners()
    end
    self._GoInputs = {}

    local unpassStageId = self._Control:GetCurUnpassStage(self._ChapterId)
    for index, grid in pairs(self._Stages) do
        grid:RefreshData()
        grid:CheckPanelNowShow(unpassStageId)
        local isActived = grid:IsNodeShow()
        ---@type XGoInputHandler
        local goInput = self._UiSceneObjs[string.format("GoInput%s", index)]
        if goInput and isActived then
            -- 设置3D节点点击事件
            goInput:AddPointerClickListener(function()
                grid:OnBtnChapterClick()
            end)
            --goInput:AddDragListener(function(eventData)
            --    self._UiModelObjs.PanelDrag:OnDrag(eventData)
            --end)
            self._GoInputs[index] = goInput
        end
        self:SetNodeColliderEnable(index, isActived)
    end

    for _, grid in pairs(self._Calls) do
        grid:RefreshData()
    end
end

function XUiFpsGameChapter:RefreshChapterNodePos()
    self._NodePosTimer = XScheduleManager.ScheduleForever(function()
        self:SetPositions()
    end, 10)
end

function XUiFpsGameChapter:SetPositions()
    for _, grid in pairs(self._Stages) do
        grid:RefreshPosition()
    end
    for _, grid in pairs(self._Calls) do
        grid:RefreshPosition()
    end
end

function XUiFpsGameChapter:RefreshCallNodeRedPoint()
    for _, grid in pairs(self._Calls) do
        grid:RefreshRedPoint()
    end
end

function XUiFpsGameChapter:SetViewPosToTransformLocalPosition(uiTransform, targetTransform)
    if XTool.UObjIsNil(self._UiModelObjs.UiFarCamera) then
        return
    end
    CS.XUiHelper.SetViewPosToTransformLocalPosition(self._UiModelObjs.UiFarCamera, uiTransform, targetTransform, self._Offset)
end

function XUiFpsGameChapter:PlayCameraAnim(nodeIdx)
    -- 7个普通关卡
    for i = 1, 7 do
        local camName = string.format("UiCamFarChapter%s", i)
        if self._UiModelObjs[camName] then
            self._UiModelObjs[camName].gameObject:SetActiveEx(self._ChapterId == XEnumConst.FpsGame.Story and i == nodeIdx)
        end
        camName = string.format("UiCamNearEasyChapter%s", i)
        if self._UiModelObjs[camName] then
            self._UiModelObjs[camName].gameObject:SetActiveEx(self._ChapterId == XEnumConst.FpsGame.Story and i == nodeIdx)
        end
    end
    -- 3个困难关卡
    for i = 1, 3 do
        local camName = string.format("UiCamFarHardChapter%s", i)
        if self._UiModelObjs[camName] then
            self._UiModelObjs[camName].gameObject:SetActiveEx(self._ChapterId == XEnumConst.FpsGame.Challenge and i == nodeIdx)
        end
        camName = string.format("UiCamNearHardChapter%s", i)
        if self._UiModelObjs[camName] then
            self._UiModelObjs[camName].gameObject:SetActiveEx(self._ChapterId == XEnumConst.FpsGame.Challenge and i == nodeIdx)
        end
    end
end

function XUiFpsGameChapter:SetNodeColliderEnable(nodeIdx, bo)
    ---@type UnityEngine.BoxCollider
    local boxCollider = self._UiSceneObjs[string.format("BoxCollider%s", nodeIdx)]
    if boxCollider then
        boxCollider.enabled = bo
    end
end

---@return UnityEngine.Transform
function XUiFpsGameChapter:GetStageNode(nodeIdx)
    local nodeName = string.format("Level%s", nodeIdx)
    local node = self._UiSceneObjs[nodeName]
    if not node then
        XLog.Error(string.format("节点[%s]不存在", nodeName))
    end
    return node
end

---@return UnityEngine.Transform
function XUiFpsGameChapter:GetCallNode(nodeIdx)
    local nodeName = string.format("Special%s", nodeIdx)
    local node = self._UiSceneObjs[nodeName]
    if not node then
        XLog.Error(string.format("节点[%s]不存在", nodeName))
    end
    return node
end

--function XUiFpsGameChapter:ScrollTo()
--    local datas = self._Control:GetStagesByChapter(self._ChapterId)
--    local nodeIdx
--    for i, data in ipairs(datas) do
--        local id = data.StageId
--        if not self._Control._Model:IsStagePass(id) then
--            nodeIdx = i
--            break
--        end
--    end
--    ---@type UnityEngine.RectTransform
--    local cameraFollowPoint = self._UiModelObjs.PanelDrag.Target
--    local gridPos = self:GetStageNode(nodeIdx or #datas)
--    cameraFollowPoint.position = gridPos.position
--end

--endregion

function XUiFpsGameChapter:RefreshReward()
    local rewards = self._Control:GetRewardsByChapter(self._ChapterId)
    if not self._RewardGrids then
        ---@type XUiGridFpsGameReward[]
        self._RewardGrids = {}
        XUiHelper.RefreshCustomizedList(self.GridReward.parent, self.GridReward, #rewards, function(index, go)
            self._RewardGrids[index] = require("XUi/XUiFpsGame/XUiGridFpsGameReward").New(go, self, self._ChapterId, rewards[index])
        end, true)
    end

    if self._RewardTimer then
        XScheduleManager.UnSchedule(self._RewardTimer)
        self._RewardTimer = nil
    end

    local cur, all = self._Control:GetProgress(self._ChapterId)
    self.TxtCurNum.text = cur
    self.TxtCurNum.color = self._IsStory and ColorNormal or ColorHard
    self.TxtAllNum.text = string.format("/%s", all)

    local progress = 0
    for _, grid in ipairs(self._RewardGrids) do
        grid:Refresh()
        if grid:GetState() ~= XEnumConst.FpsGame.Reward.None then
            progress = progress + 1
        end
    end

    if self._IsStory then
        self.ImgProgress.fillAmount = progress / #rewards
    else
        self.ImgProgressRed.fillAmount = progress / #rewards
    end
    self.ImgProgress.gameObject:SetActiveEx(self._IsStory)
    self.ImgStarBlue.gameObject:SetActiveEx(self._IsStory)
    self.ImgProgressRed.gameObject:SetActiveEx(not self._IsStory)
    self.ImgStarRed.gameObject:SetActiveEx(not self._IsStory)
    
    -- 异形屏不延迟的话 拿到的rect.width是错的
    self._RewardTimer = XScheduleManager.ScheduleOnce(function()
        local space = self.ImgBar.rect.width / #rewards
        self.Content.spacing = space - self.GridReward.rect.width
        self.Content.padding.left = math.ceil(space) -- 有小数的话会设置失败
    end, 1)
end

function XUiFpsGameChapter:OnBtnTeachClick()
    XLuaUiManager.Open("UiFpsGameChooseWeapon", self.TeachStageId)
end

return XUiFpsGameChapter