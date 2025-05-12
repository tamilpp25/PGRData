local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiPlanetChapterGrid = require("XUi/XUiPlanet/Chapter/XUiPlanetChapterGrid")
local XUiPlanetChapter = XLuaUiManager.Register(XLuaUi, "UiPlanetChapter")
local VALUELIMIT = 10000

function XUiPlanetChapter:OnAwake()
    self:InitObj()
    if not self.Widget then
        self:InitDynamicTable()
    end
    self:AddBtnClickListener()
end

function XUiPlanetChapter:OnStart()
    if not self.Widget then
        self:UpdateChapterList()
    end
    if not XDataCenter.PlanetManager.CheckMainIsExit() then
        self.IsResume = true
        XDataCenter.PlanetManager.ResumeMainScene(function()
            self.IsResume = false
            XDataCenter.PlanetManager.GetPlanetMainScene():UpdateCameraInChapter(function()
                self:UpdateChapterGridList()
                self:UpdateChapterGridListPosition()
                self:StartUpdateChapterGridListPosition()
            end)
        end)
    end
    XDataCenter.PlanetManager.SceneOpen(XPlanetConfigs.SceneOpenReason.UiPlanetChapter)
end

function XUiPlanetChapter:OnEnable()
    self:InitChapterGridList()
    self.PlanetMainScene = XDataCenter.PlanetManager.GetPlanetMainScene()
    self.PlanetMainScene:UpdateCameraInChapter(function()
        self:UpdateChapterGridListPosition()
    end)
    self.IsBounce = false
    self.IsDrag = false
    self:RefreshRedPoint()
    self:RefreshTalentBtn()
    if self.Widget and not self.IsResume then
        self:UpdateChapterGridList()
        self:UpdateChapterGridListPosition()
        self:StartUpdateChapterGridListPosition()
    end
end

function XUiPlanetChapter:OnDisable()
    self:StopUpdateChapterGridListPosition()
end

function XUiPlanetChapter:OnRelease()
    self.Super.OnRelease(self)
    self:StopUpdateChapterGridListPosition()
end

function XUiPlanetChapter:OnDestroy()
    XDataCenter.PlanetManager.SceneRelease(XPlanetConfigs.SceneOpenReason.UiPlanetChapter)
end

--region Ui
function XUiPlanetChapter:InitChapterGridList()
    self.ChapterList = XDataCenter.PlanetManager.GetShowChapterList()
    for _, chapterId in ipairs(self.ChapterList) do
        if not self.ChapterGridList[chapterId] then
            local go = XUiHelper.Instantiate(self.GridStar.gameObject, self.ChapterRoot)
            self.ChapterGridList[chapterId] = XUiPlanetChapterGrid.New(go, self)
        end
    end
    self.PanelItemList.gameObject:SetActiveEx(false)
end

function XUiPlanetChapter:UpdateChapterGridList()
    for chapterId, grid in ipairs(self.ChapterGridList) do
        grid:Refresh(chapterId)
    end
end

function XUiPlanetChapter:UpdateChapterGridListPosition()
    local beforeUiXPosition
    local afterUiXPosition
    local beforePlanetXPosition
    local afterPlanetXPosition
    for chapterId, grid in ipairs(self.ChapterGridList) do
        local position = self.PlanetMainScene:GetChapterPlanetPosition(chapterId)
        local camera = self.PlanetMainScene:GetCamera()
        local uiPosition = XUiHelper.ObjPosToUguiPos(self.Transform, position, camera)
        if beforeUiXPosition == nil then
            beforeUiXPosition = uiPosition.x
        end
        if beforePlanetXPosition == nil then
            beforePlanetXPosition = position.x
        end
        afterPlanetXPosition = position.x
        afterUiXPosition = uiPosition.x
        grid:SetPosition(uiPosition)
    end

    self.PlanetXDistance = (beforeUiXPosition - afterUiXPosition) / (#self.ChapterList - 1)
    self:InitDragParams(beforePlanetXPosition, afterPlanetXPosition, self.PlanetXDistance)
end

function XUiPlanetChapter:StartUpdateChapterGridListPosition()
    self.UpdateTimer = XScheduleManager.ScheduleForever(function()
        if self.PlanetMainScene:CheckCameraIsMove() then
            self:UpdateChapterGridListPosition()
        else
            self:CamBounceBack()
        end
    end, 0, 0)
end

function XUiPlanetChapter:StopUpdateChapterGridListPosition()
    if self.UpdateTimer then
        XScheduleManager.UnSchedule(self.UpdateTimer)
    end
    self.UpdateTimer = nil
end

function XUiPlanetChapter:RefreshRedPoint()
    -- 必须要先请求商店信息 才能检测红点。请求前先判断能否获取信息
    XDataCenter.PlanetManager.RefreshShopInfo(function ()
        self.BtnShop:ShowReddot(XDataCenter.PlanetManager.CheckShopRedPoint())
    end, true)
    self.BtnTask:ShowReddot(XDataCenter.PlanetManager.CheckTaskRedPoint())
    self.BtnHome:ShowReddot(XDataCenter.PlanetManager.CheckTalentRedPoint())
end

function XUiPlanetChapter:RefreshTalentBtn()
    local isShowTalentPlanet = XDataCenter.PlanetManager.GetViewModel():CheckStageIsPass(XPlanetConfigs.GetTalentUnLockStage())
    self.BtnHome:SetDisable(not isShowTalentPlanet)
end
--endregion


--region Drag
local PlanetDeltaXPosition = 0  -- 两星球间X坐标差
local UiGridDeltaXPosition = 0  -- 两uiGrid间坐标差
local OverNum = 0.5             -- 超出范围百分比(小数表示)
local OverTime = 0.08            -- 回弹时间
local LeftLimit = 0             -- 左极限
local RightLimit = 0            -- 右极限
local Value = 1                 -- 滑动范围百分比(小数表示)
local BounceFri = 0             -- 弹性拉伸缓长
local OffsetX = 0               -- 当前偏移值(用于惯性)
local InertiaStrength = 10      -- 惯性力度
local Mathf = CS.UnityEngine.Mathf
local Input = CS.UnityEngine.Input

function XUiPlanetChapter:InitDragParams(leftLimit, rightLimit, uiGridDeltaXPosition)
    local camPosition = XDataCenter.PlanetManager.GetPlanetMainScene():GetCamera().transform.position
    if RightLimit ~= rightLimit then
        PlanetDeltaXPosition = XPlanetConfigs.GetCamChapterXOffset()
        LeftLimit = leftLimit + PlanetDeltaXPosition / 2
        RightLimit = rightLimit
        UiGridDeltaXPosition = uiGridDeltaXPosition
    end
    Value = (camPosition.x - LeftLimit) / (RightLimit - LeftLimit)
end

function XUiPlanetChapter:OnBeginDrag()
    local mainScene = XDataCenter.PlanetManager.GetPlanetMainScene()
    self.StartDragPosition = Input.mousePosition
    self.CameraPosition = mainScene:GetCamera().transform.position
    self.IsDrag = true
end

function XUiPlanetChapter:OnDrag()
    local deltaPosition = Input.mousePosition - self.StartDragPosition
    local camXMove = XPlanetConfigs.GetCamChapterXOffset() / UiGridDeltaXPosition
    OffsetX = (deltaPosition.x * camXMove) / (RightLimit - LeftLimit)
    Value = Value + OffsetX
    Value = Mathf.Max(0 - OverNum, Value)
    Value = Mathf.Min(Value, 1 + OverNum)
    if Value > 1 then
        Value = Mathf.SmoothDamp(Value, 1, BounceFri, OverTime)
    elseif Value < 0 then
        Value = Mathf.SmoothDamp(Value, 0, BounceFri, OverTime)
    end
    self:_UpdateCamPosition()
    self.IsDrag = true
    self.StartDragPosition = Input.mousePosition
    self.CameraPosition = XDataCenter.PlanetManager.GetPlanetMainScene():GetCamera().transform.position
end

function XUiPlanetChapter:OnEndDrag()
    self.CurValue = Value + OffsetX * InertiaStrength
    self.CurValue = Mathf.Max(0, self.CurValue)
    self.CurValue = Mathf.Min(self.CurValue, 1)
    self.IsDrag = false
    self.IsBounce = true
end

---相机弹性拉伸
function XUiPlanetChapter:CamBounceBack()
    if not self.CameraPosition then
        return
    end
    if self.IsDrag then
        return
    end
    if not self.IsBounce then
        return
    end
    
    if Value > 1 then       -- 右回弹
        Value = Mathf.SmoothDamp(Value, 1, BounceFri, OverTime)
        --因为Mathf.SmoothDamp的time参数不填1是不能到达目标值的，因此需要设置退出值，下方同理
        if math.floor(Value * VALUELIMIT) == 1 then
            Value = 1
            self.IsBounce = false
        end
    elseif Value < 0 then   -- 左回弹
        Value = Mathf.SmoothDamp(Value, 0, BounceFri, OverTime)
        if math.ceil(Value * VALUELIMIT) == 0 then
            Value = 0
            self.IsBounce = false
        end
    elseif Value > 0 and Value < 1 then -- 惯性滑动
        Value = Mathf.SmoothDamp(Value, self.CurValue, BounceFri, OverTime)
        if math.floor(Value * VALUELIMIT) == math.floor(self.CurValue * VALUELIMIT) then
            Value = self.CurValue
            self.IsBounce = false
        end
    end
    
    self:_UpdateCamPosition()
end

function XUiPlanetChapter:_UpdateCamPosition()
    local mainScene = XDataCenter.PlanetManager.GetPlanetMainScene()
    local x = LeftLimit + (RightLimit - LeftLimit) * Value
    local newPosition = Vector3(x, self.CameraPosition.y, self.CameraPosition.z)
    mainScene:MoveStaticCamera(newPosition)
    self:UpdateChapterGridListPosition()
end
--endregion


--region 列表刷新
function XUiPlanetChapter:InitDynamicTable()
    self.ScrollRect = self.PanelItemList:GetComponent("ScrollRect")
    self.ScrollRect.onValueChanged:AddListener(handler(self, self.ChangeCam))
    self.DynamicTable = XDynamicTableNormal.New(self.PanelItemList)
    self.DynamicTable:SetProxy(XUiPlanetChapterGrid, self)
    self.DynamicTable:SetDelegate(self)
    self.GridStar.gameObject:SetActiveEx(false)
end

function XUiPlanetChapter:UpdateChapterList()
    self.ChapterList = XDataCenter.PlanetManager.GetShowChapterList()
    self.DynamicTable:SetDataSource(self.ChapterList)
    self.DynamicTable:ReloadDataASync(1)
end

function XUiPlanetChapter:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local chapterId = self.ChapterList[index]
        grid:Refresh(chapterId)
    end
end

function XUiPlanetChapter:GetScreenOffset(index)
    local chapterId = self.ChapterList[index]
    local screen = CS.UnityEngine.Screen
    local mainScene = XDataCenter.PlanetManager.GetPlanetMainScene()
    -- ScreenPoint以左下角为原点
    local position = mainScene:GetCamera():WorldToScreenPoint(mainScene:GetChapterPlanetPosition(chapterId))
    local screenPoint = position - Vector3(screen.width / 2, screen.height / 2, 0) - offset
    return screenPoint
end

function XUiPlanetChapter:ChangeCam()
    local mainScene = XDataCenter.PlanetManager.GetPlanetMainScene()
    local deltaPosition = self.InitPosition - self.PanelStar.transform.localPosition
    local camXMove = 42.5 * deltaPosition.x / self.GridStar.transform.rect.width
    --mainScene:MoveStaticCamera(Vector3(27.5, 0, -50) + Vector3(camXMove, 0, 0))
    mainScene:MoveStaticCamera(Vector3(27.5, 0, mainScene:GetCamera().transform.position.z) + Vector3(camXMove, 0, 0))
end
--endregion


--region 对象初始化
function XUiPlanetChapter:InitObj()
    self.PlanetMainScene = XDataCenter.PlanetManager.GetPlanetMainScene()
    self.PlanetViewModel = XDataCenter.PlanetManager.GetViewModel()
    self.InitPosition = self.PanelStar.transform.localPosition
    ---@type XUiPlanetChapterGrid
    self.ChapterGridList = {}
end
--endregion


--region 按钮绑定
function XUiPlanetChapter:AddBtnClickListener()
    XUiHelper.RegisterClickEvent(self, self.BtnTask, self.OnBtnTaskClick)
    XUiHelper.RegisterClickEvent(self, self.BtnShop, self.OnBtnShopClick)
    XUiHelper.RegisterClickEvent(self, self.BtnHome, self.OnBtnHomeClick)

    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, function() XLuaUiManager.RunMain() end)
    self:BindHelpBtn(self.BtnHelp, XPlanetConfigs.GetHelpKey())

    if self.Widget then
        self.Widget:AddBeginDragListener(function(eventData)
            self:OnBeginDrag()
        end)
        self.Widget:AddEndDragListener(function(eventData)
            self:OnEndDrag()
        end)
        self.Widget:AddDragListener(function(eventData)
            self:OnDrag()
        end)
    end
end

function XUiPlanetChapter:OnBtnHomeClick()
    if XDataCenter.PlanetManager.GetViewModel():CheckStageIsPass(XPlanetConfigs.GetTalentUnLockStage()) then
        XLuaUiManager.Open("UiPlanetHomeland")
    else
        local stageName = XPlanetStageConfigs.GetStageFullName(XPlanetConfigs.GetTalentUnLockStage())
        XUiManager.TipError(XUiHelper.GetText("PlanetRunningTalentCardLock", stageName))
    end
end

function XUiPlanetChapter:OnBtnShopClick()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon) then
        return
    end

    XDataCenter.PlanetManager.RefreshShopInfo(function ()
        XLuaUiManager.Open("UiPlanetPropertyShop")
    end)
end

function XUiPlanetChapter:OnBtnTaskClick()
    XLuaUiManager.Open("UiPlanetPropertyTask")
end
--endregion