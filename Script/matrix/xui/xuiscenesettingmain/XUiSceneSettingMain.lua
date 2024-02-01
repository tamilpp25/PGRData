---场景设置切换界面的管理器
local XUiSceneSettingMain=XLuaUiManager.Register(XLuaUi,"UiSceneSettingMain")

local XRightTagPanel=require("XUi/XUiSceneSettingMain/XRightTagPanel")
local XDynamicSceneList=require('XUi/XUiSceneSettingMain/XDynamicSceneList')
local XBackgroundScene=require('XUi/XUiSceneSettingMain/XBackgroundScene')
local LockBackDelayCD = CS.XGame.ClientConfig:GetFloat("UiSceneSettingMainBtnBackLockTime")

local firstLoad

local UiMainMenuType = {
    Main = 1,
    Second = 2,
}
--region 生命周期

function XUiSceneSettingMain:OnAwake()
    --初始化基本按钮的回调事件
    self:InitCb()
    --初始化动态列表管理器
    self.SceneList=XDynamicSceneList.New(self.PanelSceneList)
    --初始化右上角信息栏管理器
    self.RightTagPanel=XRightTagPanel.New(self.Bg,self)
    --初始化场景显示控制器
    self.BackgroundScene=XBackgroundScene.New(self)
    --初始化事件监听
    self:InitEvent()
end

function XUiSceneSettingMain:OnStart(uiManStateCache, previewSceneId)
    if uiManStateCache then
        self.uiMainStateCache=uiManStateCache
    else
        self.uiMainStateCache=UiMainMenuType.Second
    end
    firstLoad=true
    self:RefreshSceneList(previewSceneId)
    self:RefreshRightTagPanel()
    self:RefreshSceneDisplay()
    self:RefreshSyncBtnState()
    
end

function XUiSceneSettingMain:OnEnable()
    self:PlayAnimationWithMask("DarkDisable")
    if not firstLoad then
        self.LockBack=true
        self.LockBackScheduleId=XScheduleManager.Schedule(function() self.LockBack=false  end,0,1,XScheduleManager.SECOND*LockBackDelayCD)
    else
        firstLoad=false
    end
    --开启监视电量、时间的轮询
    self.BackgroundScene:UpdateBatteryMode()
    self.BatteryEffectSchedule = XScheduleManager.ScheduleForever(function()
        self.BackgroundScene:UpdateBatteryMode()
    end, 5 * XScheduleManager.SECOND)
    -- 开启时钟
    self:ReStartClockTime()
end

function XUiSceneSettingMain:OnDisable()
    if self.LockBackScheduleId then
        XScheduleManager.UnSchedule(self.LockBackScheduleId)
    end

    -- 关闭时钟
    self:StopClockTime()
    --关闭电量、时间的监视
    XScheduleManager.UnSchedule(self.BatteryEffectSchedule)
    self.BatteryEffectSchedule=nil
end

function XUiSceneSettingMain:OnDestroy()
    self.uiMainStateCache=nil
end

--endregion

--region 初始化

---初始化场景中各自按钮点击回调事件
function XUiSceneSettingMain:InitCb()
    self.BtnBack.CallBack=function()
        if self.LockBack then return end
        XEventManager.DispatchEvent(XEventId.EVENT_SCENE_UIMAIN_RIGHTMIDTYPE_CHANGE, self.uiMainStateCache)
        self:Close()
    end
    self.BtnTongBlack.CallBack=function() 
        --判断按钮是否可交互
        if self.BtnTongBlackState==0 then
            --执行同步
            local _curSelectSceneId=self.SceneList:GetCurDisplaySceneId()
            local _curChara=XDataCenter.DisplayManager.GetDisplayChar()

            XDataCenter.PhotographManager.ChangeDisplay(_curSelectSceneId, _curChara.Id, _curChara.FashionId, function ()
                self:RefreshSceneList()
                self:RefreshSyncBtnState()
                XUiManager.TipText("PhotoModeChangeSuccess")
                local state= XSaveTool.GetData(XDataCenter.PhotographManager.GetSceneStateKey(_curSelectSceneId))
                if state~=2 and XDataCenter.PhotographManager.CheckSceneIsHaveById(_curSelectSceneId) then
                    state=2
                    XSaveTool.SaveData(XDataCenter.PhotographManager.GetSceneStateKey(_curSelectSceneId),state)
                end
                
            end)
        elseif self.BtnTongBlackState==2 then
            --提示其解锁方式
            local sceneTemplate = XDataCenter.PhotographManager.GetSceneTemplateById(self.SceneList:GetCurDisplaySceneId())
            XUiManager.TipError(sceneTemplate.LockDec)
        end
    end
    self.BtnTcanchaungBlue.CallBack=function()
        self:PlayAnimationWithMask("DarkEnable", function ()
            XDataCenter.PhotographManager.OpenScenePreview(self.SceneList:GetCurDisplaySceneId())
        end)
    end
    self.BtnTongGet.CallBack = function()
        local currentSceneId = self.SceneList:GetCurDisplaySceneId()
        local skipId = XDataCenter.PhotographManager.GetSceneSkipIdById(currentSceneId)

        if XTool.IsNumberValid(skipId) then
            XFunctionManager.SkipInterface(skipId)
        end
    end
end

function XUiSceneSettingMain:InitEvent()
    self.SceneList:ConnectSignal('ChangeSceneSelected',self,self.RefreshSceneDisplay)
end
--endregion

--region 数据更新
function XUiSceneSettingMain:RefreshSceneList(previewSceneId)
    local curSceneId=XDataCenter.PhotographManager.GetCurSceneId()
    local sortedList=self:SortSceneIdList(XDataCenter.PhotographManager.GetSceneIdList(),curSceneId)
    local hasConditionList=self:CheckAllSceneIsHasByList(sortedList)
    --设置当前正在使用的场景
    self.SceneList:RefreshCurrentSceneId(curSceneId,previewSceneId and previewSceneId or curSceneId)
    --传入各场景的拥有情况
    self.SceneList:RefreshIsHasData(hasConditionList)
    --传入排好序的场景列表
    self.SceneList:RefreshTableData(sortedList)
    
end

function XUiSceneSettingMain:RefreshRightTagPanel()
    local template=XDataCenter.PhotographManager.GetSceneTemplateById(self.SceneList:GetCurDisplaySceneId())
    self.RightTagPanel:RefreshData(template)   
end

function XUiSceneSettingMain:RefreshSceneDisplay()
    local curSceneId=self.SceneList:GetCurDisplaySceneId()
    --获取当前场景的配置
    local template=XDataCenter.PhotographManager.GetSceneTemplateById(curSceneId)
    --切换场景
    if not firstLoad then
        self:PlayAnimation('Loading',function()
            self.BackgroundScene:ChangeScenePreview(template.SceneModelId,firstLoad,curSceneId)
        end)
    else
        self.BackgroundScene:ChangeScenePreview(template.SceneModelId,firstLoad,curSceneId)
    end
end

function XUiSceneSettingMain:RefreshSyncBtnState()
    local selectedId=self.SceneList:GetCurDisplaySceneId()
    if selectedId==self.SceneList.CurSceneId then
        --禁用，并显示“使用中”
        self.BtnTongGet.gameObject:SetActiveEx(false)
        self.BtnTongBlack.gameObject:SetActiveEx(true)
        self.BtnTongBlack:SetName(XUiHelper.GetText('SceneSettingUsing'))
        self.BtnTongBlack:SetButtonState(3)
        self.BtnTongBlackState=1
    elseif not XDataCenter.PhotographManager.CheckSceneIsHaveById(selectedId) then
        if XDataCenter.PhotographManager.CheckSceneCanSkipById(selectedId) then
            self.BtnTongBlack.gameObject:SetActiveEx(false)
            self.BtnTongGet.gameObject:SetActiveEx(true)
        else
            self.BtnTongBlack.gameObject:SetActiveEx(true)
            self.BtnTongGet.gameObject:SetActiveEx(false)
            --禁用,并显示"未解锁"
            self.BtnTongBlack:SetName(XUiHelper.GetText('SceneSettingLock'))
            self.BtnTongBlack:SetButtonState(3)
            self.BtnTongBlackState=2
        end
    else
        --开启
        self.BtnTongGet.gameObject:SetActiveEx(false)
        self.BtnTongBlack.gameObject:SetActiveEx(true)
        self.BtnTongBlack:SetName(XUiHelper.GetText('SceneSettingNormal'))

        self.BtnTongBlack:SetButtonState(0)
        self.BtnTongBlackState=0
    end
end
---对场景显示进行排序
---1.优先显示使用中的场景
---2.优先显示已解锁场景
---3.其他按照表中优先级值进行排序
function XUiSceneSettingMain:SortSceneIdList(list,_curSceneId)
    table.sort(list,function(sceneA,sceneB)
        --正在使用的排在其他的前面
        if sceneA==_curSceneId then
            return true
        elseif sceneB==_curSceneId then
            return false
        end
        
        local hasA=XDataCenter.PhotographManager.CheckSceneIsHaveById(sceneA)
        local hasB=XDataCenter.PhotographManager.CheckSceneIsHaveById(sceneB)
        --已拥有的排在未拥有的前面
        if hasA and not hasB then
            return true
        end

        if hasB and not hasA then
            return false
        end
        
        local templateA=XDataCenter.PhotographManager.GetSceneTemplateById(sceneA)
        local templateB=XDataCenter.PhotographManager.GetSceneTemplateById(sceneB)
        --其他情况按优先级排序
        return templateA.Priority>templateB.Priority
        
    end)
    return list
end

function XUiSceneSettingMain:CheckAllSceneIsHasByList(list)
    local hasCondition={}
    
    for index, id in ipairs(list) do
        local isHas=XDataCenter.PhotographManager.CheckSceneIsHaveById(id) and true or false
        table.insert(hasCondition,isHas)
    end
    
    return hasCondition
end

function XUiSceneSettingMain:ReStartClockTime()
    self:StopClockTime()
    -- 开启时钟
    self.ClockTimer = XUiHelper.SetClockTimeTempFun(self)
end

function XUiSceneSettingMain:StopClockTime()
    -- 关闭时钟
    if self.ClockTimer then
        XUiHelper.StopClockTimeTempFun(self, self.ClockTimer)
        self.ClockTimer = nil
    end
end
--endregion

return XUiSceneSettingMain