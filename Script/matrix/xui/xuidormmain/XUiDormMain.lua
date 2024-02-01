local XUiDormMain = XLuaUiManager.Register(XLuaUi, "UiDormMain")
local XUiDormMainItem = require("XUi/XUiDormMain/XUiDormMainItem")
local XUiPanelTerminalEntranceTips = require("XUi/XUiDormQuest/XUiPanelTerminalEntranceTips")
local TextManager = CS.XTextManager

local DormDrawGroudId
local White = "#ffffff"
local Blue = "#34AFF8"

local MIN_MOVE_Y_DISTANCE = CS.XGame.ClientConfig:GetInt("UiGridDormSceneMinY")
local MIN_MOVE_TARGET_DISTANCE = CS.XGame.ClientConfig:GetInt("UiGridDormSceneTargetY")

function XUiDormMain:OnAwake()
    self.DormItems = {}
    self.Roomsputup = {}
    DormDrawGroudId = CS.XGame.ClientConfig:GetInt("DormDrawGroudId")
    self.DisplaySetType = XDormConfig.VisitDisplaySetType
    self.DormActiveState = XDormConfig.DormActiveState
    self.HelpCourseKey = "Dorm"
    XTool.InitUiObject(self)
    self:InitFun()
    self:InitEnter()
    self:InitUI()
end

function XUiDormMain:InitFun()
    self.DormActiveRespCB = function() self:SetDormMainItem() end
    self.DormCharEventCB = function(dormId) self:CharEventChange(dormId) end
    self.OnBtnTaskTipsClickCb = function() self:OnBtnTaskTipsClick() end
    self:BindHelpBtn(self.BtnHelp, self.HelpCourseKey, nil, XDormConfig.MarkDormCourseGuide)
    self.BtnVisit.CallBack = function() self:OnBtnVisitClick() end

end

function XUiDormMain:InitEnter()
    self:RegisterClickEvent(self.BtnWork, function() self:OpenWork() end)
    self:RegisterClickEvent(self.BtnPerson, function() self:SetPersonList() end)
    self:RegisterClickEvent(self.BtnTask, self.OnBtnTaskClick)
    self:RegisterClickEvent(self.BtnShop, function() self:OpenShopUI() end)
    self:RegisterClickEvent(self.BtnBuild, function() self:OpenBuildUI() end)
    self:RegisterClickEvent(self.BtnWareHouse, function() self:OpenWareHpuseUI() end)
    self:RegisterClickEvent(self.BtnHandbook, function() self:OpenFieldGuideUI() end)
    self.BtnWork:SetName(TextManager.GetText("DormWorkText"))
    self.BtnPerson:SetName(TextManager.GetText("DormPersonText"))
    self.BtnTask:SetName(TextManager.GetText("DormTaskText"))
    self.BtnShop:SetName(TextManager.GetText("DormShopText"))
    self.BtnWareHouse:SetName(TextManager.GetText("DormWareHouseText"))
    self.BtnBuild:SetName(TextManager.GetText("DormBuidText"))
    self.BtnEntrust:SetName(TextManager.GetText("DormEntrustText"))
end

-- 图鉴
function XUiDormMain:OpenFieldGuideUI()
    XLuaUiManager.Open("UiDormFieldGuide")
end

-- 跳到仓库
function XUiDormMain:OpenWareHpuseUI()
    XLuaUiManager.Open("UiDormBag")
    self.IsStatic = true
end

-- 跳到建造
function XUiDormMain:OpenBuildUI()
    if XDataCenter.FurnitureManager.CheckFurnitureSlopLimit() then
        XLuaUiManager.Open("UiFurnitureCreateDetail")
        return
    end
    XLuaUiManager.Open("UiFurnitureBuild")
    self.IsStatic = true
end

function XUiDormMain:CharEventChange(dormId)
    if self.DormItems[dormId] then
        self.DormItems[dormId]:SetEvenIconState(true)
    end
end

-- 跳到商店
function XUiDormMain:OpenShopUI()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon) then
        return
    end
    local shopId = self.IsShowReward and XDataCenter.DormQuestManager.GetShopId() or nil
    XLuaUiManager.Open("UiShop", XShopManager.ShopType.Dorm, nil, shopId)
    self.IsStatic = true
end

-- 跳到抽卡
function XUiDormMain:OpenDrawUI()
    -- 没有开启
    local isOpen = XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.DrawCard)
    if not isOpen then
        XUiManager.TipText("DormDrawNoOpenTips")
        return
    end

    XDataCenter.DrawManager.GetDrawGroupList(
    function()
        local info = XDataCenter.DrawManager.GetDrawGroupInfoByGroupId(DormDrawGroudId)
        XDataCenter.DrawManager.GetDrawInfoList(DormDrawGroudId, function()
            XLuaUiManager.Open("UiDraw", DormDrawGroudId, function()
                XHomeSceneManager.ResetToCurrentGlobalIllumination()
            end, info.UiBackGround)
        end)
    end
    )
    self.IsStatic = true
end

-- 跳到任务
function XUiDormMain:OnBtnTaskTipsClick()
    if self.CurTaskData and not self.CurTaskTagState then
        self:OnTaskSkip()
        return
    end

    local tab
    if self.CurTaskTagState then
        if self.TaskType == XDataCenter.TaskManager.TaskType.DormNormal then
            tab = XTaskConfig.PANELINDEX.Story
        else
            tab = XTaskConfig.PANELINDEX.Daily
        end
    end
    self:OnOpenTask(tab)
end

function XUiDormMain:OnBtnTemplateClick()
    XLuaUiManager.Open("UiDormTemplate")
end

function XUiDormMain:OnBtnVisitClick()
    XLuaUiManager.Open("UiDormVisit", nil, XDormConfig.VisitTabTypeCfg.MyFriend)
end

function XUiDormMain:OnOpenTask(tab)
    XLuaUiManager.Open("UiDormTask", tab)
    self.IsStatic = true
end

function XUiDormMain:OnBtnTaskClick()
    self:OnOpenTask()
end

function XUiDormMain:OnTaskSkip()
    if XDataCenter.RoomManager.RoomData ~= nil then
        local title = CS.XTextManager.GetText("TipTitle")
        local cancelMatchMsg = CS.XTextManager.GetText("OnlineInstanceQuitRoom")
        XUiManager.DialogTip(title, cancelMatchMsg, XUiManager.DialogType.Normal, nil, function()
            XLuaUiManager.RunMain()
            local skipId = XDataCenter.TaskManager.GetTaskTemplate(self.CurTaskData.Id).SkipId
            XFunctionManager.SkipInterface(skipId)
        end)
    else
        local skipId = XDataCenter.TaskManager.GetTaskTemplate(self.CurTaskData.Id).SkipId
        XFunctionManager.SkipInterface(skipId)
    end
end

-- 跳到打工
function XUiDormMain:OpenWork()
    XLuaUiManager.Open("UiDormWork")
    self.IsStatic = true
end

-- 设置人员list
function XUiDormMain:SetPersonList()
    XLuaUiManager.Open("UiDormPerson", XDormConfig.PersonType.Staff, self.SceneId)
    self.IsStatic = true
end

-- [监听动态列表事件]
function XUiDormMain:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.ListData[index]
        grid:OnRefresh(data)
    end
end

function XUiDormMain:SetSelectState(state)
    if not self.PanelSelect then
        return
    end

    self.PanelSelect.gameObject:SetActiveEx(state)
end

function XUiDormMain:OnStart()
    XLuaUiManager.Close("UiLoading")
    ---@type XUiPanelTerminalEntranceTips
    self.TerminalEntranceTip = XUiPanelTerminalEntranceTips.New(self.DormTeamLeisure, self)

    self.BtnGroup:SelectIndex(XDormConfig.SceneType.One)
end

function XUiDormMain:CreateDormMainItems()
    --已经拥有的宿舍
    local dormDatas = XDataCenter.DormManager.GetDormitoryData()
    for dormId, v in pairs(dormDatas) do
        if v:WhetherRoomUnlock() then
            if not self.DormItems[dormId] then
                local item = self:GetItem(dormId)
                self.DormItems[dormId] = item
            end
            self.DormItems[dormId].GameObject:SetActiveEx(true)
            self.DormItems[dormId]:OnRefresh(v, self.DormActiveState.Active)
            self.DormItems[dormId]:SetEvenIconState(XDataCenter.DormManager.IsHaveDormCharactersEvent(dormId))
        end
    end
end

function XUiDormMain:GetItem(dormId)
    local obj = self:GetDormItemPos(dormId)
    local item = XUiDormMainItem.New(obj, self)
    return item
end

function XUiDormMain:GetDormItemPos(id)
    return self.Roomsputup[id]
end

function XUiDormMain:OnEnable()
    self.BtnPanelTask.CallBack = self.OnBtnTaskTipsClickCb
    self:OnPlayAnimation()
    XDataCenter.DormManager.StartDormRedTimer()
    self.BtnWork:ShowReddot(XDataCenter.DormManager.DormWorkRedFun())
    --self.BtnBuild:ShowReddot(XDataCenter.FurnitureManager.HasCollectableFurniture())
    self.BtnEntrust:ShowReddot(XDataCenter.DormQuestManager.CheckDormEntrustRedPoint())
    local redPointTypes = XRedPointConditions.Types 
    self:AddRedPointEvent(self.BtnTask.ReddotObj, self.RefreshTaskTabRedDot, self, { redPointTypes.CONDITION_DORM_MAIN_TASK_RED })
    self:AddRedPointEvent(self.BtnBuild.ReddotObj, self.OnCheckBuildFurniture, self, { redPointTypes.CONDITION_FURNITURE_CREATE })

    XEventManager.AddEventListener(XEventId.EVENT_CHARACTER_DORMMAIN_EVENT_NOTIFY, self.DormCharEventCB)
    XEventManager.AddEventListener(XEventId.EVENT_DORM_ROOM_ACTIVE_SUCCESS, self.DormActiveRespCB, self)
    local data, tasktype, state = XDataCenter.TaskManager.GetDormTaskTips()
    if data and tasktype and state then
        self.CurTaskData = data
        self.TaskType = tasktype
        self.PanelTask.gameObject:SetActiveEx(true)
        local config = XDataCenter.TaskManager.GetTaskTemplate(data.Id)
        self.CurTaskTagState = state == XDataCenter.TaskManager.TaskState.Achieved
        if self.CurTaskTagState then
            self.BtnPanelTask:SetName(string.format("<color=%s>%s</color>", Blue, config.Desc))
        else
            self.BtnPanelTask:SetName(string.format("<color=%s>%s</color>", White, config.Desc))
        end
        self.BtnPanelTask:ShowTag(not self.CurTaskTagState)
        self.BtnPanelTask:ShowReddot(self.CurTaskTagState)
    else
        self.CurTaskData = nil
        self.PanelTask.gameObject:SetActiveEx(false)
    end
    self.TerminalEntranceTip:Refresh()
    self.BtnShop:ShowTag(false)

    if self:CheckShopTipLocal() then
        --商店购买提示
        XDataCenter.DormQuestManager.CheckPopupShopTip(function(isShow)
            self.IsShowReward = false
            if not isShow then
                return
            end
            self:OnShowShopTip()
        end)
    end
    
    self:CheckOpenHelp()

    XHomeSceneManager.SetGlobalIllumSO(CS.XGame.ClientConfig:GetString("HomeSceneSoAssetUrl"))
end

function XUiDormMain:RefreshTaskTabRedDot(count)
    self.BtnTask:ShowReddot(count >= 0)
end

function XUiDormMain:OnCheckBuildFurniture(count)
    self.BtnBuild:ShowReddot(count >= 0)
end

function XUiDormMain:OnPlayAnimation()
    --local delay = XDormConfig.DormAnimationMoveTime
    --if self.IsStatic then
    --    self.IsStatic = false
    --    delay = XDormConfig.DormAnimationStaicTime
    --end
    self:InitSpaceBtn()
    self.IsFirstAnimation = true
    --if delay > 0 then
    --    self.IsFirstAnimation = true
    --    self.SafeAreaContentPane.gameObject:SetActiveEx(false)
    --    self.DormMainLookTimer = XScheduleManager.ScheduleOnce(function()
    --        self.SafeAreaContentPane.gameObject:SetActiveEx(true)
    --        self:PlayAnimation("AnimStartEnable")
    --        self:PlayAnimation("BgEnable")
    --        self:PlayAnimation("LeftTapGroupEnable")
    --        self:SetDormMainItem()
    --        XScheduleManager.UnSchedule(self.DormMainLookTimer)
    --    end, delay)
    --else
        self:SetDormMainItem()
        self:PlayAnimation("AnimStartEnable")
        self:PlayAnimation("BgEnable")
        self:PlayAnimation("LeftTapGroupEnable")
    --end
end

function XUiDormMain:SetDormMainItem()
    self:CreateDormMainItems()
end

function XUiDormMain:OnDisable()
    self.BtnPanelTask.CallBack = nil
    XEventManager.RemoveEventListener(XEventId.EVENT_CHARACTER_DORMMAIN_EVENT_NOTIFY, self.DormCharEventCB)
    XEventManager.RemoveEventListener(XEventId.EVENT_DORM_ROOM_ACTIVE_SUCCESS, self.DormActiveRespCB, self)
    if self.DormMainLookTimer then
        XScheduleManager.UnSchedule(self.DormMainLookTimer)
        self.DormMainLookTimer = nil
    end

    -- 进入房间应该隐藏Hud
    for _, v in pairs(self.DormItems) do
        v.GameObject:SetActiveEx(false)
        v:SetEvenIconState(false)
    end
    XDataCenter.DormManager.StopDormRedTimer()
    self.TerminalEntranceTip:OnDisable()
end

function XUiDormMain:OnDestroy()
    XHomeSceneManager.LeaveScene()
    XEventManager.DispatchEvent(XEventId.EVENT_DORM_HIDE_COMPONENT)
end

function XUiDormMain:InitUI()
    local itemId = XDataCenter.ItemManager.ItemId
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, itemId.DormCoin, itemId.FurnitureCoin, itemId.DormEnterIcon)
    self:AddListener()
    local cfg = XDormConfig.GetTotalDormitoryCfg()
    local i = 1
    for _, v in pairs(cfg) do
        self.Roomsputup[v.Id] = self["DormlMainItem" .. v.InitNumber]
        i = i + 1
    end
    self:InitBtnTabsGroup()
    self:InitPanelSceneGroup()
end

function XUiDormMain:InitBtnTabsGroup()
    local tab = {
        self.BtnTab1,
        self.BtnTab2,
        self.BtnTab3,
        self.BtnTab4,
    }

    self.BtnGroup:Init(tab, function(tabIndex) self:ChangeSceneOnBtnTabClick(tabIndex) end)
    self.TabList = tab
    ---@type UnityEngine.RectTransform
    self.GroupRectTransform = self.BtnGroup:GetComponent("RectTransform")
end

function XUiDormMain:InitPanelSceneGroup()
    self.PanelSceneGroup = {}
    local index = 1
    while true do
        if self["PanelScene" .. index] then
            self.PanelSceneGroup[index] = self["PanelScene" .. index]
        else
            break
        end
        index = index + 1
    end
end

function XUiDormMain:AddListener()
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUIClick)
    self:RegisterClickEvent(self.BtnBack, self.OnBtnReturnClick)
    self:RegisterClickEvent(self.BtnEntrust, self.OnBtnEntrustClick)
end

function XUiDormMain:OnBtnMainUIClick()
    XDataCenter.DormManager.ExitDormitoryBackToMain()
end

function XUiDormMain:OnBtnReturnClick()
    XDataCenter.DormManager.RequestDormitoryExit()
    XEventManager.DispatchEvent(XEventId.EVENT_DORM_CLOSE_COMPONET)
    self:Close()
end

function XUiDormMain:OnBtnEntrustClick()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.DormQuest) then
        return
    end
    local dict = {}
    dict["button"] = XGlobalVar.BtnDorm.BtnUiDormBtnEntrust
    CS.XRecord.Record(dict, "200010", "Dorm")
    XLuaUiManager.Open("UiDormTerminalSystem")
    self.IsStatic = true
end

function XUiDormMain:ChangeSceneOnBtnTabClick(index)
    if self.SceneId == index then
        return
    end
    --local grid = self.TabList[index]
    --local diffY = grid.transform.localPosition.y + self.GroupRectTransform.localPosition.y
    --if diffY > MIN_MOVE_Y_DISTANCE then
    --    local tarPosY = MIN_MOVE_TARGET_DISTANCE - grid.transform.localPosition.y
    --    local tarPos = self.GroupRectTransform.localPosition
    --    tarPos.y = tarPosY 
    --    XLuaUiManager.SetMask(true)
    --    XUiHelper.DoMove(self.GroupRectTransform, tarPos, XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration, XUiHelper.EaseType.Sin, function()
    --        XLuaUiManager.SetMask(false)
    --    end)
    --end
    self.SceneId = index
    self:HideAllPanelScene()
    XHomeSceneManager.ChangeSceneView(self.SceneId, function()
            self:OpenOnePanelScene(self.SceneId)
            self:OnPlayAnimation()
        end)
end

--==================
--隐藏所有PanelScene
--==================
function XUiDormMain:HideAllPanelScene()
    for _, scene in pairs(self.PanelSceneGroup) do
        scene.gameObject:SetActiveEx(false)
    end
end
--==================
--打开对应序号的PanelScene
--@param index:页签序号
--==================
function XUiDormMain:OpenOnePanelScene(index)
    if not index then index = self.SceneId end
    if not index then index = XDormConfig.SceneType.One end
    for i, scene in pairs(self.PanelSceneGroup) do
        local isSelect = i == index
        scene.gameObject:SetActiveEx(isSelect)
    end
end
--==================
--初始化左侧页签及PanelScene状态
--==================
function XUiDormMain:InitSpaceBtn()
    if self.IsFirstAnimation then
        return
    end
    self:OpenOnePanelScene()
end

function XUiDormMain:OnShowShopTip()
    --等待100ms, 避免跳转到子界面时不可见
    XScheduleManager.ScheduleOnce(function()
        local obj = self.GameObject
        if XTool.UObjIsNil(obj) or not obj.activeInHierarchy then
            return
        end

        if not self:CheckShopTipLocal() then
            return
        end
        
        self.IsShowReward = true
        local grid = XUiGridCommon.New(self, self.GridReward)
        grid:Refresh(XDataCenter.DormQuestManager.GetShowFragmentId())
        self.BtnShop:ShowTag(true)
        self:MarkShopTipLocal()
    end, 100)
    
end 

function XUiDormMain:CheckShopTipLocal()
    local key = XDormConfig.GetDormShopTipLocalKey()
    --已有数据
    if XSaveTool.GetData(key) then
        return false
    end
    
    return true
end

function XUiDormMain:MarkShopTipLocal()
    local key = XDormConfig.GetDormShopTipLocalKey()
    if XSaveTool.GetData(key) then
        return
    end
    
    XSaveTool.SaveData(key, true)
end

function XUiDormMain:CheckOpenHelp()
    if XLuaUiManager.IsUiShow("UiHelp") then
        return
    end
    
    --已经触发引导
    if not XDataCenter.GuideManager.CheckIsGuide(XDormConfig.DormCourseGuideId) then
        return
    end
    
    local configJumpIndex = XDormConfig.DormCourseJumpIndex
    local key = XDormConfig.GetDormCourseGuideLocalKey(configJumpIndex)
    --已有数据
    if XSaveTool.GetData(key) then
        return
    end
    
    XLuaUiManager.SetMask(true)
    local count = XHelpCourseConfig.GetImageAssetCount(self.HelpCourseKey) or 0
    local index = math.min(configJumpIndex, count)
    XScheduleManager.ScheduleOnce(function()
        XLuaUiManager.SetMask(false)
        if XTool.UObjIsNil(self.GameObject) then
            return
        end
        XUiManager.ShowHelpTip(self.HelpCourseKey, function()
            XSaveTool.SaveData(key, true)
        end, index - 1)
    end, 700)
    
end