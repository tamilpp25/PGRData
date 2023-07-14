local CSDGTweeningEase_Linear = CS.DG.Tweening.Ease.Linear
local Vector3 = CS.UnityEngine.Vector3

local tableInsert = table.insert

local XUiSlotMachineIconItem = require("XUi/XUiSlotMachine/XUiSlotMachineIconItem")
---@class XUiSlotMachinePanel
local XUiSlotMachinePanel = XClass(nil, "XUiSlotMachinePanel")

local ROLL_ONE_CIRCLE_TIME = 0.5 -- 匀速滚动一圈时间
local ICON_LAST_ROLL_TIME = 0.8
local ICON_LIST01_ROLL_COUNT = 4
local ICON_LIST02_ROLL_COUNT = 6
local ICON_LIST03_ROLL_COUNT = 8

---@param rootUi XUiSlotMachine
function XUiSlotMachinePanel:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RectTransform = ui
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self:Init()
    XUiHelper.RegisterClickEvent(self, self.BtnSkip, self.OnBtnSkipClick)
    self:SetBtnSkipActive(false)
end

function XUiSlotMachinePanel:Init()
    self.IconHeight = self.IconTmp.rect.height
    self.IconsPool1 = {}
    self.IconsPool2 = {}
    self.IconsPool3 = {}
    self.TweenSequencePool1 = nil
    self.TweenSequencePool2 = nil
    self.TweenSequencePool3 = nil
    self.IsSkipAnim = false
end

function XUiSlotMachinePanel:Refresh(machineId)
    self.CurMachineEntity = XDataCenter.SlotMachineManager.GetSlotMachineDataEntityById(machineId)
    self.MachineState = XDataCenter.SlotMachineManager.CheckSlotMachineState(machineId)
    if self.MachineState == XSlotMachineConfigs.SlotMachineState.Locked then
        self.SlotmachineLock:SetRawImage(self.CurMachineEntity:GetMachineLockImage())
        self.SlotmachineLock.gameObject:SetActiveEx(true)
        self.SlotmachineBg.gameObject:SetActiveEx(false)
        self.RootUi.EffectPinmu.gameObject:SetActiveEx(false)
        self.RootUi.EffectWord.gameObject:SetActiveEx(false) -- 文字特效
    else
        self.SlotmachineBg:SetRawImage(self.CurMachineEntity:GetMachineImage())
        self.SlotmachineBg.gameObject:SetActiveEx(true)
        self.SlotmachineLock.gameObject:SetActiveEx(false)
        self.RootUi.EffectPinmu.gameObject:SetActiveEx(true)
        self.RootUi.EffectWord.gameObject:SetActiveEx(machineId == 2) -- 文字特效

        self:RefreshWindow()
    end
end

function XUiSlotMachinePanel:RefreshWindow()
    if self.CurMachineEntity then
        local reverseIconList = self:GetReverseTable(self.CurMachineEntity:GetIcons())
        self.MaxIconListHeight = #reverseIconList * self.IconHeight
        tableInsert(reverseIconList, reverseIconList[1])

        local IconsData = {}
        self.IconIdToIndex = {}
        local iconsCount = #reverseIconList
        for index, iconId in ipairs(reverseIconList) do
            local data = {
                IconId = iconId,
            }
            tableInsert(IconsData, data)
            local positionIndex = (iconsCount - index + 1)
            if not self.IconIdToIndex[iconId] then
                self.IconIdToIndex[iconId] = positionIndex
            end
        end

        local onCreateCb = function(item, data)
            item:SetActiveEx(true)
            item:OnCreate(data)
        end

        XUiHelper.CreateTemplates(self.RootUi, self.IconsPool1, IconsData, XUiSlotMachineIconItem.New, self.IconTmp, self.IconList01, onCreateCb)
        XUiHelper.CreateTemplates(self.RootUi, self.IconsPool2, IconsData, XUiSlotMachineIconItem.New, self.IconTmp, self.IconList02, onCreateCb)
        XUiHelper.CreateTemplates(self.RootUi, self.IconsPool3, IconsData, XUiSlotMachineIconItem.New, self.IconTmp, self.IconList03, onCreateCb)
    end
end

function XUiSlotMachinePanel:StartRoll(iconIdList, cb)
    if #iconIdList ~= 3 then
        XLog.Error("Icon Count Is Not 3")
        return
    end
    self:PlayRollAnimation(self.IconIdToIndex[iconIdList[1]], self.IconIdToIndex[iconIdList[2]], self.IconIdToIndex[iconIdList[3]], cb)
end

function XUiSlotMachinePanel:PlayRollAnimation(idx1, idx2, idx3, cb)
    self.IconList01.transform:DOLocalMoveY(-self.MaxIconListHeight, ROLL_ONE_CIRCLE_TIME):SetEase(CSDGTweeningEase_Linear):OnComplete(function()
        self:RollUniformSpeed(self.IconList01.gameObject, ICON_LIST01_ROLL_COUNT, function()
            self:RollToIconByIndex(self.IconList01.gameObject, idx1, function()
                self.RootUi.Effect01.gameObject:SetActiveEx(false)
                self.RootUi.Effect01.gameObject:SetActiveEx(true)
            end)
        end)
    end)
    self.IconList02.transform:DOLocalMoveY(-self.MaxIconListHeight, ROLL_ONE_CIRCLE_TIME):SetEase(CSDGTweeningEase_Linear):OnComplete(function()
        self:RollUniformSpeed(self.IconList02.gameObject, ICON_LIST02_ROLL_COUNT, function()
            self:RollToIconByIndex(self.IconList02.gameObject, idx2, function()
                self.RootUi.Effect02.gameObject:SetActiveEx(false)
                self.RootUi.Effect02.gameObject:SetActiveEx(true)
            end)
        end)
    end)
    self.IconList03.transform:DOLocalMoveY(-self.MaxIconListHeight, ROLL_ONE_CIRCLE_TIME):SetEase(CSDGTweeningEase_Linear):OnComplete(function()
        self:RollUniformSpeed(self.IconList03.gameObject, ICON_LIST03_ROLL_COUNT, function()
            self:RollToIconByIndex(self.IconList03.gameObject, idx3, function()
                self.RootUi.Effect03.gameObject:SetActiveEx(false)
                self.RootUi.Effect03.gameObject:SetActiveEx(true)
                if cb then cb() end
            end)
        end)
    end)
end

function XUiSlotMachinePanel:RollUniformSpeed(gameObject, rollCount, cb)
    gameObject.transform.localPosition = Vector3(gameObject.transform.localPosition.x, 0, 0)
    gameObject.transform:DOLocalMoveY(-self.MaxIconListHeight, ROLL_ONE_CIRCLE_TIME):SetLoops(rollCount):SetEase(CSDGTweeningEase_Linear):OnComplete(function()
        if cb then cb() end
    end)
end

function XUiSlotMachinePanel:RollToIconByIndex(gameObject, index, cb)
    if index > 0 then
        local iconCount = index - 1
        local needRollPix = iconCount * self.IconHeight
        gameObject.transform.localPosition = Vector3(gameObject.transform.localPosition.x, 0, 0)
        if cb then
            gameObject.transform:DOLocalMoveY(-needRollPix, ICON_LAST_ROLL_TIME):OnComplete(function()
                cb()
            end)
        else
            gameObject.transform:DOLocalMoveY(-needRollPix, ICON_LAST_ROLL_TIME)
        end
    end
end

function XUiSlotMachinePanel:GetReverseTable(arr) -- 翻转数组（只能是数组）
    local tmp = {}
    for i = #arr, 1, -1 do
        tableInsert(tmp, arr[i])
    end

    return tmp
end

---@param transform UnityEngine.Transform
function XUiSlotMachinePanel:GetRollAnimSequence(transform, index, rollCount, effectGameObject, cb)
    local iconCount = index - 1
    local needRollPix = iconCount * self.IconHeight
    local sequence = CS.DG.Tweening.DOTween.Sequence()
    sequence:Append(transform:DOLocalMoveY(-self.MaxIconListHeight, ROLL_ONE_CIRCLE_TIME):SetEase(CSDGTweeningEase_Linear):OnComplete(function()
        transform.localPosition = Vector3(transform.localPosition.x, 0, 0)
    end))
    sequence:Append(transform:DOLocalMoveY(-self.MaxIconListHeight, ROLL_ONE_CIRCLE_TIME):SetLoops(rollCount):SetEase(CSDGTweeningEase_Linear):OnComplete(function()
        transform.localPosition = Vector3(transform.localPosition.x, 0, 0)
    end))
    sequence:Append(transform:DOLocalMoveY(-needRollPix, ICON_LAST_ROLL_TIME):OnComplete(function()
        effectGameObject:SetActiveEx(false)
        effectGameObject:SetActiveEx(true)
    end))
    sequence.onComplete = function()
        if cb then cb() end
    end
    sequence.onKill = function()
        if self.IsSkipAnim then
            transform.localPosition = Vector3(transform.localPosition.x, -needRollPix, 0)
            if cb then cb() end
        end
    end
    return sequence
end

function XUiSlotMachinePanel:StartRollNew(iconIdList, cb)
    if #iconIdList ~= 3 then
        XLog.Error("Icon Count Is Not 3")
        return
    end
    if self.IsSkipAnim then
        if cb then cb() end
        return
    end
    self:KillSequence()
    self.TweenSequencePool1 = self:GetRollAnimSequence(self.IconList01, self.IconIdToIndex[iconIdList[1]], ICON_LIST01_ROLL_COUNT, self.RootUi.Effect01.gameObject)
    self.TweenSequencePool2 = self:GetRollAnimSequence(self.IconList02, self.IconIdToIndex[iconIdList[2]], ICON_LIST02_ROLL_COUNT, self.RootUi.Effect02.gameObject)
    self.TweenSequencePool3 = self:GetRollAnimSequence(self.IconList03, self.IconIdToIndex[iconIdList[3]], ICON_LIST03_ROLL_COUNT, self.RootUi.Effect03.gameObject, cb)
    self.TweenSequencePool1.Play()
    self.TweenSequencePool2.Play()
    self.TweenSequencePool3.Play()
end

function XUiSlotMachinePanel:KillSequence()
    if self.TweenSequencePool1 then
        self.TweenSequencePool1:Kill()
        self.TweenSequencePool1 = nil
    end
    if self.TweenSequencePool2 then
        self.TweenSequencePool2:Kill()
        self.TweenSequencePool2 = nil
    end
    if self.TweenSequencePool3 then
        self.TweenSequencePool3:Kill()
        self.TweenSequencePool3 = nil
    end
end

function XUiSlotMachinePanel:AsynWaitTime(second, cb)
    if self.IsSkipAnim then
        if cb then cb() end
        return
    end
    self.WaitCb = cb
    self.WaitTime = XScheduleManager.ScheduleOnce(function()
        local tempCb = self.WaitCb
        self.WaitCb = nil
        self.WaitTime = nil
        if tempCb then
            tempCb()
        end
    end, second * XScheduleManager.SECOND)
end

function XUiSlotMachinePanel:KillWaitTime()
    if self.WaitTime then
        XScheduleManager.UnSchedule(self.WaitTime)
        self.WaitTime = nil
    end
    local tempCb = self.WaitCb
    self.WaitCb = nil
    if tempCb then
        tempCb()
    end
end

function XUiSlotMachinePanel:OnBtnSkipClick()
    if self.IsSkipAnim then
        return
    end
    self:SetIsSkipActive(true)
    self:SetBtnSkipActive(false)
    self:KillSequence()
    self:KillWaitTime()
end

function XUiSlotMachinePanel:SetBtnSkipActive(value)
    self.BtnSkip.gameObject:SetActiveEx(value)
end

function XUiSlotMachinePanel:SetIsSkipActive(value)
    self.IsSkipAnim = value
end

function XUiSlotMachinePanel:GetIsSkipAnim()
    return self.IsSkipAnim
end

return XUiSlotMachinePanel