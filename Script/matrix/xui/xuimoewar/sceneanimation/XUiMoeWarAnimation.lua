local XMoeWarAnimationRole = require("XUi/XUiMoeWar/SceneAnimation/XMoeWarAnimationRole")

local Lerp = CS.UnityEngine.Mathf.Lerp
local mathFloor = math.floor

local MAX_RUNWAY_COUNT = 3 --跑道最大数量
local END_CAMERA_INDEX = 3--终场相机Index
local FOLLOW_ROLE_CAMERA_INDEXS = { 2, 4 }--跟随胜利角色的相机Index
local MowWarSceneAnimationFxGoalEffectPath = CS.XGame.ClientConfig:GetString("MowWarSceneAnimationFxGoalEffectPath")--终点特效路径
local MowWarSceneAnimationFxVictoryEffectPath = CS.XGame.ClientConfig:GetString("MowWarSceneAnimationFxVictoryEffectPath")--终点特效路径（胜利）

local XUiMoeWarAnimation = XLuaUiManager.Register(XLuaUi, "UiMoeWarAnimation")

function XUiMoeWarAnimation:OnAwake()
    self:RegisterButtonEvent()
    self.PanelStart.gameObject:SetActiveEx(false)
end

---@param closeCallback function 设置关闭回调时接管原有的关闭逻辑
---@param players 进入场景中的角色Id列表
---@param match XMoeWarMatch
function XUiMoeWarAnimation:OnStart(animGroupIds, winnerIndex, closeCallback, players, match)
    self.GroupIds = animGroupIds
    self.WinnerIndex = winnerIndex
    self.CloseCallback = closeCallback
    self.Players = players
    self.Match = match
    self:InitScene()
    self:InitRoles()
    self:PlayStartAnimation()
end

function XUiMoeWarAnimation:OnDisable()
    self:DestroyTimer()
end

function XUiMoeWarAnimation:OnDestroy()
    for _, role in pairs(self.Roles) do
        role:Dispose()
    end
end

function XUiMoeWarAnimation:OnGetEvents()
	return {
		XEventId.EVENT_MOE_WAR_ACTIVITY_END,
        XEventId.EVENT_MOE_WAR_UPDATE,
	}
end

function XUiMoeWarAnimation:OnNotify(event, ...)
	local args = { ... }
	if event == XEventId.EVENT_MOE_WAR_ACTIVITY_END then
		self.CloseCallback = function()
			XUiManager.TipText("MoeWarActivityOver")
			XLuaUiManager.RunMain()
		end
    elseif event == XEventId.EVENT_MOE_WAR_UPDATE then
        self.CloseCallback = function()
            XLuaUiManager.RunMain()
            XLuaUiManager.Open("UiMoeWarMain")
            XUiManager.TipText("MoeWarMatchEnd")
        end
	end
end

function XUiMoeWarAnimation:OnClose()
    if self.CloseCallback then
        self.CloseCallback()
        return
    end
    self:Close()
end

function XUiMoeWarAnimation:InitScene()
    local scene = self.UiSceneInfo.Transform
    local root = self.UiModelGo.transform
    local roleNum = #self.GroupIds

    --选手模型父节点
    local roleRoot
    local roleRoot2 = root:FindTransformWithSplit("Panel01")--两人
    local roleRoot3 = root:FindTransformWithSplit("Panel02")--三人
    if roleNum >= 3 then
        roleRoot = roleRoot3
        roleRoot2.gameObject:SetActiveEx(false)
        roleRoot3.gameObject:SetActiveEx(true)
    else
        roleRoot = roleRoot2
        roleRoot2.gameObject:SetActiveEx(true)
        roleRoot3.gameObject:SetActiveEx(false)
    end
    self.RoleParents = {
        roleRoot:FindTransform("PanelModelCase1"),
        roleRoot:FindTransform("PanelModelCase2"),
        roleRoot:FindTransform("PanelModelCase3"),
    }

    --跑道
    local paodao2 = scene:FindTransformWithSplit("SceneRunway_01")--两人
    local paodao3 = scene:FindTransformWithSplit("SceneRunway_01b")--三人
    paodao2.gameObject:SetActiveEx(roleNum == 2)
    paodao3.gameObject:SetActiveEx(roleNum >= 3)

    --人气显示
    for i = 1, MAX_RUNWAY_COUNT do
        self["PanelVote" .. i].gameObject:SetActiveEx(roleNum >= i)
    end

    --终点线特效
    self.GoalEffectRoot = scene:FindTransform("PanelEffectGoal")
    self.GoalEffectRoot.gameObject:SetLayerRecursively(CS.UnityEngine.LayerMask.NameToLayer("UiNear"))
    self.GoalEffectRoot:LoadPrefab(MowWarSceneAnimationFxGoalEffectPath, false)

    --角色相机
    self.CurRoleCamera = nil
    self.CameraRoles = {
        root:FindTransform("CameraRole1"):GetComponent("CinemachineVirtualCamera"),
        root:FindTransform("CameraRole2"):GetComponent("CinemachineVirtualCamera"),
        root:FindTransform("CameraRole3"):GetComponent("CinemachineVirtualCamera"),
        root:FindTransform("CameraRole4"):GetComponent("CinemachineVirtualCamera"),
    }

    --远景相机
    self.CurFarCamera = nil
    self.FarCameras = {
        root:FindTransform("CameraFar1"):GetComponent("CinemachineVirtualCamera"),
        root:FindTransform("CameraFar2"):GetComponent("CinemachineVirtualCamera"),
        root:FindTransform("CameraFar3"):GetComponent("CinemachineVirtualCamera"),
        root:FindTransform("CameraFar4"):GetComponent("CinemachineVirtualCamera"),
    }

    --当前跟随角色的虚拟相机Index
    self.FollowRoleCameraIndex = FOLLOW_ROLE_CAMERA_INDEXS[1]
end

function XUiMoeWarAnimation:InitRoles()
    self.Roles = {}
    local roleNum = #self.GroupIds

    for index, groupId in pairs(self.GroupIds) do
        index = index % MAX_RUNWAY_COUNT > 0 and index % MAX_RUNWAY_COUNT or MAX_RUNWAY_COUNT

        local parent = self.RoleParents[index]
        if not parent then
            XLog.Error("XUiMoeWarAnimation:InitRoles error: 找不到角色对应赛道, index: " .. index)
            break
        end

        --2条跑道时跑道下标1和2，3条跑道时跑道下标3~5
        local runwayIndex = roleNum >= MAX_RUNWAY_COUNT and index + 2 or index

        local switchCameraCb = function(index)
            if index ~= self.WinnerIndex then return end
            self:SwitchFollowRoleCamera()
        end

        local endAnimCb = handler(self, self.PlayEndAnimation)
        local goalAnimCb = handler(self, self.PlayGoalAnimation)
        local role = XMoeWarAnimationRole.New({
            Index = index,
            GroupId = groupId,
            Parent = parent,
            UiName = self.Name,
            Scene = self.UiSceneInfo.Transform,
            SwitchCameraCb = switchCameraCb,
            EndAnimCb = endAnimCb,
            GoalAnimCb = goalAnimCb,
            Ui = self["PanelVote" .. index],
            PlayerId = self.Players[index],
            RunwayIndex = runwayIndex,
            Match = self.Match})
        table.insert(self.Roles, role)
    end
end

function XUiMoeWarAnimation:SwitchFollowRoleCamera()
    local cameraIndex

    for _, index in pairs(FOLLOW_ROLE_CAMERA_INDEXS) do
        if index ~= self.FollowRoleCameraIndex then
            cameraIndex = index
            break
        end
    end

    local role = self.Roles[self.WinnerIndex]
    role:SetFollowCamera(self.CameraRoles[cameraIndex])
    role:SetFollowCamera(self.FarCameras[cameraIndex])

    for index, camera in pairs(self.CameraRoles) do
        camera.gameObject:SetActiveEx(index == cameraIndex)
    end
    for index, camera in pairs(self.FarCameras) do
        camera.gameObject:SetActiveEx(index == cameraIndex)
    end

    self.FollowRoleCameraIndex = cameraIndex
end

function XUiMoeWarAnimation:PlayCameraAnimationStart()
    if XTool.UObjIsNil(self.GameObject) then return end

    local cameraIndex = self.FollowRoleCameraIndex

    for index, camera in pairs(self.CameraRoles) do
        if index == cameraIndex then
            self.CurRoleCamera = camera
            camera.gameObject:SetActiveEx(true)
        else
            camera.gameObject:SetActiveEx(false)
        end
    end

    for index, camera in pairs(self.FarCameras) do
        if index == cameraIndex then
            self.CurFarCamera = camera
            camera.gameObject:SetActiveEx(true)
        else
            camera.gameObject:SetActiveEx(false)
        end
    end
end

function XUiMoeWarAnimation:PlayCameraAnimationEnd()
    local cameraIndex = END_CAMERA_INDEX

    for index, camera in pairs(self.CameraRoles) do
        camera.gameObject:SetActiveEx(index == cameraIndex)
    end

    for index, camera in pairs(self.FarCameras) do
        camera.gameObject:SetActiveEx(index == cameraIndex)
    end
end

function XUiMoeWarAnimation:RegisterButtonEvent()
    self.BtnMainUi.CallBack = function() XLuaUiManager.RunMain() end
    self.BtnBack.CallBack = handler(self, self.OnClickBtnClose)
    self.BtnSkip.CallBack = handler(self, self.OnClickBtnClose)
end

function XUiMoeWarAnimation:OnClickBtnClose()
    self:OnClose()
end

function XUiMoeWarAnimation:DestroyTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

--播放开场动画
function XUiMoeWarAnimation:PlayStartAnimation()
    local asynPlayAnim = asynTask(self.PlayAnimationWithMask, self)

    RunAsyn(function()
        --等待角色准备动作播放完毕
        asynWaitSecond(2)

        --播放镜头动画
        self:PlayCameraAnimationStart()

        --等待镜头动画播放完毕
        asynWaitSecond(1)

        --播放UI动画
        if XTool.UObjIsNil(self.PanelStart) then return end
        self.PanelStart.gameObject:SetActiveEx(true)
        asynPlayAnim("PanelStartEnable")
        if XTool.UObjIsNil(self.PanelStart) then return end
        self.PanelStart.gameObject:SetActiveEx(false)

        --UI动画播放完毕之后播放赛跑动画
        self:PlayRaceAnimation()
    end)
end

--播放所有赛道动画
function XUiMoeWarAnimation:PlayRaceAnimation()
    for index, role in pairs(self.Roles) do
        --相机跟随胜利者
        if index == self.WinnerIndex then
            role:SetFollowCamera(self.CurRoleCamera)
            role:SetFollowCamera(self.CurFarCamera)
        end

        role:Run()
    end
end

--播放终场动画
function XUiMoeWarAnimation:PlayEndAnimation(totalTime)

    RunAsyn(function()
        --播放相机转场动画
        self:PlayCameraAnimationEnd()

        --等待相机转场动画播放完毕
        asynWaitSecond(totalTime)

        --打开结束动画UI
        if XTool.UObjIsNil(self.GameObject) then return end
        XLuaUiManager.Open("UiMoeWarAnimationTips")

        --等待ui结束动画播到一半刚好遮挡住全屏时
        asynWaitSecond(0.6)

        --关闭本UI
        if XTool.UObjIsNil(self.GameObject) then return end
        self:OnClose()
    end)

end

--播放冲线特效
function XUiMoeWarAnimation:PlayGoalAnimation()
    if XTool.UObjIsNil(self.GoalEffectRoot) then return end
    self.GoalEffectRoot:LoadPrefab(MowWarSceneAnimationFxVictoryEffectPath, false)
    self.GoalEffectRoot.gameObject:SetActiveEx(false)
    self.GoalEffectRoot.gameObject:SetActiveEx(true)
end