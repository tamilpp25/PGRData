local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiRiftMain:XLuaUi 大秘境主界面
---@field _Control XRiftControl
local XUiRiftMain = XLuaUiManager.Register(XLuaUi, "UiRiftMain")

local ItemIds = {
    XDataCenter.ItemManager.ItemId.RiftGold,
    XDataCenter.ItemManager.ItemId.RiftCoin
}

function XUiRiftMain:OnAwake()
    self.RewardGridList = {}
    self:InitButton()
    self:InitComponent()
end

function XUiRiftMain:OnStart(param)
    self._Param = param
    self:InitChapterGrid()
    -- 只有从外部进入时才播放场景动效
    if param and param.IsPlayScreenTween then
        self:PlayScreenTween()
    end
end

function XUiRiftMain:InitButton()
    self:BindHelpBtn(self.BtnHelp, "RiftHelp")
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnRanking, self.OnBtnRank)
    self:RegisterClickEvent(self.BtnStory, self.OnBtnStoryClick)
    self:RegisterClickEvent(self.BtnTask, self.OnBtnTaskClick)
    self:RegisterClickEvent(self.BtnShop, self.OnBtnShopClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainClick)
end

function XUiRiftMain:OnEnable()
    self:RefreshUiShow()
    self:SetTimer()
    self:SetCameraShow()
    self:Adapter3DUi()
    if not self._Param or not self._Param.IsPlayScreenTween then
        self:PlayAnimation("UiEnable")
    end
    self._Param.IsPlayScreenTween = false
    -- 点击前往下一关时自动打开章节详情弹框
    local autoChapterId = self._Control:GetAutoOpenChapterDetail()
    if XTool.IsNumberValid(autoChapterId) then
        self._AutoOpenTimer = XScheduleManager.ScheduleOnce(function()
            self._Chapters[autoChapterId]:TryEnterChapter()
        end, 50)
    end
    self._Control:SetAutoOpenChapterDetail(nil)
end

function XUiRiftMain:OnDisable()

end

function XUiRiftMain:OnDestroy()
    if self._AutoOpenTimer then
        XScheduleManager.UnSchedule(self._AutoOpenTimer)
        self._AutoOpenTimer = nil
    end
end

function XUiRiftMain:InitChapterGrid()
    ---@type XUiGridRiftChapter[]
    self._Chapters = {}
    local datas = self._Control:GetEntityChapter()
    for i, chapter in ipairs(datas) do
        local ui3d = self._Panel3D["PanelRiftGrid" .. i]
        if ui3d then
            local lastChapter = i > 1 and datas[i - 1] or nil
            local go = XUiHelper.Instantiate(self._Panel3D.BtnRiftGrid, ui3d)
            go.localPosition = CS.UnityEngine.Vector3.zero
            ---@type XUiGridRiftChapter
            local grid = require("XUi/XUiRift/Grid/XUiGridRiftChapter").New(go, self, chapter, lastChapter)
            grid:SetModelLine(self._Panel3D["Line" .. i], self._Panel3D["DisLine" .. i])
            self._Chapters[i] = grid
        else
            XLog.Error("不存在节点： PanelRiftGrid" .. i)
        end
    end
    for i = #datas + 1, 9 do
        self:SetModelActive(self._Panel3D["PanelRiftGrid" .. i], false)
        self:SetModelActive(self._Panel3D["DisLine" .. i], false)
        self:SetModelActive(self._Panel3D["Line" .. i], false)
    end
    self:SetModelActive(self._Panel3D.BtnRiftGrid, false)
end

function XUiRiftMain:SetModelActive(model, visible)
    if not XTool.UObjIsNil(model) then
        model.gameObject:SetActiveEx(visible)
    end
end

function XUiRiftMain:RefreshUiShow()
    -- 目标(任务/权限回收)
    self:RefreshUiTask()
    -- 资源栏
    self.AssetActivityPanel:Refresh(ItemIds)
    -- 商店展示道具
    self:RefreshShopReward()
    -- 排行榜按钮
    self.IsRankUnlock, self.RankConditionDesc = self._Control:IsRankUnlock()
    self.BtnRanking:SetButtonState(self.IsRankUnlock and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
    -- 商店开启时间
    local startTime = self._Control:GetActivityStartTime()
    local endTime = self._Control:GetActivityEndTime()
    local startStr = XTime.TimestampToGameDateTimeString(startTime, "MM.dd")
    local endStr = XTime.TimestampToGameDateTimeString(endTime, "MM.dd HH:mm")
    self.BtnShop:SetNameByGroup(0, string.format("%s-%s", startStr, endStr))
    -- 刷新章节
    for _, grid in pairs(self._Chapters) do
        grid:Update()
    end
end

function XUiRiftMain:SetCameraShow(chapterId)
    for i = 1, #self._Chapters do
        local camera = self._Panel3D["UiCameraMain" .. i]
        if camera then
            camera.gameObject:SetActiveEx(chapterId == i)
        else
            XLog.Error("不存在节点： UiCameraMain" .. i)
        end
    end
end

function XUiRiftMain:OnBtnRank()
    if not self.IsRankUnlock then
        XUiManager.TipError(self.RankConditionDesc)
        return
    end
    XLuaUiManager.Open("UiRiftRanking")
end

function XUiRiftMain:SetTimer()
    local endTimeSecond = self._Control:GetTime()
    self:SetAutoCloseInfo(endTimeSecond, function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
            return
        end
        local leftTime = endTimeSecond - XTime.GetServerNowTimestamp()
        local remainTime = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY)
        self.TxtTime.text = CS.XTextManager.GetText("ShopActivityItemCount", remainTime)
    end, nil, 0)
end

function XUiRiftMain:InitComponent()
    self._Panel3D = {}
    XUiHelper.InitUiClass(self._Panel3D, self.UiModelGo.transform)
    self.AssetActivityPanel = XUiHelper.NewPanelActivityAssetSafe(ItemIds, self.PanelSpecialTool, self)
end

-- 刷新任务ui
function XUiRiftMain:RefreshUiTask()
    local titleName, desc = self._Control:GetBtnShowTask()
    local isShow = titleName ~= nil
    self.PanelTask.gameObject:SetActiveEx(isShow)
    if isShow then
        self.TxtTaskName.text = titleName
        self.TxtTaskDesc.text = desc
        local isShowRed = self._Control:CheckTaskCanReward()
        self.BtnTask:ShowReddot(isShowRed)
    end
end

-- 刷新商店展示道具
function XUiRiftMain:RefreshShopReward()
    local config = self._Control:GetRiftShopById(1)
    for i, itemId in ipairs(config.ShowItemId) do
        local grid = self.RewardGridList[i]
        if grid == nil then
            local obj = self.GridReward
            if i > 1 then
                obj = CS.UnityEngine.GameObject.Instantiate(self.GridReward, self.GridReward.transform.parent)
            end
            grid = XUiGridCommon.New(self, obj)
            table.insert(self.RewardGridList, grid)
        end

        grid:Refresh({ TemplateId = itemId })
    end
end

function XUiRiftMain:Adapter3DUi()
    ---@type UnityEngine.Canvas
    local canvas = self._Panel3D.Canvas
    ---@type UnityEngine.RectTransform
    local map = self._Panel3D.MapBg
    -- Canvas在距离摄像机100距离处
    local cam = canvas.worldCamera
    local frustumHeight = 2 * 100 * CS.UnityEngine.Mathf.Tan(cam.fieldOfView * 0.5 * CS.UnityEngine.Mathf.Deg2Rad)
    local frustumWidth = frustumHeight * cam.aspect

    local center = cam.transform.position + cam.transform.forward * 100
    local right = cam.transform.right * frustumWidth / 2
    local up = cam.transform.up * frustumHeight / 2

    local topLeft = map:InverseTransformPoint(center + up - right)
    local topRight = map:InverseTransformPoint(center + up + right)
    local bottomLeft = map:InverseTransformPoint(center - up - right)
    --local bottomRight = map:InverseTransformPoint(center - up + right)

    local screenWidth = (topLeft - topRight).magnitude
    local screenHeight = (topLeft - bottomLeft).magnitude
    local screenRadio = screenWidth / screenHeight
    local mapBgRadio = 1920 / 1080

    canvas.transform.sizeDelta = Vector2(screenWidth, screenHeight)

    if screenRadio >= mapBgRadio then
        -- 按宽度适配
        map.sizeDelta = Vector2(screenWidth, screenWidth / mapBgRadio)
    else
        -- 按高度适配
        map.sizeDelta = Vector2(screenHeight * mapBgRadio, screenHeight)
    end
end

function XUiRiftMain:OnBtnMainClick()
    XLuaUiManager.RunMain()
end

function XUiRiftMain:OnBtnTaskClick()
    XLuaUiManager.Open("UiRiftTask")
end

function XUiRiftMain:OnBtnShopClick()
    self._Control:OpenUiShop()
end

function XUiRiftMain:OnBtnStoryClick()
    XLuaUiManager.Open("UiRiftStory")
end

--region 动效

function XUiRiftMain:PlayScreenTween()
    self.UiModelGo.transform:FindTransform("Enable"):GetComponent("PlayableDirector"):Play()
    self:PlayAnimationWithMask("Enable")
end

function XUiRiftMain:PlayOpenTipTween(chapterId)
    self:PlayAnimation("UiDisable")
    self:SetCameraShow(chapterId)
end

function XUiRiftMain:PlayCloseTipTween()
    self:PlayAnimation("UiEnable")
    self:SetCameraShow()
end

--endregion

return XUiRiftMain