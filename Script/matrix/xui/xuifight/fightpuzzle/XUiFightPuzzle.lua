local XUiFightPuzzle = XLuaUiManager.Register(XLuaUi,  "UiFightPuzzle")

local TIME_ERROR_TIPS = 5 -- 失败提示
local TIME_SUCCESS_TIPS = 2 --成功提示
local DOOR_ARRAY = --迷宫谜底
{
    {true,false,false,false,false,false,false,false,false},
    {false,false,false,false,false,false,false,true,false},
    {false,false,false,false,true,false,false,false,false},
    {false,false,false,false,false,false,true,false,false},
}
--Override
function XUiFightPuzzle:OnAwake()
    self.BtnBoomEffect = 
    {
        self.Effect1.transform,
        self.Effect2.transform,
        self.Effect3.transform,
        self.Effect4.transform,
        self.Effect5.transform,
        self.Effect6.transform,
        self.Effect7.transform,
        self.Effect8.transform,
        self.Effect9.transform,
    };
    
    self.BtnTipsEffect = 
    {
        self.Tips1.gameObject,
        self.Tips2.gameObject,
        self.Tips3.gameObject,
        self.Tips4.gameObject,
        self.Tips5.gameObject,
        self.Tips6.gameObject,
        self.Tips7.gameObject,
        self.Tips8.gameObject,
        self.Tips9.gameObject,
    }
end

function XUiFightPuzzle:OnStart()
    self:RegisterUIEvent();
end

function XUiFightPuzzle:OnEnable(iType)
    self:ResetUI();
    self.CurPage = iType;
    self.Map1.gameObject:SetActiveEx(1 == iType);
    self.Map2.gameObject:SetActiveEx(2 == iType);
    self.Map3.gameObject:SetActiveEx(3 == iType);
    self.Map4.gameObject:SetActiveEx(4 == iType);
end

function XUiFightPuzzle:OnDisable()
    self:ResetSchedule(); 
end
---End Override

------------------------------------------------------------------
function XUiFightPuzzle:ResetSchedule()
    if self.ErrorTimerID then
        XScheduleManager.UnSchedule(self.ErrorTimerID)
        self.ErrorTimerID = nil
    end
end

function XUiFightPuzzle:RegisterUIEvent()
    self.BtnTanchuangClose.CallBack = function() self:ClosePuzzleUI() end
    self:RegisterClickEvent(self.BtnSelect1, function() self:ChoiceDoor(1, self.BtnSelect1)  end)
    self:RegisterClickEvent(self.BtnSelect2, function() self:ChoiceDoor(2, self.BtnSelect2)  end)
    self:RegisterClickEvent(self.BtnSelect3, function() self:ChoiceDoor(3, self.BtnSelect3)  end)
    self:RegisterClickEvent(self.BtnSelect4, function() self:ChoiceDoor(4, self.BtnSelect4)  end)
    self:RegisterClickEvent(self.BtnSelect5, function() self:ChoiceDoor(5, self.BtnSelect5)  end)
    self:RegisterClickEvent(self.BtnSelect6, function() self:ChoiceDoor(6, self.BtnSelect6)  end)
    self:RegisterClickEvent(self.BtnSelect7, function() self:ChoiceDoor(7, self.BtnSelect7)  end)
    self:RegisterClickEvent(self.BtnSelect8, function() self:ChoiceDoor(8, self.BtnSelect8)  end)
    self:RegisterClickEvent(self.BtnSelect9, function() self:ChoiceDoor(9, self.BtnSelect9)  end)
end

--选择出口
function XUiFightPuzzle:ChoiceDoor(index, btn)
    if self.IsLock then return end
    self.IsLock = true;
    self.CurBtn = btn;
    for i = 1, 9 do
        self.BtnTipsEffect[i]:SetActiveEx(false);
    end
    
    self:Result(DOOR_ARRAY[self.CurPage][index], index);
end 

function XUiFightPuzzle:Result(isTure, index)
    self.UiResult = isTure;
    if isTure then
        self.RImgTips1.gameObject:SetActiveEx(true);
        local tipsCount= TIME_SUCCESS_TIPS;
        local function SuccessAction()
            tipsCount = tipsCount - 1;
            if(tipsCount <= 0 ) then
                self.UiResult = false;
                self:Close()
            end
        end
        
        self.ErrorTimerID = XScheduleManager.Schedule(SuccessAction, XScheduleManager.SECOND,TIME_SUCCESS_TIPS, 0);
        self.CurBtn:SetButtonState(CS.UiButtonState.Select)
        self.Dianliu01.gameObject:SetActiveEx(self.CurPage == 1)
        self.Dianliu02.gameObject:SetActiveEx(self.CurPage == 2)
        self.Dianliu03.gameObject:SetActiveEx(self.CurPage == 3)
        self.Dianliu04.gameObject:SetActiveEx(self.CurPage == 4)

        local fight = CS.XFight.Instance
        if fight then
            fight.InputControl:OnClick(CS.XNpcOperationClickKey.CommonMiniGameWin, CS.XOperationClickType.KeyDown)
            fight.InputControl:OnClick(CS.XNpcOperationClickKey.CommonMiniGameWin, CS.XOperationClickType.KeyUp)
        end
    else
       self.TimerText.text = tostring(TIME_ERROR_TIPS)
        local tickTime = TIME_ERROR_TIPS;
        local function action()
            tickTime = tickTime - 1;
            self:TimerTick(tickTime);
        end
       
        self.ErrorTimerID = XScheduleManager.Schedule(action, XScheduleManager.SECOND,TIME_ERROR_TIPS, 0);
        self.RImgTips2.gameObject:SetActiveEx(true);
        self.CurBtn:SetButtonState(CS.UiButtonState.Disable)
        self.Baozha.transform:SetParent(self.BtnBoomEffect[index], false)
        self.Baozha.transform.localPosition = CS.UnityEngine.Vector3.zero
        self.Baozha.gameObject:SetActiveEx(true);
        XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, 794);
    end
end

function XUiFightPuzzle:TimerTick(timer)
   self.TimerText.text = tostring(timer);
    if timer <= 0 then
        self:ResetUI();
    end
end

function XUiFightPuzzle:ResetUI()
    self.RImgTips1.gameObject:SetActiveEx(false);
    self.RImgTips2.gameObject:SetActiveEx(false);
    self.Baozha.gameObject:SetActiveEx(false)
    self.Dianliu01.gameObject :SetActiveEx(false)
    self.Dianliu02.gameObject :SetActiveEx(false)
    self.Dianliu03.gameObject :SetActiveEx(false)
    self.Dianliu04.gameObject :SetActiveEx(false)
    self.IsLock = false;
    self.UiResult = false;
    if self.CurBtn then
        self.CurBtn:SetButtonState(CS.UiButtonState.Normal)
    end
    self.CurBtn = nil;

    for i = 1, 9 do
        self.BtnTipsEffect[i]:SetActiveEx(true);
    end

    self:ResetSchedule();
end

function XUiFightPuzzle:ClosePuzzleUI()
    if self.UiResult then return end--播放胜利特效的时候，不许关闭界面
  
    local fight = CS.XFight.Instance
    if fight then
        fight.InputControl:OnClick(CS.XNpcOperationClickKey.CommonUiClose, CS.XOperationClickType.KeyDown)
        fight.InputControl:OnClick(CS.XNpcOperationClickKey.CommonUiClose, CS.XOperationClickType.KeyUp)
    end
    self:Close()
end

return XUiFightPuzzle