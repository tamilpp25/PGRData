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
local PanelType = {
    Main = 1,
    Second = 2,
}
--@region 主要逻辑
function XUiActivityBriefBase:OnAwake()
    self:AutoAddListener()
end

function XUiActivityBriefBase:OnStart(type)
    self.IsFromMain = true
    self.PanelType = type or PanelType.Main
    self.SpineObj = {}
    
    self.UiActivityBriefRefreshButton = XUiActivityBriefRefreshButton.New(self, self.PanelType)
    self:RefreshPanel()
    if self.PanelType == PanelType.Main then
        local firstOpen = XDataCenter.ActivityBriefManager.IsFirstOpen()
        if firstOpen and OpMovieId ~= 0 then
            self:PlayMovie(function()
                XDataCenter.ActivityBriefManager.SetNotFirstOpen()
                self:PlayAnimationWithMask("AnimEnable2")
                self:PlayEnterSpineAnimation()
            end)
        else
            self:PlayAnimationWithMask("AnimEnable2")
            self:PlayEnterSpineAnimation()
        end
    end
    self:SpineAutoFit()
end

function XUiActivityBriefBase:OnEnable()
    local firstOpen = XDataCenter.ActivityBriefManager.IsFirstOpen()
    if firstOpen then
        XDataCenter.ActivityBriefManager.SetNotFirstOpen()
        --self:PlayEnterSpineAnimation()
    else
        if not self.IsFromMain and self.PanelType == PanelType.Main then
            -- 避免跳转玩法界面后有进入剧情等类似会造成Ui清空再读取的行为结束后返回该界面时动画播放不正确
            -- AnimEnable2不在播放状态且播放时长小于总时长
            if self.AnimEnable2.state ~= CS.Playable.PlayState.Playing and self.AnimEnable2.time <= self.AnimEnable2.duration then
                self.AnimEnable2:Play()
                self.AnimEnable2.time = self.AnimEnable2.duration
            end
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
    self:RegisterClickEvent(self.BtnBackSecond, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnMainUiSecond, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnVideo, self.OnClickBtnVideo)
    self:RegisterClickEvent(self.BtnNotice, self.OnClickBtnDetail)
    self:RegisterClickEvent(self.BtnNoticeSecond, self.OnClickBtnDetail)
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

function XUiActivityBriefBase:LoadSpine(transform, index)
    -- 根据主副面板加载动画
    local path = XActivityBriefConfigs.GetSpinePathByType(self.PanelType, index)
    if not string.IsNilOrEmpty(path) then
        transform.gameObject:SetActiveEx(true)
        local obj = transform:LoadSpinePrefab(path):GetComponent("SkeletonAnimation")
        return obj
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
    if self.PanelType ~= PanelType.Main then
        return
    end
    -- 根据配置遍历播放
    for index, _ in ipairs(XActivityBriefConfigs.GetSpinePathList(self.PanelType)) do
        local spineObjName = "PanelSpine"..index
        ---@type Spine.Unity.SkeletonGraphic
        if not XTool.UObjIsNil(self[spineObjName]) then
            self.SpineObj[index] = self:LoadSpine(self[spineObjName], index)
        end
        --self:PlaySpineAnimation(self.SpineObj[index], "Enable", "idle")
        self:PlaySpineAnimation(self.SpineObj[index], "Enable", "loop")
    end
end

function XUiActivityBriefBase:PlaySpineAnimation(spineObject,fromAnim,toAnim)
    if XTool.UObjIsNil(spineObject) then return end
    --Delegate += 操作Lua写法
    local cb
    cb = function(track)
        if track.Animation.Name == fromAnim then
            spineObject.AnimationState:SetAnimation(0, toAnim, true)
            spineObject.AnimationState:Complete('-', cb)
        end
    end
    spineObject.AnimationState:Complete('+', cb)
    spineObject.AnimationState:SetAnimation(0, fromAnim, false)
end

function XUiActivityBriefBase:PlayEnableSpineAnimation()
    if self.PanelType ~= PanelType.Main then
        return
    end
    -- if XTool.UObjIsNil(self.SpineObject1) then
    --     self.SpineObject1 = self:LoadSpine(self.PanelSpine1, 2)
    -- end
    -- if XTool.UObjIsNil(self.SpineObject) then
    --     self.SpineObject = self:LoadSpine(self.PanelSpine, 1)
    -- end
    -- self.SpineObject1.state:SetAnimation(0, "loop1", true)
    -- self.SpineObject.state:SetAnimation(0, "loop2", true)

    -- 根据配置遍历播放
    for index, _ in ipairs(XActivityBriefConfigs.GetSpinePathList(self.PanelType)) do
        local spineObjName = "PanelSpine"..index
        ---@type Spine.Unity.SkeletonGraphic
        if not XTool.UObjIsNil(self[spineObjName]) then
            local aniName = "loop" .. index
            self.SpineObj[index] = self:LoadSpine(self[spineObjName], index)
        end
        self.SpineObj[index].state:SetAnimation(0, aniName, true)
    end
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

function XUiActivityBriefBase:RefreshPanel()
    if self.PanelType == PanelType.Main then
        self.PanelActivity1.gameObject:SetActiveEx(true)
        self.PanelActivity2.gameObject:SetActiveEx(false)
        self.PanelActivityInfo1.gameObject:SetActiveEx(true)
        self.PanelActivityInfo2.gameObject:SetActiveEx(false)
    elseif self.PanelType == PanelType.Second then
        self.PanelActivity1.gameObject:SetActiveEx(false)
        self.PanelActivity2.gameObject:SetActiveEx(true)
        self.PanelActivityInfo1.gameObject:SetActiveEx(false)
        self.PanelActivityInfo2.gameObject:SetActiveEx(true)
    end
end 