local CSDGTweeningEase_Linear = CS.DG.Tweening.Ease.Linear
local Vector3 = CS.UnityEngine.Vector3

local tableInsert = table.insert

local XUiSlotMachineIconItem = require("XOverseas/XUi/XUiSlotMachine/XUiSlotMachineIconItem")

local XUiSlotMachinePanel = XClass(nil, "XUiSlotMachinePanel")

local ROLL_ONE_CIRCLE_TIME = 0.5 -- 匀速滚动一圈时间
local ICON_LAST_ROLL_TIME = 0.8
local ICON_LIST01_ROLL_COUNT = 4
local ICON_LIST02_ROLL_COUNT = 6
local ICON_LIST03_ROLL_COUNT = 8

function XUiSlotMachinePanel:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RectTransform = ui
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    self:Init()
end

function XUiSlotMachinePanel:Init()
    self.IconHeight = self.IconTmp.rect.height
    self.IconsPool1 = {}
    self.IconsPool2 = {}
    self.IconsPool3 = {}
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
            local positionIndex = (iconsCount-index+1)
            if not self.IconIdToIndex[iconId] then
                self.IconIdToIndex[iconId] = positionIndex
            end
        end

        local onCreateCb = function (item, data)
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

function XUiSlotMachinePanel:RollToIconByIndex(gameObject, index , cb)
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

return XUiSlotMachinePanel