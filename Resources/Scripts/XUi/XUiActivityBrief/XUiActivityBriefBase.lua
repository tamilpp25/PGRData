--[[    活动界面的功能相关和各版本的界面临时代码写在这里
    XUiActivityBriefRefreshButton.lua：活动按钮相关的代码（按钮的点击、刷新，红点显示、跳转）
    XActivityBrieIsOpen.lua：管理各按钮的开放条件与显示日期的代码
    XActivityBrieButton.lua：按钮的交互逻辑代码
]]
local XUiActivityBriefBase = XLuaUiManager.Register(XLuaUi, "UiActivityBriefBase")
local OpMovieId = CS.XGame.ClientConfig:GetInt("ActivityBriefMovie")
local CSXTextManagerGetText = CS.XTextManager.GetText
local XUiActivityBriefRefreshButton = require("XUi/XUiActivityBrief/XUiActivityBriefRefreshButton")

local Vector2 = CS.UnityEngine.Vector2

--@region 主要逻辑
function XUiActivityBriefBase:OnAwake()
    self.UiActivityBriefRefreshButton = XUiActivityBriefRefreshButton.New(self)

    self:AutoAddListener()
end

function XUiActivityBriefBase:OnStart()
    self.IsFromMain = true
    local firstOpen = XDataCenter.ActivityBriefManager.IsFirstOpen()
    if firstOpen and OpMovieId ~= 0 then
        self:PlayMovie(function()
            XDataCenter.ActivityBriefManager.SetNotFirstOpen()
            self:InitModel()
            self:PlayAnimationWithMask("AnimEnable2")
            --self:PlayEnterSpineAnimation()
        end)
    else
        self:PlayAnimationWithMask("AnimEnable2")
        --self:PlayEnterSpineAnimation()
        self:InitModel()
    end
    
    self:SpineAutoFit()
end

function XUiActivityBriefBase:OnEnable()
    local firstOpen = XDataCenter.ActivityBriefManager.IsFirstOpen()
    if firstOpen then
        XDataCenter.ActivityBriefManager.SetNotFirstOpen()
        --self:PlayEnterSpineAnimation()
    else
        if not self.IsFromMain then
            self:PlayAnimationWithMask("AnimEnable1")
            --self:PlayEnableSpineAnimation()
        end
    end
    self.IsFromMain = false
    self.UiActivityBriefRefreshButton:Refresh()
end

function XUiActivityBriefBase:OnDisable()
end

function XUiActivityBriefBase:OnDestroy()
end

--@endregion
--@region 监听事件
function XUiActivityBriefBase:AutoAddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnVideo, self.OnClickBtnVideo)
    self:RegisterClickEvent(self.BtnNotice, self.OnClickBtnDetail)
end

function XUiActivityBriefBase:OnBtnBackClick()
    self:Close()
end

function XUiActivityBriefBase:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiActivityBriefBase:OnClickBtnDetail()
    XLuaUiManager.Open("UiActivityBase")
end

function XUiActivityBriefBase:OnClickBtnVideo()
    --if self.PanelSpine then
    --    CS.UnityEngine.GameObject.Destroy(self.PanelSpine:GetComponent("XLoadSpinePrefab"))
    --end
    --if self.PanelSpine1 then
    --    CS.UnityEngine.GameObject.Destroy(self.PanelSpine1:GetComponent("XLoadSpinePrefab"))
    --end
    self:PlayMovie(function()
        self:PlayAnimationWithMask("AnimEnable2")
        --self:PlayEnterSpineAnimation()
    end)
end
--@endregion
--@region 初始化模型
function XUiActivityBriefBase:InitModel()
    -- if not self.RoleModelPanel then
    --     local models = XActivityBriefConfigs.GetActivityModels()
    --     if models and #models >= 1 then
    --         local root = self.UiModelGo.transform
    --         self.PanelModel = root:FindTransform("PanelModel")
    --         self.RoleModelPanel = XUiPanelRoleModel.New(self.PanelModel, self.Name, nil, true)
    --         self:LoadModel(models[XDataCenter.ActivityBriefManager.GetModelRankIndex()])
    --     end
    -- end
end

function XUiActivityBriefBase:LoadSpine(gameObject, index)
    local path = XActivityBriefConfigs.GetSpinePath(index)
    if not string.IsNilOrEmpty(path) then
        local obj = gameObject:LoadSpinePrefab(path):GetComponent("SkeletonAnimation")
        return obj
    end
end

--加载模型
function XUiActivityBriefBase:LoadModel(modelName)
    if not self.RoleModelPanel or modelName == "" then
        return
    end

    self.RoleModelPanel:UpdateBossModel(modelName, XModelManager.MODEL_UINAME.XUiActivityBriefBase, nil, function(model)
        --必须等延迟0.5秒后才执行(等动作执行完，不然Center节点的坐标会是动作执行前的坐标)
        XScheduleManager.ScheduleOnce(function()
            self:DoAutoRotateWeapon(model)
        end, 500)
    end, true)
    self.PanelModel.gameObject:SetActive(false)
    self.PanelModel.gameObject:SetActive(true)
end

function XUiActivityBriefBase:DoAutoRotateWeapon(model)
    local rotate = self.PanelModel:GetComponent("XAutoRotation")
    if rotate then
        rotate.RotateSelf = false
        rotate.Inited = true
        rotate.Target = model.transform
        rotate:SetCenterPoint(model.transform:Find("Bip001/Center"))
    end
end
--@endregion
--@region 通用函数
function XUiActivityBriefBase:PlayMovie(cbFunc)
    --此处不用self:SetActive, 由于self:SetActive会把uiModel的也隐藏导致无法播放下面的动画
    self.GameObject:SetActiveEx(false)

    XDataCenter.VideoManager.PlayMovie(OpMovieId, function()
        self.GameObject:SetActiveEx(true)
        if cbFunc then
            cbFunc()
        end
    end)
end

function XUiActivityBriefBase:PlayEnterSpineAnimation()
    if XTool.UObjIsNil(self.SpineObject1) then
        self.SpineObject1 = self:LoadSpine(self.PanelSpine1, 2)
    end
    self.SpineObject1.state:SetAnimation(0, "1", false)
    self.SpineObject1.state:AddAnimation(0, "2", false, 0)
    self.SpineObject1.state:AddAnimation(0, "loop1", true, 0)
    --Delegate += 操作Lua写法
    local completeCb
    completeCb = function(track)
        if track.Animation.Name == "1" then
            if XTool.UObjIsNil(self.SpineObject) then
                self.SpineObject = self:LoadSpine(self.PanelSpine, 1)
                self.SpineObject.state:SetAnimation(0, "loop2", true)
            end
            self.SpineObject1.state:Complete('-', completeCb)
        end
    end
    self.SpineObject1.state:Complete('+', completeCb)
end

function XUiActivityBriefBase:PlayEnableSpineAnimation()
    if XTool.UObjIsNil(self.SpineObject1) then
        self.SpineObject1 = self:LoadSpine(self.PanelSpine1, 2)
    end
    if XTool.UObjIsNil(self.SpineObject) then
        self.SpineObject = self:LoadSpine(self.PanelSpine, 1)
    end
    self.SpineObject1.state:SetAnimation(0, "loop1", true)
    self.SpineObject.state:SetAnimation(0, "loop2", true)
end

--播放场景预设上的Timeline
function XUiActivityBriefBase:PlayAnimationForScene(animName, cbFunc)
    local root = self.UiModelGo.transform
    local transform = root:FindTransform(animName)

    if transform then
        transform:PlayTimelineAnimation(cbFunc)
    end
end
--@endregion
--spine动画底边对齐适配
function XUiActivityBriefBase:SpineAutoFit()
    local transform = self.ActivitySpineLogin
    if XTool.UObjIsNil(transform) then return end

    local rate = transform.localScale.y / 60
    transform.anchoredPosition = Vector2(transform.anchoredPosition.x, transform.anchoredPosition.y * rate)
end