local XUiMoeWarParkourStage = XClass(nil, "XUiMoeWarParkourStage")

function XUiMoeWarParkourStage:Ctor(ui, stage)
    XTool.InitUiObjectByUi(self, ui)
    
    self.Stage = stage
    self.Button = self.Transform:GetComponent("XUiButton")
    
    self.Button.CallBack = function() 
        self:OnButtonClick()
    end
end

function XUiMoeWarParkourStage:Refresh()
    if not self.Stage then return end

   
    self.Button:SetRawImage(self.Stage:GetBackground())
    self.Button:SetNameByGroup(0, self.Stage:GetDuringTime())
    self.Button:SetNameByGroup(1, self.Stage:GetAllTimeHigh())
    
    local state = self.Stage:GetState()

    if state == XMoeWarConfig.ParkourGameState.Over then
        self.Button:SetDisable(true)
        self.TimeOver.gameObject:SetActiveEx(true)
        self.Lock.gameObject:SetActiveEx(false)
    elseif state == XMoeWarConfig.ParkourGameState.Unopened then
        self.Button:SetDisable(true)
        self.TimeOver.gameObject:SetActiveEx(false)
        self.Lock.gameObject:SetActiveEx(true)
        self.TxtOpenTime.text = XUiHelper.GetText("PivotCombatLockTimeTxt", self.Stage:GetOpenTime()) 
    elseif state == XMoeWarConfig.ParkourGameState.Opening then
        self.Button:SetDisable(false)
        self.TimeOver.gameObject:SetActiveEx(false)
        self.Lock.gameObject:SetActiveEx(false)
    end
end

function XUiMoeWarParkourStage:OnButtonClick()
    local isOverTime = self.Stage:IsOverTime()
    local isUnLock = self.Stage:IsUnLock()
    if isOverTime or not isUnLock then
        return
    end
    
    XLuaUiManager.Open("UiMoeWarParkourPrepare", self.Stage)
end


--=========================================类分界线=========================================--


local XUiMoeWarParkourMain = XLuaUiManager.Register(XLuaUi, "UiMoeWarParkourMain")
local REFRESH_INTERVAL = XScheduleManager.SECOND * 60 -- 界面关卡状态每分钟刷新一次

function XUiMoeWarParkourMain:OnAwake()
    self:InitCb()
end 

function XUiMoeWarParkourMain:OnStart()
    self.StageList = XDataCenter.MoeWarManager.GetParkourStageList()
    self.UiStageList = {}
    self:InitView()
    
    self:SetAutoCloseInfo(XDataCenter.MoeWarManager.GetParkourEndTime(), function(isClose)
        if isClose then
            self:Close()
        end
    end)
    
    self.TimerId = XScheduleManager.ScheduleForever(function() 
        self:RefreshStage()
    end, REFRESH_INTERVAL)
end

function XUiMoeWarParkourMain:OnEnable()
    XUiMoeWarParkourMain.Super.OnEnable(self)
    self.TxtTicketNum.text = XDataCenter.MoeWarManager.GetParkourTicket()
end

function XUiMoeWarParkourMain:OnDestroy()
    if XTool.IsNumberValid(self.TimerId) then
        XScheduleManager.UnSchedule(self.TimerId)
        self.TimerId = nil
    end
end

function XUiMoeWarParkourMain:OnGetEvents()
    return {
        XEventId.EVENT_MOE_WAR_PREPARATION_UPDATE,
        XEventId.EVENT_MOE_WAR_PARKOUR_UPDATE,
    }
end

function XUiMoeWarParkourMain:OnNotify(event, ...)
    local args = { ... }
    if event == XEventId.EVENT_MOE_WAR_PREPARATION_UPDATE then
        XDataCenter.MoeWarManager.OnPreparationDataUpdate()
    elseif event == XEventId.EVENT_MOE_WAR_PARKOUR_UPDATE then
        self.TxtTicketNum.text = XDataCenter.MoeWarManager.GetParkourTicket()
    end
end

function XUiMoeWarParkourMain:InitCb()
    self:BindExitBtns(self.BtnBack, self.BtnMainUi)
    self:BindHelpBtn(self.BtnHelp, "MoeWarParkourMain")
    self.BtnTcanchaungBlueLight.CallBack = function()
        XDataCenter.MoeWarManager.JumpToTeach()
    end
end 

function XUiMoeWarParkourMain:InitView()
    for i, stage in ipairs(self.StageList or {}) do
        local ui = i == 1 and self.GridStage or CS.UnityEngine.Object.Instantiate(self.GridStage, self.PanelStage, false)
        local grid = XUiMoeWarParkourStage.New(ui, stage)
        self.UiStageList[i] = grid
        grid:Refresh()
    end
    
    local itemId = XDataCenter.ItemManager.ItemId.MoeWarRespondItemId
    XUiHelper.NewPanelActivityAssetSafe( { itemId }, self.PanelSpecialTool, self)
    
end

function XUiMoeWarParkourMain:RefreshStage()
    for _, grid in ipairs(self.UiStageList or {}) do
        grid:Refresh()
    end
end 