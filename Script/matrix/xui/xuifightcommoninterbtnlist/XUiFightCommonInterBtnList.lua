local CSXKeyCode = CS.XKeyCode
local CSXInputManager = CS.XInputManager
local CSXNpcOperationClickKey = CS.XNpcOperationClickKey
local Input = CS.UnityEngine.Input

local XUiCommonInterBtn = require("XUi/XUiFightCommonInterBtnList/XUiCommonInterBtn")

local XUiFightCommonInterBtnList = XLuaUiManager.Register(XLuaUi, "UiFightCommonInterBtnList")

function XUiFightCommonInterBtnList:OnAwake()
    self.CommonInterBtnPool = {}
    self.GridDatas = {}
    self.GridDataList = {}
    self.CurBtnOptionPcIndex = 1    --光标所在位置的按钮下标
    self.BtnOption.gameObject:SetActiveEx(false)
    self.OnPcClickCb = handler(self, self.OnPcClick)
    self.BtnOptionXUiButtons = {}
    self.CSWorldToViewPoint = CS.XFightUiManager.WorldToViewPoint
    self.CSXRLManagerCamera = CS.XRLManager.Camera
    self.OriginOptionsPos = self.Options.transform.anchoredPosition
    self.OriginOptionsAnchorMin = self.Options.transform.anchorMin
    self.OriginOptionsAnchorMax = self.Options.transform.anchorMax
end

function XUiFightCommonInterBtnList:OnStart()
    self.IconRoller.gameObject:SetActiveEx(false)
    self.BtnOptionPC.gameObject:SetActiveEx(false)
    self.BtnOptionPC.transform:SetParent(self.Options.transform)
end

function XUiFightCommonInterBtnList:OnEnable()
    CSXInputManager.RegisterOnClick(CSXKeyCode.UpArrow, handler(self, self.ReduceBtnOptionPcIndex))
    CSXInputManager.RegisterOnClick(CSXKeyCode.Axis7P, handler(self, self.ReduceBtnOptionPcIndex))
    CSXInputManager.RegisterOnClick(CSXKeyCode.DownArrow, handler(self, self.AddBtnOptionPcIndex))
    CSXInputManager.RegisterOnClick(CSXKeyCode.Axis7M, handler(self, self.AddBtnOptionPcIndex))
    CSXInputManager.RegisterOnClick(CS.XOperationType.Fight, self.OnPcClickCb)
    self.Timer = XScheduleManager.ScheduleForever(handler(self, self.Update), 0)
    CS.XRLManager.Camera.InputScaleEnable = not XDataCenter.UiPcManager.IsPc()
end

function XUiFightCommonInterBtnList:OnDisable()
    CSXInputManager.UnregisterOnClick(CSXKeyCode.UpArrow)
    CSXInputManager.UnregisterOnClick(CSXKeyCode.Axis7P)
    CSXInputManager.UnregisterOnClick(CSXKeyCode.DownArrow)
    CSXInputManager.UnregisterOnClick(CSXKeyCode.Axis7M)
    CSXInputManager.UnregisterOnClick(CS.XOperationType.Fight, self.OnPcClickCb)
    XScheduleManager.UnSchedule(self.Timer)
    self.Timer = nil
    CS.XRLManager.Camera.InputScaleEnable = true
end

local Scroll
local Delay = 0
function XUiFightCommonInterBtnList:Update()
    self:UpdateFollowNpc()
    
    if not XDataCenter.UiPcManager.IsPc() or Delay > 0 then
        Delay = Delay - 1
        return
    end
    
    Scroll = Input.GetAxis("Mouse ScrollWheel")
    if Scroll > 0 then
        self:ReduceBtnOptionPcIndex()
    elseif Scroll < 0 then
        self:AddBtnOptionPcIndex()
    else
        return
    end

    Delay = 10
end

function XUiFightCommonInterBtnList:UpdateFollowNpc()
    if not self.FollowNpc then
        return
    end

    if not self.FollowNpc.IsActivate then
        self.Options.gameObject:SetActiveEx(false)
    else
        local pos = self.FollowNode.position
        if self.CSXRLManagerCamera:CheckInView(pos) and not XTool.IsTableEmpty(self.GridDataList) then
            local viewPoint = self.CSWorldToViewPoint(pos)
            self.Options.transform.anchoredPosition = Vector2(viewPoint.x, viewPoint.y) + self.Offset
            self.Options.gameObject:SetActiveEx(true)
        else
            self.Options.gameObject:SetActiveEx(false)
        end
    end
end

function XUiFightCommonInterBtnList:OnGetEvents()
    return {
        XEventId.EVENT_CUSTOM_UI_SCHEME_CHANGED,
    }
end

function XUiFightCommonInterBtnList:OnNotify(evt, ...)
    if evt == XEventId.EVENT_CUSTOM_UI_SCHEME_CHANGED then
        CS.XRLManager.Camera.InputScaleEnable = not XDataCenter.UiPcManager.IsPc()
        self:Refresh()
    end
end

function XUiFightCommonInterBtnList:OnPcClick(inputDeviceType, key, clickType, operationType)
    if not XDataCenter.UiPcManager.IsPc() then
        return
    end
    
    local fight = CS.XFight.Instance
    if not fight then
        return
    end
    
    if CSXNpcOperationClickKey.__CastFrom(key) == CSXNpcOperationClickKey.InteractKey then
        if not self.GridDataList[self.CurBtnOptionPcIndex] then
            return
        end
        
        local uiCommonInterBtn = self.CommonInterBtnPool[self.CurBtnOptionPcIndex]
        if not uiCommonInterBtn then
            return
        end
        fight.InputControl:OnClick(uiCommonInterBtn:GetKey(), clickType)
    end
end

function XUiFightCommonInterBtnList:AddBtnOptionPcIndex()
    if not XDataCenter.UiPcManager.IsPc() then
        return
    end
    self.CurBtnOptionPcIndex = self.CurBtnOptionPcIndex + 1 < #self.GridDataList and self.CurBtnOptionPcIndex + 1 or #self.GridDataList
    self:UpdateOptions()
end

function XUiFightCommonInterBtnList:ReduceBtnOptionPcIndex()
    if not XDataCenter.UiPcManager.IsPc() then
        return
    end
    self.CurBtnOptionPcIndex = self.CurBtnOptionPcIndex - 1 > 1 and self.CurBtnOptionPcIndex - 1 or 1
    self:UpdateOptions()
end

function XUiFightCommonInterBtnList:UpdateOptions()
    if XTool.IsTableEmpty(self.GridDataList) then
        return
    end
    self:UpdateCurBtnOptionPcIndex(self.GridDataList)
    self:UpdateOptionsSelect()
end

function XUiFightCommonInterBtnList:UpdateOptionsSelect()
    if not XDataCenter.UiPcManager.IsPc() then
        self:CancelOptionSelect()
        return
    end
    self.Options:SelectIndex(self.CurBtnOptionPcIndex)
end

function XUiFightCommonInterBtnList:OnOptionsSelect(index)
    if not XDataCenter.UiPcManager.IsPc() then
        return
    end
    
    local selectGrid = self.SelectIndex and self.CommonInterBtnPool[self.SelectIndex]
    if selectGrid then
        selectGrid:SetIsSelect(false)
    end
    self.CommonInterBtnPool[index]:SetIsSelect(true)
    self.SelectIndex = index
end

function XUiFightCommonInterBtnList:CancelOptionSelect()
    self.Options:CancelSelect()
end

function XUiFightCommonInterBtnList:Refresh()
    if XTool.UObjIsNil(self.GameObject) then
        return
    end
    self:CancelOptionSelect()
    
    local onCreate = function(item, data)
        item:Refresh(data)
    end

    self.GridDataList = {}
    for _, data in pairs(self.GridDatas) do
        if not data then
            goto CONTINUE
        end
        table.insert(self.GridDataList, data)
        :: CONTINUE ::
    end
    table.sort(self.GridDataList, function(a, b)
        if a.Order ~= b.Order then
            return a.Order < b.Order
        end
    end)
    XUiHelper.CreateTemplates(self, self.CommonInterBtnPool, self.GridDataList, XUiCommonInterBtn.New, self.BtnOption.gameObject, self.Line.transform, onCreate)
    
    --PC端按钮
    local dataCount = #self.GridDataList
    if XDataCenter.UiPcManager.IsPc() and dataCount > 0 then
        self.BtnOptionPC.gameObject:SetActiveEx(true)
        self.IconRoller.gameObject:SetActiveEx(dataCount > 1)
    else
        self.BtnOptionPC.gameObject:SetActiveEx(false)
        self.IconRoller.gameObject:SetActiveEx(false)
    end

    --按钮组
    local xUiButtons = {}
    for i in ipairs(self.GridDataList) do
        table.insert(xUiButtons, self.CommonInterBtnPool[i]:GetXUiButton())
    end
    self.Options:Init(xUiButtons, handler(self, self.OnOptionsSelect), self.CurBtnOptionPcIndex)
    self:UpdateOptions()
    
    self.Options.gameObject:SetActiveEx(not XTool.IsTableEmpty(self.GridDataList))
end

function XUiFightCommonInterBtnList:UpdateCurBtnOptionPcIndex(gridDataList)
    local commonInterBtn
    local curBtnOptionPcIndex
    for i in ipairs(gridDataList) do
        if i == self.CurBtnOptionPcIndex then
            curBtnOptionPcIndex = self.CurBtnOptionPcIndex
            break
        end
    end

    if not curBtnOptionPcIndex then
        curBtnOptionPcIndex = #gridDataList
        self.CurBtnOptionPcIndex = curBtnOptionPcIndex
    end
    commonInterBtn = self.CommonInterBtnPool[curBtnOptionPcIndex]

    if not commonInterBtn then
        return
    end
    self.BtnOptionPC.transform:SetParent(commonInterBtn:GetTransform())
    self.BtnOptionPC.transform.anchoredPosition = Vector2(self.BtnOptionPC.transform.anchoredPosition.x, -5)
end

function XUiFightCommonInterBtnList:SetCommonInterBtn(...)
    local data = {...}
    local id = data[1]
    self.GridDatas[id] = {Id = id, Key = data[2], Icon = data[3], Text = data[4], Order = data[5], IsDisable = data[6]}
    self:Refresh()
end

function XUiFightCommonInterBtnList:SetFollowNpc(...)
    local data = {...}
    local targetNpc, jointName, offsetX, offsetY = data[1], data[2], data[3], data[4]
    if string.IsNilOrEmpty(jointName) then
        jointName = CS.XStealthManager.XTargetIndicator.NameMarkCase
    end

    self.FollowNpc = targetNpc
    self.FollowNode = self.FollowNpc.RLNpc:GetJoint(jointName)
    self.Offset = Vector2(offsetX, offsetY)
    self.Options.transform.anchorMin = Vector2.zero
    self.Options.transform.anchorMax = Vector2.zero
    self:Refresh()
end

function XUiFightCommonInterBtnList:RemoveCommonInterBtn(id)
    if XTool.UObjIsNil(self.GameObject) then
        return
    end

    if id then
        self.GridDatas[id] = nil
    else
        self.GridDatas = {}
    end

    if XTool.IsTableEmpty(self.GridDatas) then
        self.FollowNpc = nil
        self.FollowNode = nil
        self.Options.transform.anchorMin = self.OriginOptionsAnchorMin
        self.Options.transform.anchorMax = self.OriginOptionsAnchorMax
        self.Options.transform.anchoredPosition = self.OriginOptionsPos
        self.Options.gameObject:SetActiveEx(true)
        self:Close()
        return
    end
    self:Refresh()
end

function XUiFightCommonInterBtnList:Close()
    self.SelectIndex = nil
    self.Super.Close(self)
end 