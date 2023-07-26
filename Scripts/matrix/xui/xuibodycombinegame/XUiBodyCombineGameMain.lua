---==============================
   ---@desc: 关卡入口按钮
---==============================
local XUiButtonGrid = XClass(nil, "XUiButtonGrid")
--关卡状态
local StageState    = XDataCenter.BodyCombineGameManager.StageState
--解锁的状态
local LockState     = XDataCenter.BodyCombineGameManager.LockState
--字体颜色
local Color = {
    Red = "red",
    White = "white",
}

function XUiButtonGrid:Ctor(ui, stageId)
    
    XTool.InitUiObjectByUi(self, ui)
    
    self.Stage = XDataCenter.BodyCombineGameManager.GetStage(stageId)
    
    self.State = XDataCenter.BodyCombineGameManager.GetStageState(self.Stage:GetStageId())
    
    self:InitUI(stageId)
    self:AddListener()
end

function XUiButtonGrid:InitUI(stageId)
    self.Button = self.Transform:GetComponent("XUiButton")
    
    local openBanner = self.Stage:GetOpenBanner()
    local finishBanner = self.Stage:GetFinishBanner()
    self.RImgCome:SetRawImage(openBanner)
    self.RImgFinish:SetRawImage(finishBanner)
    local itemId = XDataCenter.BodyCombineGameManager.GetCoinItemId()
    self.RImgCoinIcon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(itemId))
    
    local stageName = self.Stage:GetStageName()
    self.TxtComeLevelTittle.text = stageName
    self.TxtLockLevelTittle.text = stageName

    self.RedPointId = XRedPointManager.AddRedPointEvent(self.Button, self.OnCheckButtonRedPoint, self, {
        XRedPointConditions.Types.CONDITION_BODYCOMBINEGAME_UNLOCKED_STAGE,
    }, stageId, false)
end


function XUiButtonGrid:Refresh()
    self.State = XDataCenter.BodyCombineGameManager.GetStageState(self.Stage:GetStageId())
    self:RefreshState()
end

---==============================
   ---@desc: 刷新关卡状态 
---==============================
function XUiButtonGrid:RefreshState()
    local showCome = self.State == StageState.Come
    local showPass = self.State == StageState.Pass
    local showLock = self.State == StageState.Lock
    
    self.PanelLock.gameObject:SetActiveEx(showLock)
    self.PanelCome.gameObject:SetActiveEx(showCome)
    self.PanelFinish.gameObject:SetActiveEx(showPass)

    self.Button.enabled = not showPass

    if showLock then
        local cost = self.Stage and self.Stage:GetCost() or 0
        local itemId = XDataCenter.BodyCombineGameManager.GetCoinItemId()
        local hasCount = XDataCenter.ItemManager.GetCount(itemId)
        local color = hasCount >= cost and Color.White or Color.Red
        self.TxtContent.text = CSXTextManagerGetText("BodyCombineGameCostTips", color, cost)
    end

    XRedPointManager.Check(self.RedPointId, self.Stage:GetStageId())
end


function XUiButtonGrid:AddListener()
    self.Button.CallBack = function()
        if self.State == StageState.Lock then
            local stageId = self.Stage:GetStageId()
            local lockState = XDataCenter.BodyCombineGameManager.GetLockState(stageId)
            if lockState == LockState.Unlocked then
                return
            elseif lockState == LockState.NoPassPreStage then
                local preStageId = self.Stage:GetPreStageId()
                local stage = XDataCenter.BodyCombineGameManager.GetStage(preStageId)
                local txt = CSXTextManagerGetText("BodyCombineGameLock1Tips", stage and stage:GetStageName() or "")
                XUiManager.TipError(txt)
                return
            elseif lockState == LockState.NoEnoughCoin then
                local cost = self.Stage and self.Stage:GetCost() or 0
                local itemId = XDataCenter.BodyCombineGameManager.GetCoinItemId()
                local itemName = XDataCenter.ItemManager.GetItemName(itemId)
                local txt = CSXTextManagerGetText("BodyCombineGameLock2Tips", itemName, cost, itemName)
                XUiManager.TipError(txt)
                return
            else
                XDataCenter.BodyCombineGameManager.BodyCombineUnlockRequest(stageId, handler(self, self.RefreshState))
            end
        end
        XLuaUiManager.Open("UiBodyCombineGamePlay", self.Stage)
    end
    
end

function XUiButtonGrid:OnCheckButtonRedPoint(count)
    self.Button:ShowReddot(count >= 0)
end



--===========================================================================
 ---@desc 接头霸王小游戏主界面
--===========================================================================
local XUiBodyCombineGameMain = XLuaUiManager.Register(XLuaUi, "UiBodyCombineGameMain")

local Stage_Members = 4 -- 关卡数量


function XUiBodyCombineGameMain:OnAwake()
    self:InitCB()
end 

function XUiBodyCombineGameMain:OnStart()
    
    local itemId = XDataCenter.BodyCombineGameManager.GetCoinItemId()
    self.AssetPanel = XUiHelper.NewPanelActivityAsset({ itemId }, self.PanelAsset)
    
    self.RImgTittle:SetRawImage(XDataCenter.BodyCombineGameManager.GetActivityTitle())

    self.TreasureRedDot = XRedPointManager.AddRedPointEvent(self.BtnTreasure, self.OnCheckTreasureRedPoint, self, {
        XRedPointConditions.Types.CONDITION_BODYCOMBINEGAME_REWARD,
    })
end

function XUiBodyCombineGameMain:OnEnable()

    self:RefreshStageButton()
    self:RefreshTaskProgress()

    self.TxtTime.text = XDataCenter.BodyCombineGameManager.GetActivityLeftTime()
    
    local isFinishAll = XDataCenter.BodyCombineGameManager.IsFinishAll()
    self.PanelAllLevel.gameObject:SetActiveEx(not isFinishAll)
    self.RImageSuccess.gameObject:SetActiveEx(isFinishAll)
    if isFinishAll then
        self.RImageSuccess:SetRawImage(XDataCenter.BodyCombineGameManager.GetFinishBanner())
    end

    if XDataCenter.BodyCombineGameManager.IsFirstTimeIn() then
        XUiManager.ShowHelpTip("BodyCombineGame")
    end
    
    self:CheckTreasureRedPoint()

    XEventManager.AddEventListener(XEventId.EVENT_BODYCOMBINEGAME_ACTIVITY_END, XDataCenter.BodyCombineGameManager.OnActivityEnd)
    
end

function XUiBodyCombineGameMain:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_BODYCOMBINEGAME_ACTIVITY_END, XDataCenter.BodyCombineGameManager.OnActivityEnd)
end

function XUiBodyCombineGameMain:OnGetEvents()
    return {
        XEventId.EVENT_BODYCOMBINEGAME_ACTIVITY_END,
        XEventId.EVENT_BODYCOMBINEGAME_TASK_REWARD,
    }
end

function XUiBodyCombineGameMain:OnNotify(evt, ...)
    local args = {...}
    if evt == XEventId.EVENT_BODYCOMBINEGAME_TASK_REWARD then
        self:CheckTreasureRedPoint()
        self:RefreshTaskProgress()
    end
end


--===========================================================================
 ---@desc 刷新按钮关卡按钮
--===========================================================================
function XUiBodyCombineGameMain:RefreshStageButton()

    local stageIds = XDataCenter.BodyCombineGameManager.GetCurActivityStageIds()
    
    for idx = 1, Stage_Members do
        local btnStage = self["StageButton"..idx]
        if not btnStage then
            local stageId = stageIds[idx]
            if not stageId then
                goto Continue
            end
            btnStage = XUiButtonGrid.New(self["PanelLevel"..idx], stageId)
            self["StageButton"..idx] = btnStage
        end
        if not btnStage then
            goto Continue
        end
        
        btnStage:Refresh()
        
        ::Continue::
    end
end

--===========================================================================
 ---@desc 刷新任务按钮状态
--===========================================================================
function XUiBodyCombineGameMain:RefreshTaskProgress()
    local taskFinish, taskTotal = XDataCenter.BodyCombineGameManager.TaskProgress()
    local taskProgress
    if taskTotal == 0 then
        taskProgress = 0
    else
        taskProgress = taskFinish / taskTotal
    end

    self.ImgJindu.fillAmount = taskProgress
    self.TxtStarNum.text = CSXTextManagerGetText("BodyCombineGameTaskProgress", taskFinish, taskTotal)
    self.ImgLingqu.gameObject:SetActiveEx(taskFinish > 0 and taskTotal == taskFinish)
end



function XUiBodyCombineGameMain:InitCB()
    self.BtnMainUi.CallBack = function() 
        XLuaUiManager.RunMain()
    end
    
    self.BtnBack.CallBack = function()
        self:Close()
    end

    self:BindHelpBtn(self.BtnHelp, "BodyCombineGame")
    
    self.BtnTreasure.CallBack = function()
        self:OnBtnTreasureClick()
    end
end 



function XUiBodyCombineGameMain:OnBtnTreasureClick()
    XLuaUiManager.Open("UiBodyCombineGameTask")
end

--检查奖励红点回调
function XUiBodyCombineGameMain:OnCheckTreasureRedPoint(count)
    self.BtnTreasure:ShowReddot(count >= 0)
end

--检查奖励红点
function XUiBodyCombineGameMain:CheckTreasureRedPoint()
    XRedPointManager.Check(self.TreasureRedDot)
end 

