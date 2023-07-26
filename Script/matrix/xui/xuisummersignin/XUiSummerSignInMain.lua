---@class XUiSummerSignInMain : XLuaUi
local XUiSummerSignInMain = XLuaUiManager.Register(XLuaUi, "UiSummerSignInMain")
local XUiGridSummerSignInCheckpoints = require("XUi/XUiSummerSignIn/XUiGridSummerSignInCheckpoints")

local UiSummerSignInConfirm = "UiSummerSignInConfirm"

local FocusTime = 0.5
local ScaleLevel = {}

function XUiSummerSignInMain:OnAwake()
    self:RegisterUiEvents()
    self.GridCheckPoints = {}
end

function XUiSummerSignInMain:OnStart()
    self:InitCheckPoints()
    
    ScaleLevel = {
        Small = self.PanelSort.MinScale,
        Big = self.PanelSort.MaxScale,
        Normal = (self.PanelSort.MinScale + self.PanelSort.MaxScale) / 2,
    }
    -- 暂停自动弹窗
    XDataCenter.AutoWindowManager.StopAutoWindow()
end

function XUiSummerSignInMain:OnEnable()
    self:RefreshSignTips()
    self:RefreshSignInProgress()
    self:RefreshBtnMfyf()
    self:StartTime()
    -- 播放动画
    self:PlayAnimationWithMask("AnimEnable1",function()
        self:GotoNotOpenSignIn()
    end)
end

function XUiSummerSignInMain:OnGetEvents()
    return{
        XEventId.EVENT_SUMMER_SIGNIN_UPDATE,
    }
end

function XUiSummerSignInMain:OnNotify(event, ...)
    if event == XEventId.EVENT_SUMMER_SIGNIN_UPDATE then
        self:RefreshSignTips()
        self:RefreshSignInProgress()
        self:RefreshBtnMfyf()
        self:RefreshGrid()
    end
end

function XUiSummerSignInMain:OnDisable()
    self:StopTime()
end

function XUiSummerSignInMain:InitCheckPoints()
    self.UiSummerSignInCheckpoints.gameObject:SetActiveEx(false)
    self.MessageIds = XDataCenter.SummerSignInManager.GetActivityMessageId()
    for i = 1, #self.MessageIds do
        local grid = self.GridCheckPoints[i]
        if not grid then
            local ui = XUiHelper.Instantiate(self.UiSummerSignInCheckpoints, self.PanelStageContent)
            grid = XUiGridSummerSignInCheckpoints.New(ui, self, handler(self, self.ClickGrid))
            self.GridCheckPoints[i] = grid
            grid.GameObject:SetActiveEx(true)
        end
        grid:Refresh(self.MessageIds[i])
    end
end

-- 刷新签到提示
function XUiSummerSignInMain:RefreshSignTips()
    -- 是否查看完所以的便签
    if XDataCenter.SummerSignInManager.CheckCanFinishAllSignIn() then
        self.RImgTips.gameObject:SetActiveEx(false)
        return
    end
    -- 默认显示
    local msg = XUiHelper.GetText("SummerSignInDefault")
    -- 当日完成签到 签到次数已用尽
    if XDataCenter.SummerSignInManager.CheckSurplusTimes() then
        msg = XUiHelper.GetText("SummerSignInFinishSign")
    end

    self.TxtTips.text = XUiHelper.ConvertLineBreakSymbol(msg)
end

-- 刷新签到进度
function XUiSummerSignInMain:RefreshSignInProgress()
    local currentProgress, totalProgress = XDataCenter.SummerSignInManager.GetActivitySignInProgress()
    self.TxtCurProgress.text = currentProgress
    self.TxtTotalProgress.text = string.format("/%s", totalProgress)
    self.ImgProgressBar.fillAmount = currentProgress * 1.0 / totalProgress
end

-- 刷新研发按钮
function XUiSummerSignInMain:RefreshBtnMfyf()
    local isDrawFree = XDataCenter.DrawManager.CheckDrawFreeTicketTag()
    -- 红点
    self.BtnMfyf:ShowReddot(isDrawFree)
    self.BtnMfyf.gameObject:SetActiveEx(isDrawFree)
end

-- 刷新Grid
function XUiSummerSignInMain:RefreshGrid()
    for _, grid in pairs(self.GridCheckPoints or {}) do
        if grid then
            grid:RefreshView()
        end
    end
end

-- 选中一个 Grid
function XUiSummerSignInMain:ClickGrid(grid)
    self.Mask.gameObject:SetActiveEx(true)
    self.PanelSort:StartFocus(grid.Transform.position, ScaleLevel.Big, FocusTime, CS.UnityEngine.Vector3.zero, true, function()
        -- 打开便签确认界面
        if grid:GetIsSignIn() then
            XLuaUiManager.Open("UiSummerSignInTips", grid.MessageId, false, handler(self, self.CancelSelect))
        else
            if not XLuaUiManager.IsUiShow(UiSummerSignInConfirm) then
                self:OpenChildUi(UiSummerSignInConfirm)
            end
            self:FindChildUiObj(UiSummerSignInConfirm):Refresh(grid.MessageId, handler(self, self.CancelSelect))
        end
        self.Mask.gameObject:SetActiveEx(false)
    end)
end

-- 取消
function XUiSummerSignInMain:CancelSelect()
     self.PanelSort:EndFocus()
end

-- 滚动到未打开的便签
function XUiSummerSignInMain:GotoNotOpenSignIn()
    local lastGridIndex = 1
    for i = 1, #self.MessageIds do
        if not XDataCenter.SummerSignInManager.CheckCanMsgIdList(self.MessageIds[i]) then
            lastGridIndex = i
            break
        end
    end
    
    local grid = self.GridCheckPoints[lastGridIndex]
    local nearestTransform = grid.Transform
    
    self.Mask.gameObject:SetActiveEx(true)
    XScheduleManager.ScheduleOnce(function()
        self.PanelSort:FocusTarget(nearestTransform, ScaleLevel.Normal, FocusTime, CS.UnityEngine.Vector3.zero, function()
            self.Mask.gameObject:SetActiveEx(false)
        end)
    end, 0)
end

function XUiSummerSignInMain:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, self.OnBtnMainUiClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMfyf, self.OnBtnMfyfClick)
    self:BindHelpBtn(self.BtnHelp, "SummerSignInMain")
end

function XUiSummerSignInMain:OnBtnBackClick()
    self:Close()
end

function XUiSummerSignInMain:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiSummerSignInMain:OnBtnMfyfClick()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.DrawCard) then
        return
    end
    XDataCenter.DrawManager.OpenDrawUi()
end

--region 剩余时间

function XUiSummerSignInMain:StartTime()
    if self.Timer then
        self:StopTime()
    end

    self:UpdateTime()
    self.Timer = XScheduleManager.ScheduleForever(function()
        self:UpdateTime()
    end, XScheduleManager.SECOND)
end

function XUiSummerSignInMain:UpdateTime()
    if XTool.UObjIsNil(self.TxtTime) then
        self:StopTime()
        return
    end

    local endTime = XDataCenter.SummerSignInManager.GetEndTime()
    local now = XTime.GetServerNowTimestamp()
    if now >= endTime then
        self:StopTime()
        XDataCenter.SummerSignInManager.HandleActivityEndTime()
        return
    end

    local timeText = XUiHelper.GetTime(endTime - now, XUiHelper.TimeFormatType.ACTIVITY)
    self.TxtTime.text = timeText
end

function XUiSummerSignInMain:StopTime()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

return XUiSummerSignInMain