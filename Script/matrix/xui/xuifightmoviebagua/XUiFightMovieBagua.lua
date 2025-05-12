local CsTime = CS.UnityEngine.Time

local LOCK_COUNT = 3    --密码锁数量，1是最内层的锁
local ANGLE = 45        --每个锁之间的角度
local OriginCenterX = CS.XResolutionManager.OriginWidth / 2
local OriginCenterY = CS.XResolutionManager.OriginHeight / 2
local OriginCenter = Vector2(OriginCenterX, OriginCenterY)
local AUTO_ROTATE_SPEED = 100

--旋转方向
local RotateDirection = {
    Clockwise = -1,     --顺时针
    AntiClockwise = 1   --逆时针
}


local XUiPanelDisc = XClass(nil, "XUiPanelDisc")

function XUiPanelDisc:Ctor(circleGoInputHandler, circle, parent, index)
    self.Index = index
    self.Circle = circle
    self.Parent = parent
    circleGoInputHandler:AddBeginDragListener(function(eventData) self:OnBeginDrag(eventData) end)
    circleGoInputHandler:AddDragListener(function(eventData) self:OnDrag(eventData) end)
    circleGoInputHandler:AddEndDragListener(function(eventData) self:OnEndDrag(eventData) end)
end

function XUiPanelDisc:Init()
    self.Circle.transform.eulerAngles = Vector3.zero
    self:SetCurSlot(0)
    self:ResetAutoData()
end

function XUiPanelDisc:ResetAutoData()
    self.CurAutoRotateAngleZ = 0
    self.DifferAngleZ = 0
    self.IsAutoRotate = false
    self.CurPlaySoundAngle = 0
end

function XUiPanelDisc:OnBeginDrag(eventData)
    if self.Parent:GetIsPass() then
        return
    end
    self.StartPosition = eventData.position
    self.StartDir = self.StartPosition - OriginCenter   --某一点到中心的向量
    self.StartAngleZ = self.Circle.transform.eulerAngles.z
    self.LastEulerAngleZ = self.StartAngleZ
    self:SetCurSlot(0)
    self:ResetAutoData()
end

function XUiPanelDisc:OnDrag(eventData)
    if self.Parent:GetIsPass() then
        return
    end
    
    local eventPos = eventData.position - OriginCenter
    local angle = Vector2.SignedAngle(self.StartDir, eventPos)
    self.Circle.transform.eulerAngles = Vector3(0, 0, self.StartAngleZ + angle)
    
    --每有一个格位的转动播放音效
    local curPlaySoundAngle = math.abs(self.CurPlaySoundAngle + angle)
    if curPlaySoundAngle >= ANGLE then
        self:PlaySound()
        self.CurPlaySoundAngle = -angle
    end

    --缓存当前旋转方向
    self.AutoRotateDirection = angle < self.LastEulerAngleZ and RotateDirection.Clockwise or RotateDirection.AntiClockwise
    self.LastEulerAngleZ = angle
end

function XUiPanelDisc:OnEndDrag(eventData)
    if self.Parent:GetIsPass() then
        return
    end
    local curAngle = self.Circle.transform.eulerAngles
    local curAngleZ = curAngle.z
    self.CurAngleZ = curAngleZ
    self.DifferAngleZ = curAngleZ % ANGLE
    
    if self.AutoRotateDirection == RotateDirection.AntiClockwise then
        self.DifferAngleZ = ANGLE - self.DifferAngleZ
    end
    self.IsAutoRotate = true
end

function XUiPanelDisc:RefreshCurSlot()
    local curAngleZ = math.floor(self.Circle.transform.eulerAngles.z)
    curAngleZ = curAngleZ < 360 and curAngleZ or curAngleZ % 360
    self:SetCurSlot(math.floor(curAngleZ / ANGLE) + 1)
end

function XUiPanelDisc:SetCurSlot(slot)
    self.CurSlot = slot
end

function XUiPanelDisc:IsUnlock()
    return self.CurSlot == self.Parent:GetUnlockSlot(self.Index)
end

function XUiPanelDisc:Update()
    if not self.IsAutoRotate then
        return
    end
    
    self.CurAutoRotateAngleZ = math.min(self.CurAutoRotateAngleZ + CsTime.deltaTime * AUTO_ROTATE_SPEED, self.DifferAngleZ)
    local curAngle = self.Circle.transform.eulerAngles
    self.Circle.transform.eulerAngles = Vector3(curAngle.x, curAngle.y, self.CurAngleZ + self.CurAutoRotateAngleZ * self.AutoRotateDirection)

    if self.CurAutoRotateAngleZ == self.DifferAngleZ then
        self:ResetAutoData()
        self:PlaySound()
        self:RefreshCurSlot()
        self.Parent:CheckGame()
    end
end

function XUiPanelDisc:PlaySound()
    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.FightMovieBagua)
end


--八卦转盘密码锁界面
local XUiFightMovieBagua = XLuaUiManager.Register(XLuaUi, "UiFightMovieBagua")

function XUiFightMovieBagua:OnAwake()
    self:RegisterClickEvent(self.BtnTanchuangCloseBig, self.OnClose)
    self.PanelDiscList = {}
    for i = 1, LOCK_COUNT do
        self.PanelDiscList[i] = XUiPanelDisc.New(self["CircleGoInputHandler" .. i], self["Circle" .. i], self, i)
    end
end

function XUiFightMovieBagua:OnEnable()
    self.AnimationEnable.gameObject:SetActiveEx(true)
    self:PlayAnimation("AnimationEnable", function()
        self.AnimationEnable.gameObject:SetActiveEx(false)
    end)
    self.Timer = XScheduleManager.ScheduleForeverEx(handler(self, self.Update), 0, 0)
    for _, panelRight in ipairs(self.PanelDiscList) do
        panelRight:Init()
    end
    self.PanelRight.gameObject:SetActiveEx(false)
    self.IsPass = false
end

function XUiFightMovieBagua:OnDisable()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

--CSCallLua
function XUiFightMovieBagua:Init(id)
    self.UnlockSlots = {}
    for index = 1, LOCK_COUNT do
        self.UnlockSlots[index] = XFightPasswordConfigs.GetCorrectPassword(id, index)
    end
end

function XUiFightMovieBagua:GetUnlockSlot(index)
    return self.UnlockSlots[index]
end

function XUiFightMovieBagua:Update()
    for _, panelDisc in ipairs(self.PanelDiscList) do
        panelDisc:Update()
    end
end

function XUiFightMovieBagua:CheckGame()
    for _, panelDisc in ipairs(self.PanelDiscList) do
        if not panelDisc:IsUnlock() then
            return
        end
    end
    
    self.IsPass = true
    self.PanelRight.gameObject:SetActiveEx(true)
    local fight = CS.XFight.Instance
    if fight then
        fight.InputControl:OnClick(CS.XNpcOperationClickKey.CommonMiniGameWin, CS.XOperationClickType.KeyDown)
        fight.InputControl:OnClick(CS.XNpcOperationClickKey.CommonMiniGameWin, CS.XOperationClickType.KeyUp)
    end
end

function XUiFightMovieBagua:GetIsPass()
    return self.IsPass
end

function XUiFightMovieBagua:OnClose()
    local fight = CS.XFight.Instance
    if fight then
        fight.InputControl:OnClick(CS.XNpcOperationClickKey.CommonUiClose, CS.XOperationClickType.KeyDown)
        fight.InputControl:OnClick(CS.XNpcOperationClickKey.CommonUiClose, CS.XOperationClickType.KeyUp)
    end
    self:Close()
end